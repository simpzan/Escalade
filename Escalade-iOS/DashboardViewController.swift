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
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        nc.addObserver(self, selector: #selector(updateUI), name: serversUpdatedNotification, object: nil)
    }
    @objc func appWillEnterForeground() {
        DDLogInfo("appWillEnterForeground")
        guard self.visible else { return }
        startTrafficMonitor()
        testConnectivity()
    }
    @objc func appDidEnterBackground() {
        DDLogInfo("appDidEnterBackground")
        guard self.visible else { return }
        stopTrafficMonitor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTrafficMonitor()
        updateCurrentServer()
        testConnectivity()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTrafficMonitor()
    }
    
    @objc func updateUI() {
        connectionChanged()
        updateCurrentServer()
    }

    func connectionChanged() {
        let state = manager.status
        let enabled = [.connected, .disconnected, .invalid].contains(state)
        connectSwitch.isEnabled = enabled && getCurrentServer() != nil
        let on = [.connected, .connecting, .reasserting].contains(state)
        connectSwitch.setOn(on, animated: true)
        NSLog("status changed to \(state.description), enabled: \(enabled), on: \(on)")

        testConnectivity()
        if state == .connected {
            startTrafficMonitor()
        } else {
            stopTrafficMonitor()
        }
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
    @IBOutlet weak var connectivityLabel: UILabel!
    
    func startTrafficMonitor() {
        guard manager.connected else { return }
        monitor.startUpdate { (rx, tx) in
            self.trafficCell.textLabel?.text = "⬇︎ \(readableSize(rx))/s, ⬆︎ \(readableSize(tx))/s"
        }
    }
    func stopTrafficMonitor() {
        guard manager.connected else { return }
        monitor.stopUpdate()
    }
    let monitor = TrafficMonitorClient()
    @IBOutlet weak var trafficCell: UITableViewCell!
    
    @objc func updateCurrentServer() {
        let current = getCurrentServer()
        self.currentServerCell.textLabel?.text = current
        tableView.reloadData() // force update current server cell.
    }
    @IBOutlet weak var currentServerCell: UITableViewCell!
    
    let api = APIClient.shared

    func testConnectivity() {
        guard manager.connected else {
            connectivityLabel.text = "VPN disabled"
            return
        }

        direct = ""
        proxy = ""
        api.pingDirect { (result) in
            self.direct = miliseconds(result ?? -1)
            self.updateConnectivityInfo()
        }
        api.pingProxy { (result) in
            self.proxy = miliseconds(result ?? -1)
            self.updateConnectivityInfo()
        }
        DDLogInfo("ping testing...")
        connectivityLabel.text = "ping testing..."
    }
    func updateConnectivityInfo() {
        let status = "China \(direct), World \(proxy)"
        DDLogInfo("ping test \(status)")
        connectivityLabel.text = status
    }
    var direct: String = ""
    var proxy: String = ""

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
        let actions = ["ReportIssue", "Toggle verbose logging", "Toggle proxy service", "Network Tests", "Reset Data", "Connections"]
        self.select(actions, title: "choose action", { (index) in
            switch index {
            case 0:
                self.getTextInput(withTitle: "What is the issue?", { (issue) in
                    guard let issue = issue else { return }
                    self.manager.sendMessage(msg: "reportIssue.\(issue)")
                    self.manager.sendMessage(msg: "dumpTunnel")
                })
            case 1:
                self.api.toggleVerboseLogging()
            case 2:
                self.manager.sendMessage(msg: "toggleProxyService")
            case 3:
                self.networkRequestTests()
            case 4:
                resetData()
            case 5:
                self.api.getConnections { (connections) in
                    DDLogInfo("connections \(connections*)")
                }
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
    
    func pingTest() {
        if !manager.connected {
            SVProgressHUD.showError(withStatus: "VPN not enabled")
            return
        }
        SVProgressHUD.showInfo(withStatus: "auto selecting...\nwill finish in 4 seconds")
        api.autoSelect { (result) in
            DDLogInfo("auto selelct result \(result)")
            let current = result.first!
            self.proxy = current.1
            self.updateConnectivityInfo()
            self.currentServerCell.textLabel?.text = "\(current.0)"
            SVProgressHUD.dismiss()
        }
    }
    private func showSystemStatus() {
        guard let result = api.getSystemStatus() else { return }
        let memory = Int(result["memory"]!)
        let cpu = Double(result["extensionCpu"]!) / 1000
        let extensionInfo = "extension: \(cpu)%, \(readableSize(memory))"
        let appMemory = Int(memoryUsage())
        let appCpu = cpuUsage()
        let appInfo = "app: \(appCpu)%, \(readableSize(appMemory))"
        let systemCpu = systemCpuUsage()
        let systemInfo = String(format: "system: %.2f%%.", systemCpu)
        self.select([extensionInfo, appInfo, systemInfo], title: "System Status") { (_) in
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cellId = tableView.cellForRow(at: indexPath)?.reuseIdentifier else { return }
        
        DDLogInfo("selected \(cellId)")
        switch cellId {
        case "connectivityCell":
            testConnectivity()
        case "logsCell":
            showLogFiles()
        case "pingTestCell":
            pingTest()
        case "systemStatusCell":
            showSystemStatus()
        default:
            break
        }
    }
}

extension UIViewController {
    public var visible: Bool {
        return self.viewIfLoaded?.window != nil
    }
}
