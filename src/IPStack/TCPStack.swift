import Foundation
import tun2socks
import CocoaLumberjackSwift

/// This class wraps around tun2socks to build a TCP only IP stack.
open class TCPStack: TSIPStackDelegate, IPStackProtocol {
    /// The `TCPStack` singleton instance.
    open static var stack = TCPStack()

    private let ipStack = TSIPStack.stack

    // MARK: - input/output

    /**
     Input a packet into the stack.

     - note: Only process IPv4 TCP packet as of now, since stable lwip does not support ipv6 yet.

     - parameter packet:  The IP packet.
     - parameter version: The version of the IP packet, i.e., AF_INET, AF_INET6.

     - returns: If the stack takes in this packet. If the packet is taken in, then it won't be processed by other IP stacks.
     */
    open func input(packet: Data, version: NSNumber?) -> Bool {
        if let version = version {
            // we do not process IPv6 packets now
            if version.int32Value == AF_INET6 {
                return false
            }
        }
        if IPPacket.peekProtocol(packet) == .tcp {
            ipStack.received(packet: packet)
            return true
        }
        return false
    }

    /// This is set automatically when the stack is registered to some interface.
    open var outputFunc: (([Data], [NSNumber]) -> Void)! {
        get { return ipStack.outputBlock }
        set { ipStack.outputBlock = newValue }
    }

    // MARK: - start/stop

    public func start() {
        ipStack.delegate = self
        ipStack.processQueue = QueueFactory.getQueue()
        ipStack.resumeTimer()
    }

    /**
     Stop the TCP stack.

     After calling this, this stack should never be referenced. Use `TCPStack.stack` to get a new reference of the singleton.
     */
    open func stop() {
        ipStack.delegate = nil
        ipStack.suspendTimer()
        proxyServer = nil
    }

    // MARK: - TSIPStackDelegate Implementation
    open func didAcceptTCPSocket(_ sock: TSTCPSocket) {
        DDLogDebug("Accepted a new socket from IP stack.")
        let tunSocket = TUNTCPSocket(socket: sock)
        let proxySocket = DirectProxySocket(socket: tunSocket)
        proxyServer?.didAcceptNewSocket(proxySocket)
    }

    /// The proxy server that handles connections accepted from this stack.
    ///
    /// - warning: This must be set before `TCPStack` is registered to `TUNInterface`.
    open weak var proxyServer: ProxyServer?
}
