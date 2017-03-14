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

extension DDLogFlag: CustomStringConvertible {
    public var description: String {
        switch self {
        case DDLogFlag.error:   return "E"
        case DDLogFlag.warning: return "W"
        case DDLogFlag.info:    return "I"
        case DDLogFlag.debug:   return "D"
        case DDLogFlag.verbose: return "V"
        default:                return " "
        }
    }
}
class LogFormatter: NSObject, DDLogFormatter {
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "MM-dd HH:mm:ss:SSS"
        return formatter
    }()
    public func format(message logMessage: DDLogMessage!) -> String! {
        let time = formatter.string(from: logMessage.timestamp)
        let file = "\(logMessage.fileName!):\(logMessage.line)"
        return "\(time) \(logMessage.flag) \(file) \t\(logMessage.message ?? "")"
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let logFile: String? = {
        DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
        DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs

        let logger = DDFileLogger()!
        logger.rollingFrequency = TimeInterval(60*60*12)
        logger.logFileManager.maximumNumberOfLogFiles = 3
        logger.logFormatter = LogFormatter()
        DDLog.add(logger, with: .debug)

        return logger.logFileManager?.sortedLogFilePaths.first
    }()

    lazy var manager: VPNManager = {
        VPNManager(provider: self)
    }()

    func getTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.mtu = 1500
        settings.dnsSettings = NEDNSSettings(servers: ["114.114.114.114"])
        let v4Settings = NEIPv4Settings(addresses:["192.0.2.1"], subnetMasks:["255.255.255.0"])
        v4Settings.includedRoutes = [NEIPv4Route.default()]
        v4Settings.excludedRoutes = [NEIPv4Route(destinationAddress:"114.114.114.114", subnetMask:"255.255.255.255")]
        settings.iPv4Settings = v4Settings
        settings.proxySettings = getProxySettings()
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

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLogInfo("startTunnel \(self) \(options)")
        NSLog("log file \(logFile)")

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
        manager.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if let handler = completionHandler {
			handler(messageData)
		}
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

}
