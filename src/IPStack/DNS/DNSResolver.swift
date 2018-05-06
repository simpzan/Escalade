import Foundation
import CocoaLumberjackSwift

public protocol DNSResolverProtocol: class {
    weak var delegate: DNSResolverDelegate? { get set }
    func resolve(session: DNSSession)
    func stop()
}

public protocol DNSResolverDelegate: class {
    func didReceive(rawResponse: Data)
}

public class UDPDNSResolver: NSObject, DNSResolverProtocol, NWUDPSocketDelegate {
    let socket: NWUDPSocket
    public weak var delegate: DNSResolverDelegate?

    public init(address: IPAddress, port: Port) {
        socket = NWUDPSocket(host: address.presentation, port: Int(port.value), timeout: 0)!
        super.init()
        socket.delegate = self
    }

    public func resolve(session: DNSSession) {
        let data: Data = session.requestMessage.payload
        DDLogVerbose("\(self) write \(data)")
        socket.write(data: data)
    }

    public func stop() {
        DDLogInfo("\(self) stopping resolver")
        socket.disconnect()
    }

    public func didReceive(data: Data, from: NWUDPSocket) {
        DDLogVerbose("\(self) didReceive \(data)")
        delegate?.didReceive(rawResponse: data)
    }
    
    public func didCancel(socket: NWUDPSocket) {
        DDLogInfo("\(self) NWUDPSocket \(socket) closed")
    }
}
