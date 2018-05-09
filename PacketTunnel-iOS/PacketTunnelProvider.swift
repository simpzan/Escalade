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

public let groupId = "group.com.simpzan.Escalade.iOS"

class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var proxyService: ProxyService? = {
        guard let configString = loadDefaults(key: configKey) else {
            DDLogError("no config yet.")
            return nil
        }
        guard let config = loadConfiguration(content: configString) else {
            DDLogError("fail to parse config: \n\(configString)")
            return nil
        }
        let service = ProxyService(config: config, provider: self, defaults: defaults)
        DDLogInfo("loaded servers \(service.serverController.servers)")
        return service
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
        setupLog(.debug)
        DDLogInfo("startTunnel \(self) \(options*)")
        connectivity.listenNetworkChange { (type) in
            DDLogInfo("network changed to \(type.description), restarting proxy service")
            self.proxyService?.restart()
        }
        setTunnelNetworkSettings(tunController.getTunnelSettings()) { (error) in
            if error != nil {
                DDLogError("setTunnelNetworkSettings error:\(error!)")
                return
            }
            self.proxyService?.start()
            self.api?.start()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DDLogInfo("stopTunnel \(self) \(reason)")
        connectivity.stopListening()
        proxyService?.stop()
        api?.stop()
        completionHandler()
    }
    
    private lazy var connectivity: ConnectivityManager! = {
        return ConnectivityManager(provider: self)
    }()

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        guard let msg = String(data: messageData, encoding: .utf8) else { return }
        DDLogInfo("received request \(msg)")
        switch msg {
        case "dumpTunnel":
            proxyService?.proxyManager.dump()
            completionHandler?(nil)
        case "reportIssue":
            DDLogError("############ReportIssue############")
        default:
            DDLogWarn("unknown msg \(msg)")
        }
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

extension NetworkType {
    var description: String {
        let descriptions = ["None", "Wifi", "Cellular"]
        return descriptions[self.rawValue]
    }
}
