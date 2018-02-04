//
//  VPNManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/19/17.
//
//

import Foundation
import NetworkExtension
import CocoaLumberjackSwift

class VPNManager: NSObject {
    public override init() {
        super.init()
        loadManager { (manager) in
            DDLogInfo("load manager result \(manager)")
            self.connectionChanged()
        }
    }

    public func monitorStatus(callback: @escaping (NEVPNStatus) -> Void) {
        NotificationCenter.default.addObserver(self, selector: #selector(connectionChanged), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        self.callback = callback
    }
    func connectionChanged() {
        callback?(status)
    }
    private var callback: StatusCallback?
    public typealias StatusCallback = (NEVPNStatus) -> Void

    public var status: NEVPNStatus {
        guard let connection = connection else { return .invalid }
        return connection.status
    }
    private var connection: NEVPNConnection? {
        return manager?.connection
    }
    public var connected: Bool {
        return status == .connected
    }
    
    private func createManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        let config = NETunnelProviderProtocol()
        config.providerBundleIdentifier = providerBundleIdentifier
        config.serverAddress = "10.0.0.2"

        let manager = NETunnelProviderManager()
        manager.protocolConfiguration = config
        manager.isEnabled = true
        manager.saveToPreferences { (error) in
            if error == nil {
                callback(manager)
            } else {
                NSLog("create manager error \(error)")
                callback(nil)
            }
        }
    }

    private var manager: NETunnelProviderManager? = nil

    private func loadManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if error == nil {
                let manager = managers?.first
                self.manager = manager
                callback(manager)
            } else {
                NSLog("load managers failed \(error)")
                callback(nil)
            }
        }
    }
    private func getManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        loadManager { manager in
            if manager != nil { return callback(manager) }

            self.createManager { manager in
                self.loadManager(callback: callback)
            }
        }
    }

    let configString = Bundle.main.fileContent("fyzhuji.yaml")!
    private func saveConfig() {
        save(key: configKey, value: configString)
    }
    public func startVPN() {
        getManager { (manager) in
            guard let manager = manager else { return }

            self.saveConfig()

            manager.isEnabled = true
            manager.saveToPreferences { error in
                if error != nil { return NSLog("failed to enable manager") }

                do {
                    try manager.connection.startVPNTunnel(options: nil)
                    NSLog("started")
                } catch {
                    NSLog("start error \(error)")
                }
            }
        }
    }
    public func stopVPN() {
        guard let manager = manager else { return }

        manager.connection.stopVPNTunnel()
        NSLog("stopped")
    }

}
