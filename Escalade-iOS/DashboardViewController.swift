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
    
    func pingTest() {
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
