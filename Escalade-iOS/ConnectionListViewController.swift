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
    }
    
    @IBAction func refreshConnectionList(_ sender: Any) {
        updateList()
    }
    
    func updateList() {
        api.getConnections { (connections) in
            DDLogInfo("connections \(connections*)")
            guard let connections = connections else { return }
            self.connections = connections
            self.tableView.reloadData()
        }
    }
    var connections = [ConnectionRecord]()
    let api = APIClient.shared

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let connection = connections[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectionCell")!
        cell.textLabel?.text = connection.remoteEndpoint;
        cell.detailTextLabel?.text = "⬇︎ \(readableSize(connection.rx)), ⬆︎ \(readableSize(connection.tx))"
        return cell;
    }
}
