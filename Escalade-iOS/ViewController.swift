//
//  ViewController.swift
//  Escalade-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift
import SVProgressHUD
import NEKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let manager = VPNManager.shared


    @IBOutlet weak var pingButton: UIBarButtonItem!
    @IBAction func pingClicked(_ sender: Any) {
        if !manager.connected {
            SVProgressHUD.showError(withStatus: "VPN not enabled")
            return
        }
        SVProgressHUD.showInfo(withStatus: "auto selecting...\nwill finish in 4 seconds")
        api.autoSelect { (result) in
            DDLogInfo("auto selelct result \(result)")
            self.servers = result
            self.current = getCurrentServer()
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
    }

    let api = APIClient.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = loadConfig()
        
        api.getServersAsync { (servers) in
            if let servers = servers {
                self.servers = servers
                self.tableView.reloadData()
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(serversUpdated), name: serversUpdatedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func serversUpdated() {
        _ = loadConfig()
    }

    @IBOutlet weak var tableView: UITableView!
    public func loadConfig() -> Bool {
        guard let adapterFactoryManager = createAdapterFactoryManager() else {
            DDLogError("failed to load servers")
            return false
        }
        let serverNames = adapterFactoryManager.selectFactory.servers
        servers = serverNames.map({ (server) -> (String, String) in
            return (server, "")
        })
        current = getCurrentServer()
        tableView.reloadData()
        return true
    }

    var current: String? = nil
    var servers: [(String, String)] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (server, ping) = servers[indexPath.row]
        let isCurrent = current != nil && server == current!
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigCell")!
        cell.textLabel?.text = server
        cell.detailTextLabel?.text = ping
        cell.accessoryType = isCurrent ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let (server, _) = servers[indexPath.row]
        saveDefaults(key: currentServerKey, value: server)
        current = server
        if manager.connected {
            let result = api.switchServer(server: server)
            DDLogInfo("switch server result: \(result)")
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

