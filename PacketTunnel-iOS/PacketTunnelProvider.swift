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

private let fileLogger: DDFileLogger? = {
    defaultDebugLevel = .info
    DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs

    let logger = DDFileLogger()!
    logger.rollingFrequency = TimeInterval(60*60*12)
    logger.logFileManager.maximumNumberOfLogFiles = 3
    DDLog.add(logger, with: .debug)
    return logger
}()

class PacketTunnelProvider: NEPacketTunnelProvider {

    lazy var manager: VPNManager = {
        VPNManager(provider: self)
    }()

    func getTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.mtu = 1500
        settings.dnsSettings = NEDNSSettings(servers: ["114.114.114.114"])
        let v4Settings = NEIPv4Settings(addresses:["192.0.2.1"], subnetMasks:["255.255.255.0"])
        v4Settings.includedRoutes = [NEIPv4Route.default()]
//        v4Settings.excludedRoutes = [NEIPv4Route(destinationAddress:"114.114.114.114", subnetMask:"255.255.255.255")]
        settings.iPv4Settings = v4Settings
//        settings.proxySettings = getProxySettings()
        return settings
    }
    func getProxySettings() -> NEProxySettings {
        let proxy = NEProxySettings()
        proxy.httpEnabled = true
        proxy.httpServer = NEProxyServer(address: manager.httpProxyAddress, port: Int(manager.httpProxyPort))
        proxy.httpsEnabled = true
        proxy.httpsServer = proxy.httpServer
//        proxy.autoProxyConfigurationEnabled = true
//        proxy.proxyAutoConfigurationURL
        proxy.excludeSimpleHostnames = true
        proxy.matchDomains = []
        return proxy
    }

    private var logFile: String? {
        return fileLogger?.logFileManager?.sortedLogFilePaths?.first
    }

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLogInfo("startTunnel \(self) \(options)")
        NSLog("log file \(logFile)")

        self.addObserver(self, forKeyPath: "defaultPath", options: [.new], context: nil)
        manager.start()

        setTunnelNetworkSettings(getTunnelSettings()) { (error) in
            if error != nil {
                DDLogError("setTunnelNetworkSettings error:\(error)")
                return
            }
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DDLogInfo("stopTunnel \(self) \(reason)")
        NSLog("log file \(logFile)")
        self.removeObserver(self, forKeyPath: "defaultPath")
        manager.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DDLogDebug("defaultPath changed")
        manager.reset()
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        DDLogInfo("about to sleep...")
        manager.stop()
        completionHandler()
    }

    override func wake() {
        DDLogInfo("about to wake...")
        manager.start()
    }

    deinit {
        DDLogDebug("deinit \(self)")
    }
}
