//
//  ViewController.swift
//  Escalade-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {
    @IBOutlet weak var connectSwitch: UISwitch!
    @IBAction func connectClicked(_ sender: Any) {
        NSLog("connectClicked")
        if status == .connected {
            stopVPN()
        } else {
            startVPN()
        }
        NSLog("connection \(connection)")
    }
    func updateConnectSwitch() {
        NotificationCenter.default.addObserver(self, selector: #selector(connectionChanged), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    func connectionChanged() {
        let state = status
        NSLog("status changed to \(state.rawValue)")
        let disabledStates: [NEVPNStatus] = [.disconnecting, .connecting, .reasserting]
        connectSwitch.isEnabled = !disabledStates.contains(state)
        let onStates: [NEVPNStatus] = [.connected, .connecting, .reasserting]
        connectSwitch.setOn(onStates.contains(state), animated: true)
    }
    var status: NEVPNStatus {
        guard let connection = connection else { return .invalid }
        return connection.status
    }
    var connection: NEVPNConnection? {
        return manager?.connection
    }

    @IBAction func test(_ sender: Any) {
        let result = callAPI(id: getServersId)
        NSLog("getServers \(result)")
    }

    func createManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        let config = NETunnelProviderProtocol()
        config.providerBundleIdentifier = "com.simpzan.Escalade-iOS.PacketTunnel-iOS"
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

    var manager: NETunnelProviderManager? = nil

    func loadManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
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
    func getManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        loadManager { manager in
            if manager != nil { return callback(manager) }

            self.createManager { manager in
                self.loadManager(callback: callback)
            }
        }
    }

    func saveConfig() {
        let config = Bundle.main.fileContent("fyzhuji.yaml")!
        save(key: configKey, value: config)
    }
    @IBAction func tunnel(_ sender: Any) {

        getManager { manager in
            if manager == nil { return NSLog("get manager failed") }
            self.startVPN()
        }
    }
    func startVPN() {
        guard let manager = manager else { return }

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
    func stopVPN() {
        guard let manager = manager else { return }

        manager.connection.stopVPNTunnel()
        NSLog("stopped")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateConnectSwitch()
        loadManager { (_) in
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

