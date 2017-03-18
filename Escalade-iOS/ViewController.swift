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
    let manager = VPNManager()

    @IBOutlet weak var connectSwitch: UISwitch!
    @IBAction func connectClicked(_ sender: Any) {
        NSLog("connectClicked")
        if manager.connected {
            manager.stopVPN()
        } else {
            manager.startVPN()
        }
    }

    func connectionChanged() {
        let state = manager.status
        NSLog("status changed to \(state.rawValue)")
        let disabledStates: [NEVPNStatus] = [.disconnecting, .connecting, .reasserting]
        connectSwitch.isEnabled = !disabledStates.contains(state)
        let onStates: [NEVPNStatus] = [.connected, .connecting, .reasserting]
        connectSwitch.setOn(onStates.contains(state), animated: true)
    }


    @IBAction func test(_ sender: Any) {
        let result = callAPI(id: getServersId)
        NSLog("getServers \(result)")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        manager.monitorStatus { (_) in
            self.connectionChanged()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

