import Foundation
import Resolver
import CocoaLumberjackSwift

protocol TunnelDelegate : class {
    func tunnelDidClose(_ tunnel: Tunnel)
    
    func shouldDelay(_ tunnel: Tunnel) -> TimeInterval
}

/// The tunnel forwards data between local and remote.
public class Tunnel: NSObject, SocketDelegate {
    
    /// The status of `Tunnel`.
    public enum TunnelStatus: CustomStringConvertible {
        
        case invalid, readingRequest, waitingToBeReady, forwarding, closing, closed
        
        public var description: String {
            switch self {
            case .invalid:
                return "invalid"
            case .readingRequest:
                return "reading request"
            case .waitingToBeReady:
                return "waiting to be ready"
            case .forwarding:
                return "forwarding"
            case .closing:
                return "closing"
            case .closed:
                return "closed"
            }
        }
    }
    
    /// The proxy socket.
    var proxySocket: ProxySocket
    public var clientPort: UInt16? {
        return proxySocket.socket.sourcePort?.value;
    }
    public var clientPid: Int?
    public var clientProgram: String?
    public var userAgent: String?
    public var closedBy: ClosedSourceEnum {
        get { return _closedBy ?? .none }
        set { _closedBy = _closedBy ?? newValue }
    }
    public enum ClosedSourceEnum {
        case proxy, adapter, tunnel, none
    }
    private var _closedBy: ClosedSourceEnum? = nil

    /// The adapter socket connecting to remote.
    var adapterSocket: AdapterSocket?
    
    /// The delegate instance.
    weak var delegate: TunnelDelegate?
    
    var observer: Observer<TunnelEvent>?
    
    /// Indicating how many socket is ready to forward data.
    private var readySignal = 0
    
    /// If the tunnel is closed, i.e., proxy socket and adapter socket are both disconnected.
    var isClosed: Bool {
        return proxySocket.isDisconnected && (adapterSocket?.isDisconnected ?? true)
    }
    
    fileprivate var _cancelled: Bool = false
    fileprivate var _stopForwarding = false
    public var isCancelled: Bool {
        return _cancelled
    }
    
    fileprivate var _status: TunnelStatus = .invalid
    public var status: TunnelStatus {
        return _status
    }
    
    public var statusDescription: String {
        return status.description
    }
    
    override public var description: String {
        if let adapterSocket = adapterSocket {
            return "<Tunnel \(proxySocket) \(adapterSocket) rx \(rx) tx \(tx)>"
        } else {
            return "<Tunnel \(proxySocket)>"
        }
    }
    
    public let createdTime: Date
    public var closedTime: Date?
    
    init(proxySocket: ProxySocket) {
        self.proxySocket = proxySocket
        createdTime = Date()
        super.init()
        self.proxySocket.delegate = self
        
        self.observer = ObserverFactory.currentFactory?.getObserverForTunnel(self)
    }
    
    /**
     Start running the tunnel.
     */
    func openTunnel() {
        guard !self.isCancelled else {
            return
        }
        
        self.proxySocket.openSocket()
        self._status = .readingRequest
        self.observer?.signal(.opened(self))
    }
    
    /**
     Close the tunnel elegantly.
     */
    func close() {
        observer?.signal(.closeCalled(self))
        
        guard !self.isCancelled else {
            return
        }
        
        self._cancelled = true
        self._status = .closing
        
        if !self.proxySocket.isDisconnected {
            self.proxySocket.disconnect()
        }
        if let adapterSocket = self.adapterSocket {
            if !adapterSocket.isDisconnected {
                adapterSocket.disconnect()
            }
        }
    }
    
    /// Close the tunnel immediately.
    ///
    /// - note: This method is thread-safe.
    func forceClose() {
        observer?.signal(.forceCloseCalled(self))
        
        guard !self.isCancelled else {
            return
        }
        self.closedBy = .tunnel
        self._cancelled = true
        self._status = .closing
        self._stopForwarding = true
        
        if !self.proxySocket.isDisconnected {
            self.proxySocket.forceDisconnect()
        }
        if let adapterSocket = self.adapterSocket {
            if !adapterSocket.isDisconnected {
                adapterSocket.forceDisconnect()
            }
        }
    }
    
    public func didReceive(session: ConnectSession, from: ProxySocket) {
        guard !isCancelled else {
            return
        }
        
        _status = .waitingToBeReady
        observer?.signal(.receivedRequest(session, from: from, on: self))
        
        if !session.isIP() {
            _ = Resolver.resolve(hostname: session.host, timeout: Opt.DNSTimeout) { [weak self] resolver, err in
                QueueFactory.getQueue().async {
                    if err != nil {
                        session.ipAddress = ""
                    } else {
                        session.ipAddress = (resolver?.ipv4Result.first)!
                    }
                    self?.openAdapter(for: session)
                }
            }
        } else {
            session.ipAddress = session.host
            openAdapter(for: session)
        }
    }
    
    fileprivate func openAdapter(for session: ConnectSession) {
        guard !isCancelled else {
            return
        }
        
        if let socket = proxySocket as? HTTPProxySocket {
            userAgent = socket.userAgent
        }
        let manager = RuleManager.currentManager
        let factory = manager.match(session)!
        adapterSocket = factory.getAdapterFor(session: session)
        adapterSocket!.delegate = self
        adapterSocket!.openSocketWith(session: session)
    }
    
    public func didBecomeReadyToForwardWith(socket: SocketProtocol) {
        guard !isCancelled else {
            return
        }
        
        readySignal += 1
        observer?.signal(.receivedReadySignal(socket, currentReady: readySignal, on: self))
        
        defer {
            if let socket = socket as? AdapterSocket {
                proxySocket.respondTo(adapter: socket)
            }
        }
        if readySignal == 2 {
            waitAndRun { [weak self] in
                self?._status = .forwarding
                self?.proxySocket.readData()
                self?.adapterSocket?.readData()
            }
        }
    }
    
    func waitAndRun(fn: @escaping () -> Void) {
        let delay = delegate?.shouldDelay(self) ?? 0
        if delay == 0 { return fn() }
        
        DDLogInfo("\(self), wait \(delay)s.")
        QueueFactory.delay(Double(delay), closure: fn)
    }
    
    public func didDisconnectWith(socket: SocketProtocol) {
        if !isCancelled {
            _stopForwarding = true
            self.closedBy = socket === proxySocket ? .proxy : .adapter
            close()
        }
        checkStatus()
    }
    
    public var tx = 0
    public var rx = 0

    public func didRead(data: Data, from socket: SocketProtocol) {
        if let socket = socket as? ProxySocket {
            observer?.signal(.proxySocketReadData(data, from: socket, on: self))
            
            guard !isCancelled else {
                return
            }
            adapterSocket!.write(data: data)
            tx += data.count
        } else if let socket = socket as? AdapterSocket {
            observer?.signal(.adapterSocketReadData(data, from: socket, on: self))
            
            guard !isCancelled else {
                return
            }
            proxySocket.write(data: data)
            rx += data.count
        }
    }
    
    public func didWrite(data: Data?, by socket: SocketProtocol) {
        if let socket = socket as? ProxySocket {
            observer?.signal(.proxySocketWroteData(data, by: socket, on: self))
            
            guard !isCancelled else {
                return
            }
            QueueFactory.getQueue().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Opt.forwardReadInterval)) { [weak self] in
                self?.waitAndRun { [weak self] in
                    self?.adapterSocket?.readData()
                }
            }
        } else if let socket = socket as? AdapterSocket {
            observer?.signal(.adapterSocketWroteData(data, by: socket, on: self))
            
            guard !isCancelled else {
                return
            }
            
            waitAndRun { [weak self] in
                self?.proxySocket.readData()
            }
        }
    }
    
    public func didConnectWith(adapterSocket: AdapterSocket) {
        guard !isCancelled else {
            return
        }
        
        observer?.signal(.connectedToRemote(adapterSocket, on: self))
    }
    
    public func updateAdapterWith(newAdapter: AdapterSocket) {
        guard !isCancelled else {
            return
        }
        
        observer?.signal(.updatingAdapterSocket(from: adapterSocket!, to: newAdapter, on: self))
        
        adapterSocket = newAdapter
        adapterSocket?.delegate = self
    }
    
    fileprivate func checkStatus() {
        if isClosed {
            _status = .closed
            closedTime = Date()
            observer?.signal(.closed(self))
            delegate?.tunnelDidClose(self)
            delegate = nil
        }
    }
}
