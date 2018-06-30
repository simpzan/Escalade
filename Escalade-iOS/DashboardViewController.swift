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
    }
    
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
