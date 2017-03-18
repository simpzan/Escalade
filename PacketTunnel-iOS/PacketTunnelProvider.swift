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
    private lazy var proxyService: ProxyService? = {
        let configManager = ConfigurationManager()
        if !configManager.reloadConfigurations() { return nil }
        return ProxyService(config: configManager.current!, provider: self)
    }()
    var tunController: TUNController {
        return (proxyService?.tunController)!
    }

    private var logFile: String? {
        return fileLogger?.logFileManager?.sortedLogFilePaths?.first
    }

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLogInfo("startTunnel \(self) \(options)")
        NSLog("log file \(logFile)")

        self.addObserver(self, forKeyPath: "defaultPath", options: [.new], context: nil)
        proxyService?.start()

        setTunnelNetworkSettings(tunController.getTunnelSettings()) { (error) in
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
        proxyService?.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DDLogDebug("defaultPath changed")
        proxyService?.restart()
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
