//
//  TrafficMonitor.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/10/17.
//
//

import Foundation
import NEKit
import CocoaLumberjackSwift

func isListPortEnabled() -> Bool {
    var pid: Int32 = 0
    let program = ListPortRPC(9990, &pid)
    DDLogInfo("pid \(pid) \(program*)")
    return program != nil && pid == getpid()
}
public func updateCanGetClientProcessInfo() {
    canGetClientProcessInfo = isListPortEnabled()
}
var canGetClientProcessInfo: Bool = false;


class ESObserverFactory: ObserverFactory {
    override func getObserverForAdapterSocket(_ socket: AdapterSocket) -> Observer<AdapterSocketEvent>? {
        return ESAdapterSocketObserver()
    }
    class ESAdapterSocketObserver: Observer<AdapterSocketEvent> {
        override func signal(_ event: AdapterSocketEvent) {
            switch event {
            case .readData(let data, _):
                TrafficMonitor.shared.updateRx(rx: data.count)
            case .socketOpened(let socket, let request):
                if let rule = request.matchedRule {
                    DDLogInfo("Request: \(request.host) Type: \(socket) Rule: \(rule)")
                }
            default:
                break
            }
            switch event {
            case .errorOccured:
                DDLogError("\(event)")
            case .socketOpened,
                 .disconnected,
                 .connected:
                DDLogDebug("\(event)")
            case .readyForForward:
                DDLogVerbose("\(event)")
            case .disconnectCalled,
                 .forceDisconnectCalled:
                DDLogDebug("\(event)")
            case .readData,
                .wroteData:
                DDLogVerbose("\(event)")
            }
        }
    }

    override open func getObserverForTunnel(_ tunnel: Tunnel) -> Observer<TunnelEvent>? {
        return DebugTunnelObserver()
    }
    open class DebugTunnelObserver: Observer<TunnelEvent> {
        override open func signal(_ event: TunnelEvent) {
            switch event {
            case .receivedRequest:
                DDLogInfo("\(event)")
            case .opened,
                 .connectedToRemote,
                 .updatingAdapterSocket:
                DDLogVerbose("\(event)")
            case .closeCalled,
                 .closed,
                 .forceCloseCalled,
                 .receivedReadySignal,
                 .proxySocketReadData,
                 .proxySocketWroteData,
                 .adapterSocketReadData,
                 .adapterSocketWroteData:
                DDLogDebug("\(event)")
            }
            switch event {
            case .opened(let tunnel):
                if canGetClientProcessInfo { getClientProcessInfo(tunnel: tunnel) }
            default:
                break
            }
        }
        func getClientProcessInfo(tunnel: Tunnel) {
            guard let clientPort = tunnel.clientPort else { return }
            var pid: Int32 = -1;
            guard let program = ListPortRPC(UInt32(clientPort), &pid) else {
                DDLogWarn("\(tunnel) client process not found for \(clientPort).")
                return
            }
            DDLogInfo("\(tunnel) request from \(clientPort), process \(pid) \(program)")
            tunnel.clientPid = Int(pid)
            tunnel.clientProgram = program
        }
    }
    
    override func getObserverForProxySocket(_ socket: ProxySocket) -> Observer<ProxySocketEvent>? {
        return ESProxySocketObserver()
    }
    open class ESProxySocketObserver: Observer<ProxySocketEvent> {
        override open func signal(_ event: ProxySocketEvent) {
            switch event {
            case .readData(let data, _):
                TrafficMonitor.shared.updateTx(tx: data.count)
            default:
                break;
            }
            switch event {
            case .errorOccured:
                DDLogError("\(event)")
            case .disconnected,
                 .receivedRequest:
                DDLogDebug("\(event)")
            case .socketOpened,
                 .askedToResponseTo,
                 .readyForForward:
                DDLogVerbose("\(event)")
            case .disconnectCalled,
                 .forceDisconnectCalled:
                DDLogDebug("\(event)")
            case .readData,
                 .wroteData:
                DDLogVerbose("\(event)")
            }
        }
    }

    
    override open func getObserverForProxyServer(_ server: ProxyServer) -> Observer<ProxyServerEvent>? {
        return DebugProxyServerObserver()
    }
    open class DebugProxyServerObserver: Observer<ProxyServerEvent> {
        override open func signal(_ event: ProxyServerEvent) {
            switch event {
            case .started,
                 .stopped:
                DDLogInfo("\(event)")
            case let .tunnelClosed(tunnel, onServer: server):
                DDLogInfo("\(tunnel) closed, \(server.tunnels.count) sessions remaining.")
                if tunnel.rx == 0 && tunnel.tx == 0 {
                    DDLogWarn("\(tunnel) didn't transfer any data.")
                }
            case let .newSocketAccepted(socket, onServer: server):
                 DDLogInfo("\(server) accepted \(socket), \(server.tunnels.count + 1) sessions totally.")
            }
        }
    }

    open override func getObserverForRuleManager(_ manager: RuleManager) -> Observer<RuleMatchEvent>? {
        return DebugRuleManagerObserver()
    }
    open class DebugRuleManagerObserver: Observer<RuleMatchEvent> {
        open override func signal(_ event: RuleMatchEvent) {
            switch event {
            case .ruleDidNotMatch, .dnsRuleMatched:
                DDLogVerbose("\(event)")
            case .ruleMatched:
                DDLogInfo("\(event)")
            }
        }
    }
}

class TrafficMonitor: NSObject {

    public static let shared = TrafficMonitor()

    override init() {
        ObserverFactory.currentFactory = ESObserverFactory()
    }

    var rx = 0
    var tx = 0

    var rxLast = 0
    var txLast = 0
    var timestampLast = CFAbsoluteTimeGetCurrent()

    func getRate() -> (Int, Int) {
        let ts = CFAbsoluteTimeGetCurrent()
        let interval = ts - timestampLast
        guard interval > 0 else { return (0, 0) }

        timestampLast = ts

        let rxDiff = Double(rx - rxLast) / interval
        let txDiff = Double(tx - txLast) / interval

        rxLast = rx
        txLast = tx

        return (Int(rxDiff), Int(txDiff))
    }

    func updateRx(rx: Int) {
        DispatchQueue.main.async {
            self.rx += rx
        }
    }
    func updateTx(tx: Int) {
        DispatchQueue.main.async {
            self.tx += tx
        }
    }

    @objc func updateTraffic() {
        let (rx, tx) = getRate()
        callback?(rx, tx)
    }
    var timer: Timer!
    var callback: ((Int, Int) -> Void)?
    public func startUpdate(callback: @escaping (Int, Int) -> Void) {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTraffic), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
        self.callback = callback
        updateTraffic()
    }
    public func stopUpdate() {
        timer?.invalidate()
        timer = nil
        self.callback = nil
    }
}


