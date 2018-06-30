//
//  DashboardViewController.swift
//  Escalade-iOS
//
//  Created by simpzan on 30/06/2018.
//

import UIKit
import SVProgressHUD
import CocoaLumberjackSwift
import FileBrowser

class DashboardViewController: UITableViewController {
    override func viewDidLoad() {
        connectionChanged()
        manager.monitorStatus { (_) in
            self.connectionChanged()
        }
        updateCurrentServer()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTrafficMonitor()
        updateCurrentServer()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTrafficMonitor()
    }

    func connectionChanged() {
        let state = manager.status
        let enabled = [.connected, .disconnected, .invalid].contains(state)
        connectSwitch.isEnabled = enabled // && servers.count > 0
        let on = [.connected, .connecting, .reasserting].contains(state)
        connectSwitch.setOn(on, animated: true)
        NSLog("status changed to \(state.description), enabled: \(enabled), on: \(on)")

        if state == .connected { startTrafficMonitor() }
        else { stopTrafficMonitor() }
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
    
    func startTrafficMonitor() {
        guard manager.connected else { return }
        monitor.startUpdate { (rx, tx) in
            self.trafficCell.detailTextLabel?.text = "⬇︎ \(readableSize(rx))/s, ⬆︎ \(readableSize(tx))/s"
        }
    }
    func stopTrafficMonitor() {
        guard manager.connected else { return }
        monitor.stopUpdate()
    }
    let monitor = TrafficMonitorClient()
    @IBOutlet weak var trafficCell: UITableViewCell!
    
    func updateCurrentServer() {
        let current = loadDefaults(key: currentServerKey)
        currentServerCell.detailTextLabel?.text = current
    }
    @IBOutlet weak var currentServerCell: UITableViewCell!
    
    let api = APIClient.shared

    func pingTest() {
        guard manager.connected else {
            connectivityCell.detailTextLabel?.text = "VPN disabled"
            return
        }

        var direct: Double = 0
        var proxy: Double = 0
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
            let status = "China \(miliseconds(direct)), World \(miliseconds(proxy))"
            DDLogInfo("ping test \(status)")
            if direct == -1 && proxy == -1 {
                connectivityCell.detailTextLabel?.text = "ping test failed"
            } else {
                connectivityCell.detailTextLabel?.text = status
            }
        }
    }
    
    
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
    
    @IBAction func openMenu(_ sender: Any) {
        let actions = ["ReportIssue", "View log files", "Toggle proxy service", "Network Tests"]
        self.select(actions, title: "choose action", { (index) in
            switch index {
            case 0:
                self.getTextInput(withTitle: "What is the issue?", { (issue) in
                    guard let issue = issue else { return }
                    self.manager.sendMessage(msg: "reportIssue.\(issue)")
                    self.manager.sendMessage(msg: "dumpTunnel")
                })
            case 1:
                self.showLogFiles()
            case 2:
                self.manager.sendMessage(msg: "toggleProxyService")
            case 3:
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
