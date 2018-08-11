import Foundation
import NetworkExtension
import CocoaLumberjackSwift

/// The delegate protocol of `NWUDPSocket`.
public protocol NWUDPSocketDelegate: class {
    /**
     Socket did receive data from remote.
     
     - parameter data: The data.
     - parameter from: The socket the data is read from.
     */
    func didReceive(data: Data, from: NWUDPSocket)
    
    func didCancel(socket: NWUDPSocket)
}

/// The wrapper for NWUDPSession.
///
/// - note: This class is thread-safe.
public class NWUDPSocket: NSObject, RawUDPSocketProtocol {
    private var session: NWUDPSession!
    private var pendingWriteData: [Data] = []
    private var writing = false
    private let queue: DispatchQueue = QueueFactory.getQueue()
    public var timeout: Int = Opt.UDPSocketActiveTimeout
    private var remoteEndpoint: NWHostEndpoint! = nil
    
    /// The delegate instance.
    public weak var delegate: RawUDPSocketDelegate?
    
    public func bindEndpoint(_ host: String, _ port: UInt16) -> Bool {
        let provider = RawSocketFactory.TunnelProvider
        let to = NWHostEndpoint(hostname: host, port: "\(port)")
        remoteEndpoint = to
        guard let session = provider?.createUDPSession(to: to, from: nil) else { return false }
        setupSession(session)

        if (timeout > 0) { createTimer() }
        return true
    }
    
    private func setupSession(_ newSession: NWUDPSession) {
        if session != nil {
            session.removeObserver(self, forKeyPath: #keyPath(NWUDPSession.state))
            session.removeObserver(self, forKeyPath: #keyPath(NWUDPSession.hasBetterPath))
            session.cancel()
            DDLogInfo("\(self) updating session, \(session) -> \(newSession).")
        }
        session = newSession;
        newSession.addObserver(self, forKeyPath: #keyPath(NWUDPSession.state), options: [.new], context: nil)
        newSession.addObserver(self, forKeyPath: #keyPath(NWUDPSession.hasBetterPath), options: [.new], context: nil)
        newSession.setReadHandler({ [ weak self ] dataArray, error in
            self?.queueCall {
                guard let sSelf = self else { return }
                
                sSelf.updateActivityTimer()
                
                guard error == nil, let dataArray = dataArray else {
                    DDLogError("\(sSelf) \(sSelf.session.state), Error when reading from remote server. \(error!) ")
                    return
                }
                
                let bytes = dataArray.reduce(0) { (acc: Int, data: Data) -> Int in
                    return data.count + acc
                }
                DDLogDebug("\(sSelf) read \(bytes) bytes.")
                for data in dataArray {
                    sSelf.delegate?.didReceive(data: data, from: sSelf)
                }
            }
        }, maxDatagrams: 32)
    }
    
    /**
     Send data to remote.
     
     - parameter data: The data to send.
     */
    public func write(data: Data) {
        guard session.state != .cancelled else {
            return DDLogError("\(self) the session has been cancelled")
        }
        pendingWriteData.append(data)
        checkWrite()
    }
    
    public func disconnect() {
        queueCall { [ weak self ] in
            guard let this = self else { return }
            DDLogInfo("\(this) disconnecting...")
            this.session.cancel()
            this.destroyTimer()
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        queueCall { [ weak self ] in
            guard let this = self, let key = keyPath else { return }
            let value = this.session.value(forKeyPath: key)
            DDLogInfo("\(this) session.\(key) changed to \(String(describing: value)).")
            switch key {
            case #keyPath(NWUDPSession.hasBetterPath): this.handlePathChange()
            case #keyPath(NWUDPSession.state): this.handleStateChange()
            default: break
            }
        }
    }
    private func handleStateChange() {
        switch session.state {
        case .cancelled:
            delegate?.didCancel(socket: self)
        case .ready:
            checkWrite()
        default:
            break
        }
    }
    private func handlePathChange() {
        if session.hasBetterPath {
            let s = NWUDPSession(upgradeFor: session)
            setupSession(s)
        }
    }
    
    private func checkWrite() {
        updateActivityTimer()
        
        guard session.state == .ready else { return }
        
        guard !writing else { return }
        
        guard pendingWriteData.count > 0 else { return }
        
        writing = true
        session.writeMultipleDatagrams(self.pendingWriteData) { [ weak self ] error in
            if error != nil { DDLogError("\(String(describing: self)) writeMultipleDatagrams failed, \(error!).") }
            self?.queueCall {
                self?.writing = false
                self?.checkWrite()
            }
        }
        let bytes = pendingWriteData.reduce(0) { (acc: Int, data: Data) -> Int in
            return data.count + acc
        }
        DDLogDebug("\(self) wrote \(bytes) bytes.")
        self.pendingWriteData.removeAll(keepingCapacity: true)
    }

    // MARK: - timer
    private var timer: DispatchSourceTimer! = nil

    private func createTimer() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        let interval = DispatchTimeInterval.seconds(Opt.UDPSocketActiveCheckInterval)
        timer.schedule(deadline: DispatchTime.now(), repeating:interval , leeway: interval)
        timer.setEventHandler { [weak self] in
            self?.queueCall {
                self?.checkStatus()
            }
        }
        timer.resume()
    }
    private func destroyTimer() {
        timer?.cancel()
        timer = nil
    }

    /// The time when the last activity happens.
    ///
    /// Since UDP do not have a "close" semantic, this can be an indicator of timeout.
    private var lastActive: Date = Date()

    private func updateActivityTimer() {
        lastActive = Date()
    }
    
    private func checkStatus() {
        if timeout > 0 && Date().timeIntervalSince(lastActive) > TimeInterval(timeout) {
            DDLogError("\(self) timeout, disconnect now.")
            disconnect()
        }
    }

    // MARK: -

    private func queueCall(block: @escaping () -> Void) {
        queue.async {
            block()
        }
    }
    
    deinit {
        session.removeObserver(self, forKeyPath: #keyPath(NWUDPSession.state))
        session.removeObserver(self, forKeyPath: #keyPath(NWUDPSession.hasBetterPath))
        DDLogInfo("\(self) deinited.")
    }
    
    open override var description: String {
        let address = Utils.address(of: self)
        let typeName = String(describing: type(of: self))
        return String(format: "<%@ %p %@>", typeName, address, remoteEndpoint)
    }
}

extension NWUDPSessionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancelled:
            return "canceled"
        case .failed:
            return "failed"
        case .invalid:
            return "invalid"
        case .preparing:
            return "preparing"
        case .ready:
            return "ready"
        case .waiting:
            return "waiting"
        }
    }
}
