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
import FileBrowser

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
        let enabled = [.connected, .disconnected, .invalid].contains(state)
        connectSwitch.isEnabled = enabled && servers.count > 0
        let on = [.connected, .connecting, .reasserting].contains(state)
        connectSwitch.setOn(on, animated: true)
        NSLog("status changed to \(state.description), enabled: \(enabled), on: \(on)")
    }


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
            self.current = loadDefaults(key: self.currentServerKey)
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
    }

    let api = APIClient()
    
    func networkRequestTests() {
        let actions = ["GCDAsyncSocket_HTTP", "NSURLSession", "DNS", "UDP"]
        self.select(actions, title: "Network Tests") { (index) in
            switch index {
            case 0:
                GCDAsyncSocket.httpRequest("simpzan.com", 8000)
            case 1:
                NSURLSessionHttpTest("http://simpzan.com:8000")
            case 2:
                dnsTest("simpzan.com")
            case 3:
                udpSend("159.89.119.178", 8877, "hello from iphone")
            default:
                DDLogDebug("nothing to do")
            }
        }
    }
    
    @IBAction func test(_ sender: Any) {
        let actions = ["DumpTunnel", "ReportIssue", "View log files", "Toggle proxy service", "Network Tests"]
        self.select(actions, title: "choose action", { (index) in
            switch index {
            case 0:
                self.manager.sendMessage(msg: "dumpTunnel")
            case 1:
                self.manager.sendMessage(msg: "reportIssue")
            case 2:
                self.showLogFiles()
            case 3:
                self.manager.sendMessage(msg: "toggleProxyService")
            case 4:
                self.networkRequestTests()
            default:
                DDLogDebug("nothing")
            }
        })
    }
    
    func showLogFiles() {
        let initialPath = getContainerDir(groupId: groupId, subdir: "/Logs/")
        let fileBrowser = FileBrowser(initialPath: URL(fileURLWithPath: initialPath))
        present(fileBrowser, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = loadConfig()
        
        connectionChanged()
        manager.monitorStatus { (_) in
            self.connectionChanged()
        }

        api.getServersAsync { (servers) in
            if let servers = servers {
                self.servers = servers
                self.tableView.reloadData()
            }
        }
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
        current = loadDefaults(key: currentServerKey)
        tableView.reloadData()
        connectionChanged()
        return true
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

