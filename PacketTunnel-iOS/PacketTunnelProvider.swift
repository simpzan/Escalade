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
import Fabric
import Crashlytics

var crashlyticsInitialized = false

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

    
    var timer: Repeater? = nil
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        if !crashlyticsInitialized {
            Fabric.with([Crashlytics.self])
            crashlyticsInitialized = true
        }

        let path = getContainerDir(groupId: groupId, subdir: "/Logs/PacketTunnel/")
        setupLog(.debug, path)
        
        timer = Repeater.every(.minutes(1)) { (repeater) in
            let memory = memoryUsage()
            let cpu = cpuUsage()
            DDLogInfo("memory: \(memory) bytes, cpu: \(cpu)")
        }
        timer?.fire()

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
        DDLogInfo("stopTunnel \(self) \(reason.description)")
        timer?.pause()
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
        timer?.pause()
        proxyService?.stop()
        completionHandler()
    }

    override func wake() {
        DDLogInfo("about to wake...")
        timer?.start()
        proxyService?.start()
    }

    deinit {
        DDLogDebug("deinit \(self)")
        timer = nil
    }
}

extension NetworkType {
    var description: String {
        let descriptions = ["None", "Wifi", "Cellular"]
        return descriptions[self.rawValue]
    }
}

extension NEProviderStopReason {
    var description: String {
        let descriptions = [
            "None",
            "UserInitiated",
            "ProviderFailed",
            "NoNetworkAvailable",
            "UnrecoverableNetworkChange",
            "ProviderDisabled",
            "AuthenticationCanceled",
            "ConfigurationFailed",
            "IdleTimeout",
            "ConfigurationDisabled",
            "ConfigurationRemoved",
            "Superceded",
            "UserLogout",
            "UserSwitch"
        ]
        return descriptions[self.rawValue]
    }
}
