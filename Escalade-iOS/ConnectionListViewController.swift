//
//  ConnectionListViewController.swift
//  Escalade-iOS
//
//  Created by simpzan on 01/07/2018.
//

import UIKit
import CocoaLumberjackSwift

class ConnectionListViewController: UITableViewController {
    override func viewDidLoad() {
        updateList()
        dateFormatter.dateFormat = "MM-dd HH:mm:ss:SSS"
    }
    let dateFormatter = DateFormatter()

    @IBAction func refreshConnectionList(_ sender: Any) {
        updateList()
    }
    
    func updateList() {
        api.getConnections { (connections) in
            DDLogInfo("connections \(connections*)")
            guard let connections = connections else { return }
            let sorted = connections.sorted { (left: ConnectionRecord, right: ConnectionRecord) -> Bool in
                return left.createdTime > right.createdTime
            }
            self.connections = sorted.filter { $0.active }
            self.closeConnections = sorted.filter { !$0.active }
            self.tableView.reloadData()
        }
    }
    var closeConnections = [ConnectionRecord]()
    var connections = [ConnectionRecord]()
    let api = APIClient.shared

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Active Connections" : "Inactive Connections"
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let list = section == 0 ? connections : closeConnections
        return list.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = indexPath.section == 0 ? connections : closeConnections
        let connection = list[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectionCell")!
        cell.textLabel?.text = connection.remoteEndpoint;
        cell.detailTextLabel?.text = dateFormatter.string(from: connection.createdTime)
        return cell;
    }
}
