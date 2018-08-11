import Foundation
import CocoaLumberjackSwift

public protocol DNSResolverProtocol: class {
    weak var delegate: DNSResolverDelegate? { get set }
    func resolve(session: DNSSession)
    func start()
    func stop()
}

public protocol DNSResolverDelegate: class {
    func didReceive(rawResponse: Data)
}

public class UDPDNSResolver: NSObject, DNSResolverProtocol, RawUDPSocketDelegate {    
    private var socket: RawUDPSocketProtocol! = nil
    private let host: String
    private let portNumber: Int
    public weak var delegate: DNSResolverDelegate?

    public init(address: IPAddress, port: Port) {
        host = address.presentation
        portNumber = Int(port.value)
        super.init()
    }

    public func resolve(session: DNSSession) {
        guard let socket = socket else { return DDLogError("resolve: DNSResolver is not started yet.") }
        let data: Data = session.requestMessage.payload
        DDLogVerbose("\(self) write \(data)")
        socket.write(data: data)
    }

    public func start() {
        guard socket == nil else { return DDLogError("start: DNSResolver is started already.") }
        socket = RawSocketFactory.getRawUDPSocket()
        socket.timeout = 0
        _ = socket.bindEndpoint(host, UInt16(portNumber))
        socket.delegate = self
        DDLogInfo("\(self) started");
    }
    public func stop() {
        guard let socket = socket else { return DDLogError("stop: DNSResolver is not started yet.") }
        socket.disconnect()
        socket.delegate = nil
        self.socket = nil
        DDLogInfo("\(self) stopped");
    }

    public func didReceive(data: Data, from: RawUDPSocketProtocol) {
        DDLogVerbose("\(self) didReceive \(data)")
        delegate?.didReceive(rawResponse: data)
    }
    
    public func didCancel(socket: RawUDPSocketProtocol) {
        DDLogInfo("\(self) RawUDPSocketProtocol \(socket) closed")
    }
}
