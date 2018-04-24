//
//  PacketTunnelProvider.swift
//  PacketTunnel-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import NetworkExtension
import NEKit
import CocoaLumberjackSwift

public let groupId = "group.simpzan.Escalade-iOS"

class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var proxyService: ProxyService? = {
        guard let configString = load(key: configKey) else {
            return nil
        }
        guard let config = loadConfiguration(content: configString) else { return nil }
        return ProxyService(config: config, provider: self, defaults: defaults)
    }()
    var tunController: TUNController {
        return (proxyService?.tunController)!
    }
    var serverController: ServerController {
        return proxyService!.serverController
    }
    lazy var api: APIServer? = {
        return APIServer(self.serverController)
    }()

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLogInfo("startTunnel \(self) \(options)")
        NSLog("log file \(logFile)")

        self.addObserver(self, forKeyPath: "defaultPath", options: [.new], context: nil)

        setTunnelNetworkSettings(tunController.getTunnelSettings()) { (error) in
            if error != nil {
                DDLogError("setTunnelNetworkSettings error:\(error)")
                return
            }
            self.proxyService?.start()
            self.api?.start()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DDLogInfo("stopTunnel \(self) \(reason)")
        NSLog("log file \(logFile)")
        self.removeObserver(self, forKeyPath: "defaultPath")
        proxyService?.stop()
        api?.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        let msg = String(data: messageData, encoding: .utf8)
        DDLogInfo("received request \(msg)")
        if (msg == "dumpTunnel") {
            proxyService?.proxyManager.dump()
            completionHandler?(nil)
            return
        }
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DDLogInfo("defaultPath changed")
//        proxyService?.restart()
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        DDLogInfo("about to sleep...")
        proxyService?.stop()
        completionHandler()
    }

    override func wake() {
        DDLogInfo("about to wake...")
        proxyService?.start()
    }

    deinit {
        DDLogDebug("deinit \(self)")
    }
}


func getConnectivityState() -> ConnectivityState {
    let addrs = getNetworkAddresses()

    var result = ConnectivityState.none
    if addrs?["en0"] != nil { result = .wifi }
    else if addrs?["pdp_ip0"] != nil { result = .celluar }

    DDLogDebug("connectivity state \(result), addrs \(addrs)")
    return result
}
enum ConnectivityState {
    case wifi, celluar, none
}

