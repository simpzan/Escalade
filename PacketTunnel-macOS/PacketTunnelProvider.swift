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

public let groupId = "group.com.simpzan.Escalade.macOS"

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

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        DDLogInfo("startTunnel \(self) \(options*)")
        
        self.addObserver(self, forKeyPath: "defaultPath", options: [.new], context: nil)
//        proxyService?.start()
        
        setTunnelNetworkSettings(tunController.getTunnelSettings()) { (error) in
            if error != nil {
                DDLogError("setTunnelNetworkSettings error:\(error!)")
                return
            }
            self.api?.start()
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DDLogInfo("stopTunnel \(self) \(reason)")
        self.removeObserver(self, forKeyPath: "defaultPath")
        proxyService?.stop()
        api?.stop()
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
