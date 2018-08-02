//
//  MainMenuController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa
import CocoaLumberjackSwift
import Sparkle

class MainMenuController: NSObject, NSMenuDelegate, NSUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    override func awakeFromNib() {
        statusItem.toolTip = "Escalade"
        statusItem.image = NSImage(named: NSImage.Name(rawValue: "MenuBarIcon"))
        statusItem.menu = mainMenu

        mainMenu.delegate = self
        NSUserNotificationCenter.default.delegate = self

        serversItem.action = #selector(autoSelectClicked(_:))
        serversItem.target = self

        setupLog(.info, nil)

        let _ = launchHelper.validate()
        updateStartAtLoginItem()

        connectionChanged()
        manager.monitorStatus { (_) in
            self.connectionChanged()
        }
        listenReachabilityChange()
        
        updateServerList()
    }
    @IBOutlet weak var mainMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)


    func menuWillOpen(_ menu: NSMenu) {
        updateServerList()
        updateConnectivityInfo()

        if !reachability.isReachable { return }

        connectivityTest()
        trafficMonitor.startUpdate { rx, tx in
            self.networkTrafficItem.title = "⬇︎ \(readableSize(rx))/s, ⬆︎ \(readableSize(tx))/s"
        }
    }
    func menuDidClose(_ menu: NSMenu) {
        trafficMonitor.stopUpdate()
    }
    let trafficMonitor = TrafficMonitorClient()
    @IBOutlet weak var networkTrafficItem: NSMenuItem!


    // MARK: -
    func connectionChanged() {
        let enabled = manager.status == .connected
        NSLog("update system proxy state to \(enabled)")
        statusItem.button?.appearsDisabled = !enabled
        systemProxyItem.state = enabled ? .on : .off
    }
    @IBOutlet weak var systemProxyItem: NSMenuItem!
    @IBAction func systemProxyClicked(_ sender: Any) {
        if manager.connected {
            manager.stopVPN()
        } else {
            manager.startVPN()
        }
    }
    let manager = VPNManager.shared

    // MARK: - configurations
    func showSetupGuideIfNeeded() {
        if getCurrentServer() != nil { return }
        
        guard let file = selectFile() else { return }
        let url = URL(fileURLWithPath: file)
        guard importServers(url: url) else {
            return DDLogError("failed to import servers in \(url)")
        }

        NotificationCenter.default.post(name: serversUpdatedNotification, object: nil)
        sendNotification(title: "import done", text: "")
    }

    // MARK: - servers
    @IBOutlet weak var autoSelectItem: NSMenuItem!
    @objc @IBAction func autoSelectClicked(_ sender: Any?) {
        guard manager.connected else { return }
        guard autoSelectItem.isEnabled else { return }
        autoSelectItem.isEnabled = false
        sendNotification(title: "Servers Testing Started", text: "It will finish in 4 seconds.")
        api.autoSelect { (result) in
            let selected = result.first!
            let text = "auto selected \(selected.0)(\(selected.1))"
            let title = "Servers Testing Finished"
            sendNotification(title: title, text: text)
            self.autoSelectItem.isEnabled = true
        }
    }
    let api = APIClient.shared
    @objc func serverClicked(sender: NSMenuItem) {
        let server = sender.representedObject as! String
        saveDefaults(key: currentServerKey, value: server)
        if manager.connected {
            let result = api.switchServer(server: server)
            DDLogInfo("switch server result: \(result)")
        }
        updateServerList()
    }
    func updateServerList() {
        let tag = 10
        let menu = serversItem.submenu!
        menu.removeItems(withTag: tag)
        serversItem.title = "Servers"
        
        guard let current = getCurrentServer() else { return }
        serversItem.title = "Server: \(current)"

        guard let adapterFactoryManager = createAdapterFactoryManager() else {
            DDLogError("failed to load servers")
            return
        }
        let serverNames = adapterFactoryManager.selectFactory.servers
        let servers = serverNames.map{ (server) -> (String, TimeInterval) in
            return (server, 0)
        }
        let maxNameLength = servers.map { $0.0.utf16.count as Int }.max()!
        for (name, pingValue) in servers {
            let action = #selector(serverClicked(sender:))
            let state = current == name
            let item = createMenuItem(title: "", tag: tag, state: state, action: action)

            let nameRightPadded = name.padding(toLength: maxNameLength, withPad: " ", startingAt: 0)
            let title = "\(nameRightPadded) \t\(miliseconds(pingValue))"
            let attr = [NSAttributedStringKey.font: NSFont.userFixedPitchFont(ofSize: 14.0)!]
            item.attributedTitle = NSAttributedString(string: title, attributes: attr)
            item.representedObject = name
            menu.addItem(item)
        }
    }
    @IBOutlet weak var serversItem: NSMenuItem!
    private var proxyServerManager: ProxyServerManager {
        return proxyService.proxyManager
    }
    private func startProxy() {
        proxyService?.stop()
        proxyService = ProxyService(adapterFactoryManager: createAdapterFactoryManager()!)
        proxyService.start()
    }
    private var port: UInt16 {
        return proxyServerManager.port
    }
    private var proxyService: ProxyService! = nil

    func listenReachabilityChange() {
        func onReachabilityChange(_: Any) {
            DispatchQueue.main.async {
                self.updateConnectivityInfo()
            }
        }
        reachability.whenReachable = onReachabilityChange
        reachability.whenUnreachable = onReachabilityChange
        try? reachability.startNotifier()
    }
    let reachability = Reachability()!

    func updateConnectivityInfo() {
    }
    @IBOutlet weak var connectivityItem: NSMenuItem!

    func connectivityTest() {
        guard manager.connected else {
            connectivityItem.title = "VPN disabled"
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
        connectivityItem.title = "ping testing..."
        func showResult() {
            let status = "China \(miliseconds(direct)), World \(miliseconds(proxy))"
            DDLogInfo("ping test \(status)")
            if direct < 0 && proxy < 0 {
                connectivityItem.title = "ping test failed"
            } else {
                connectivityItem.title = status
            }
        }
    }

    // MARK: -

    @IBAction func showLogClicked(_ sender: Any) {
        if let logfile = api.getTunnelLogFile() {
            _ = runCommand(path: "/usr/bin/env", args: ["open", "-a", "Console", logfile])
        }
    }

    @IBAction func checkUpdatesClicked(_ sender: Any) {
        SUUpdater.shared().checkForUpdates(nil)
    }

    @IBAction func startAtLoginClicked(_ sender: Any) {
        let enabled = !launchHelper.enabled
        let result = launchHelper.setEnabled(enabled: enabled)
        if !result {
            DDLogError("failed to set auto launch \(enabled)")
        }
        updateStartAtLoginItem()
    }
    @IBOutlet weak var startAtLoginItem: NSMenuItem!
    func updateStartAtLoginItem() {
        startAtLoginItem.state = launchHelper.enabled ? .on : .off
    }
    let launchHelper = AutoLaunchHelper(identifier: "com.simpzan.Escalade.macOS.LaunchHelper")


    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/simpzan/Escalade")!)
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApp.terminate(nil)
    }
}
