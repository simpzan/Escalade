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
public class NWUDPSocket: NSObject {
    private let session: NWUDPSession
    private var pendingWriteData: [Data] = []
    private var writing = false
    private let queue: DispatchQueue = QueueFactory.getQueue()
    private let timeout: Int
    
    /// The delegate instance.
    public weak var delegate: NWUDPSocketDelegate?

    /**
     Create a new UDP socket connecting to remote.
     
     - parameter host: The host.
     - parameter port: The port.
     */
    public init?(host: String, port: Int, timeout: Int = Opt.UDPSocketActiveTimeout) {
        let provider = RawSocketFactory.TunnelProvider
        let to = NWHostEndpoint(hostname: host, port: "\(port)")
        guard let session = provider?.createUDPSession(to: to, from: nil) else { return nil }
        
        self.session = session
        self.timeout = timeout

        super.init()

        if (timeout > 0) { createTimer() }

        session.addObserver(self, forKeyPath: #keyPath(NWUDPSession.state), options: [.new], context: nil)
        
        session.setReadHandler({ [ weak self ] dataArray, error in
            self?.queueCall {
                guard let sSelf = self else { return }
                
                sSelf.updateActivityTimer()
                
                guard error == nil, let dataArray = dataArray else {
                    DDLogError("\(sSelf) \(session.state), Error when reading from remote server. \(error!) ")
//                    sSelf.disconnect()
                    return
                }
                
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
        DDLogDebug("\(self) disconnecting...")
        session.cancel()
        destroyTimer()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "state" else { return }
        
        switch session.state {
        case .cancelled:
            queueCall { [ weak self ] in
                if let sSelf = self {
                    sSelf.delegate?.didCancel(socket: sSelf)
                }
            }
        case .ready:
            checkWrite()
        default:
            break
        }
    }
    
    private func checkWrite() {
        updateActivityTimer()
        
        guard session.state == .ready else { return }
        
        guard !writing else { return }
        
        guard pendingWriteData.count > 0 else { return }
        
        writing = true
        session.writeMultipleDatagrams(self.pendingWriteData) { [ weak self ] _ in
            self?.queueCall {
                self?.writing = false
                self?.checkWrite()
            }
        }
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
