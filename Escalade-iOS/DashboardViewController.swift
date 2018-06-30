//
//  DashboardViewController.swift
//  Escalade-iOS
//
//  Created by simpzan on 30/06/2018.
//

import UIKit
import SVProgressHUD
import CocoaLumberjackSwift

class DashboardViewController: UITableViewController {
    override func viewDidLoad() {
        connectionChanged()
        manager.monitorStatus { (_) in
            self.connectionChanged()
        }

    }
    func connectionChanged() {
        let state = manager.status
        let enabled = [.connected, .disconnected, .invalid].contains(state)
        connectSwitch.isEnabled = enabled // && servers.count > 0
        let on = [.connected, .connecting, .reasserting].contains(state)
        connectSwitch.setOn(on, animated: true)
        NSLog("status changed to \(state.description), enabled: \(enabled), on: \(on)")
    }
    @IBAction func connectClicked(_ sender: Any) {
        if manager.connected {
            manager.stopVPN()
        } else {
            manager.startVPN()
        }
    }
    let manager = VPNManager.shared
    @IBOutlet weak var connectSwitch: UISwitch!
    @IBOutlet weak var connectivityCell: UITableViewCell!
    @IBOutlet weak var trafficCell: UITableViewCell!
    @IBOutlet weak var currentServerCell: UITableViewCell!
    
    let api = APIClient.shared

    func pingTest() {
        var direct: Double?
        var proxy: Double?
        api.pingDirect { (result) in
            direct = result ?? -1
            showResult()
        }
        api.pingProxy { (result) in
            proxy = result ?? -1
            showResult()
        }
        DDLogInfo("ping testing...")
        connectivityCell.detailTextLabel?.text = "ping testing..."
        func showResult() {
            let status = "China \(direct*), Google \(proxy*)"
            DDLogInfo("ping test \(status)")
            if direct == -1 && proxy == -1 {
                connectivityCell.detailTextLabel?.text = "ping test failed"
            } else {
                connectivityCell.detailTextLabel?.text = status
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DDLogInfo("selected \(indexPath.row)")
        switch indexPath.row {
        case 0:
            pingTest()
        default:
            DDLogInfo("")
        }
    }
}