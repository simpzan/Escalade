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

    func loadManager(callback: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if error == nil {
                callback(managers?.first)
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

    @IBAction func tunnel(_ sender: Any) {
        getManager { manager in
            if manager == nil { return NSLog("get manager failed") }

            do {
                try manager!.connection.startVPNTunnel(options: nil)
                NSLog("started")
            } catch {
                NSLog("start error \(error)")
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
