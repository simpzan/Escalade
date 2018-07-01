//
//  ConnectionDetailViewController.swift
//  Escalade-iOS
//
//  Created by simpzan on 01/07/2018.
//

import UIKit

class ConnectionDetailViewController: UITableViewController {
    var connection: ConnectionRecord!
    
    override func viewDidLoad() {
        remoteCell.textLabel?.text = connection?.remoteEndpoint
        trafficCell.textLabel?.text = "⬇︎ \(readableSize(connection.rx)), ⬆︎ \(readableSize(connection.tx))"
        ruleCell.textLabel?.text = connection?.matchedRule
        createdTimeCell.textLabel?.text = connection?.createdTime.description(with: Locale.current)
        closedTimeCell.textLabel?.text = connection?.closedTime?.description(with: Locale.current)
    }
    
    @IBOutlet weak var remoteCell: UITableViewCell!
    @IBOutlet weak var trafficCell: UITableViewCell!
    @IBOutlet weak var ruleCell: UITableViewCell!
    @IBOutlet weak var createdTimeCell: UITableViewCell!
    @IBOutlet weak var closedTimeCell: UITableViewCell!
}
