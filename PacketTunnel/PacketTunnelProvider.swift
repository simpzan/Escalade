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

class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var proxyService: ProxyService? = {
        guard let adapterFactoryManager = createAdapterFactoryManager() else {
            DDLogError("failed to load servers.")
            return nil
        }
        let service = ProxyService(adapterFactoryManager: adapterFactoryManager, provider: self, defaults: defaults)
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
        return APIServer(self.proxyService!)
    }()
    let trafficMonitorServer = TrafficMonitorServer()
    
    var timer: Repeater? = nil
    
    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        var logLevel: DDLogLevel = .debug
#if !DEBUG
        logLevel = .info
        if !crashlyticsInitialized {
            UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
            Fabric.with([Crashlytics.self])
            crashlyticsInitialized = true
        }
#endif

        let path = getContainerDir(groupId: groupId, subdir: "/Logs/")
        setupLog(logLevel, path)
        ObserverFactory.currentFactory = ESObserverFactory()

        timer = Repeater.every(.minutes(1)) { (repeater) in
            let memory = memoryUsage()
            let cpu = cpuUsage()
            let systemCpu = systemCpuUsage()
            DDLogInfo(String(format: "memory: %lld bytes, cpu: %.2f%% app, %.2f%% system.", memory, cpu, systemCpu))
        }
        timer?.fire()

        DDLogInfo("startTunnel \(self) \(options*)")
        connectivity.listenNetworkChange { (from: NetworkType, to: NetworkType) in
            DDLogInfo("network changed from \(from.description) to \(to.description)")
            if from == .None && to != .None {
                self.proxyService?.start()
            } else if from != .None && to == .None {
                self.proxyService?.stop()
            } else {
                self.proxyService?.restart()
            }
        }
        setTunnelNetworkSettings(tunController.getTunnelSettings()) { (error) in
            if error != nil {
                DDLogError("setTunnelNetworkSettings error:\(error!)")
                return
            }
            self.proxyService?.start()
            self.api?.start()
            updateCanGetClientProcessInfo()
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
            _ = proxyService?.proxyManager.dump()
            completionHandler?(nil)
        case "toggleProxyService":
            proxyService?.toggle()
        default:
            if msg.starts(with: "reportIssue") {
                DDLogError("############ReportIssue############")
                DDLogError("\(msg)")
                return
            }
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
