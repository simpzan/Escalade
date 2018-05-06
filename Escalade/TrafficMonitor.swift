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

class ESObserverFactory: ObserverFactory {
    override func getObserverForAdapterSocket(_ socket: AdapterSocket) -> Observer<AdapterSocketEvent>? {
        return ESAdapterSocketObserver()
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
        }
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


