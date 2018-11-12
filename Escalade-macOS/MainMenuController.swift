//
//  MainMenuController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa
import CocoaLumberjackSwift

class MainMenuController: NSObject, NSMenuDelegate, NSUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    override func awakeFromNib() {
        statusItem.toolTip = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        statusItem.image = NSImage(named: NSImage.Name(rawValue: "MenuBarIcon"))
        statusItem.menu = mainMenu

        mainMenu.delegate = self
        NSUserNotificationCenter.default.delegate = self

        serversItem.action = #selector(autoSelectClicked(_:))
        serversItem.target = self

        setupLog(.info, nil)

        loadServerList()
        
        let _ = launchHelper.validate()
        updateStartAtLoginItem()

        connectionChanged()
        service.listenProxyStateChange { (state) in
            self.connectionChanged()
        }
        listenReachabilityChange()

        systemProxyController.port = listeningPort
        systemProxyController.startMonitor { (state) in
            self.connectionChanged()
        }

        service.startProxy { (err) in
            if let error = err { DDLogError("startProxy error, \(error)") }
        }

        updateServerList()
        updateDebugModeItem()
        updateShareProxyItem()
    }
    @IBOutlet weak var mainMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)


    func menuWillOpen(_ menu: NSMenu) {
        updateServerList()
        updateConnectivityInfo()

        if !reachability.isReachable { return }

        connectivityTest()
        service.startUpdate { rx, tx in
            self.networkTrafficItem.title = "⬇︎ \(readableSize(rx))/s, ⬆︎ \(readableSize(tx))/s"
        }
    }
    func menuDidClose(_ menu: NSMenu) {
        service.stopUpdate()
    }
    @IBOutlet weak var networkTrafficItem: NSMenuItem!


    // MARK: -
    func connectionChanged() {
        let enabled = systemProxyController.enabled
        NSLog("update system proxy state to \(enabled)")
        statusItem.button?.appearsDisabled = !enabled
        systemProxyItem.state = enabled ? .on : .off
    }
    @IBOutlet weak var systemProxyItem: NSMenuItem!
    @IBAction func systemProxyClicked(_ sender: Any) {
        systemProxyController.enabled = !systemProxyController.enabled
    }
    private let systemProxyController = SystemProxyController()

    private lazy var service: EscaladeService = {
        return createEscaladeService()
    }()
    
    // MARK: - configurations
    @IBAction func importConfigClicked(_ sender: Any) {
        importConfigFile()
    }
    func showSetupGuideIfNeeded() {
        if getCurrentServer() != nil { return }
        importConfigFile()
    }
    func importConfigFile() {
        guard let file = selectFile() else { return }
        let url = URL(fileURLWithPath: file)
        guard importServers(url: url) else {
            return DDLogError("failed to import servers in \(url)")
        }

        NotificationCenter.default.post(name: serversUpdatedNotification, object: nil)
        loadServerList()
        sendNotification(title: "import done", text: "")
        service.stopProxy { (err) in
            if let error = err { DDLogError("stopProxy error, \(error)") }
        }
    }

    // MARK: - servers
    private var servers = [(String, String)]()
    @IBOutlet weak var autoSelectItem: NSMenuItem!
    @objc @IBAction func autoSelectClicked(_ sender: Any?) {
        guard service.isProxyRunning else { return }
        guard autoSelectItem.isEnabled else { return }
        autoSelectItem.isEnabled = false
        sendNotification(title: "Servers Testing Started", text: "It will finish in 4 seconds.")
        service.autoSelect { (result) in
            self.servers = result
            let selected = result.first!
            let text = "auto selected \(selected.0)(\(selected.1))"
            let title = "Servers Testing Finished"
            sendNotification(title: title, text: text)
            self.autoSelectItem.isEnabled = true
        }
    }

    @objc func serverClicked(sender: NSMenuItem) {
        let server = sender.representedObject as! String
        saveDefaults(key: currentServerKey, value: server)
        if service.isProxyRunning {
            let result = service.setCurrentServer(server: server)
            DDLogInfo("switch server result: \(result)")
        }
        updateServerList()
    }
    private func loadServerList() {
        if let adapterFactoryManager = createAdapterFactoryManager() {
            let serverNames = adapterFactoryManager.selectFactory.servers
            servers = serverNames.map{ (server) -> (String, String) in (server, "") }
        }
    }
    func updateServerList() {
        let tag = 10
        let menu = serversItem.submenu!
        menu.removeItems(withTag: tag)
        serversItem.title = "Servers"
        
        guard let current = getCurrentServer(), servers.count > 0 else { return }
        serversItem.title = "Server: \(current)"

        let maxNameLength = servers.map { $0.0.utf16.count as Int }.max()!
        for (name, pingValue) in servers {
            let action = #selector(serverClicked(sender:))
            let state = current == name
            let item = createMenuItem(title: "", tag: tag, state: state, action: action)

            let nameRightPadded = name.padding(toLength: maxNameLength, withPad: " ", startingAt: 0)
            let title = "\(nameRightPadded) \t\(pingValue)"
            let attr = [NSAttributedStringKey.font: NSFont.userFixedPitchFont(ofSize: 14.0)!]
            item.attributedTitle = NSAttributedString(string: title, attributes: attr)
            item.representedObject = name
            menu.addItem(item)
        }
    }
    @IBOutlet weak var serversItem: NSMenuItem!

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
        guard service.isProxyRunning else {
            connectivityItem.title = "VPN disabled"
            return
        }
        
        var direct: Double = 0
        var proxy: Double = 0
        service.pingDirect { (result) in
            direct = result ?? -1
            showResult()
        }
        service.pingProxy { (result) in
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
        if let logfile = getLogFilePath() {
            _ = runCommand(path: "/usr/bin/env", args: ["open", "-a", "Console", logfile])
        }
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

    @IBAction func debugModeClicked(_ sender: Any) {
//        api.toggleVerboseLogging()
        updateDebugModeItem()
    }
    private func updateDebugModeItem() {
//        debugModeItem.state = api.isVerboseLoggingEnabled() ? .on : .off
    }
    @IBOutlet weak var debugModeItem: NSMenuItem!
    
    private func updateShareProxyItem() {
        shareProxyItem.state = service.getSharedProxy() != nil ? .on : .off
    }
    @IBAction func shareProxyClicked(_ sender: Any) {
        let newState = shareProxyItem.state == .off
        service.setSharedProxy(state: newState)
        updateShareProxyItem()
    }
    @IBOutlet weak var shareProxyItem: NSMenuItem!
    
    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/simpzan/Escalade")!)
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApp.terminate(nil)
    }
}
