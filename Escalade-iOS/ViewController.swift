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
        callAPIAsync(id: autoSelectId) { result in
            DDLogInfo("auto selelct result \(result)")
            self.tableView.reloadData()
        }
    }

    @IBAction func test(_ sender: Any) {
        let result = callAPI(id: getServersId)
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
        servers = config.adapterFactoryManager.selectFactory.servers
        tableView.reloadData()
    }

    var servers: [String] = []
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let server = servers[indexPath.row]
        let result = callAPI(id: switchProxyId, obj: server as NSCoding?);
        DDLogInfo("switch server result: \(result)")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let server = servers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigCell")!
        cell.textLabel?.text = server
        cell.detailTextLabel?.text = ""
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

