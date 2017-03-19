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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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


    @IBOutlet weak var pingButton: UIBarButtonItem!
    @IBAction func pingClicked(_ sender: Any) {
        api.autoSelect { (result) in
            DDLogInfo("auto selelct result \(result)")
            self.servers = result
            self.tableView.reloadData()
        }
    }

    let api = APIClient()

    @IBAction func test(_ sender: Any) {
        let result = api.getServers()
        NSLog("getServers \(result)")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfig()
        
        manager.monitorStatus { (_) in
            self.connectionChanged()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBOutlet weak var tableView: UITableView!
    func loadConfig() {
        let configString = manager.configString
        guard let config = loadConfiguration(content: configString) else { return }
        let serverNames = config.adapterFactoryManager.selectFactory.servers
        servers = serverNames.map({ (server) -> (String, String) in
            return (server, "")
        })
        current = load(key: currentServerKey)
        tableView.reloadData()
    }

    let currentServerKey = "currentServer"
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
        save(key: currentServerKey, value: server)
        current = server
        let result = api.switchServer(server: server)
        DDLogInfo("switch server result: \(result)")
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

