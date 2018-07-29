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

public class UDPDNSResolver: NSObject, DNSResolverProtocol, NWUDPSocketDelegate {
    private var socket: NWUDPSocket! = nil
    private let host: String
    private let portNumber: Int
    public weak var delegate: DNSResolverDelegate?

    public init(address: IPAddress, port: Port) {
        host = address.presentation
        portNumber = Int(port.value)
        super.init()
    }

    public func resolve(session: DNSSession) {
        guard let socket = socket else { return DDLogError("DNSResolver is not started yet.") }
        let data: Data = session.requestMessage.payload
        DDLogVerbose("\(self) write \(data)")
        socket.write(data: data)
    }

    public func start() {
        socket = NWUDPSocket(host: host, port: portNumber, timeout: 0)!
        socket.delegate = self
        DDLogInfo("\(self) started");
    }
    public func stop() {
        socket.disconnect()
        socket.delegate = nil
        socket = nil
        DDLogInfo("\(self) stopped");
    }

    public func didReceive(data: Data, from: NWUDPSocket) {
        DDLogVerbose("\(self) didReceive \(data)")
        delegate?.didReceive(rawResponse: data)
    }
    
    public func didCancel(socket: NWUDPSocket) {
        DDLogInfo("\(self) NWUDPSocket \(socket) closed")
    }
}
