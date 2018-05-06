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
        statusItem.image = NSImage(named: "MenuBarIcon")
        statusItem.menu = mainMenu

        mainMenu.delegate = self
        NSUserNotificationCenter.default.delegate = self

        serversItem.action = #selector(autoSelectClicked(_:))
        serversItem.target = self

        NSLog("log file \(logFile)")

        let _ = launchHelper.validate()
        updateStartAtLoginItem()

        systemProxyController = SystemProxyController(configDir: configManager.configuraionFolder)
        systemProxyController.startMonitor { enabled in
            self.updateSystemProxyItem(enabled: enabled)
        }
        listenReachabilityChange()
    }
    @IBOutlet weak var mainMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)


    func menuWillOpen(_ menu: NSMenu) {
        if serverController == nil { return }
        
        updateConfigList()
        updateServerList()
        updateConnectivityInfo()

        if !reachability.isReachable { return }

//        pingTest()
        trafficMonitor.startUpdate { rx, tx in
            self.networkTrafficItem.title = "⬇︎ \(readableSize(rx))/s, ⬆︎ \(readableSize(tx))/s"
        }
    }
    func menuDidClose(_ menu: NSMenu) {
        trafficMonitor.stopUpdate()
    }
    let trafficMonitor = TrafficMonitor.shared
    @IBOutlet weak var networkTrafficItem: NSMenuItem!


    // MARK: -
    func updateSystemProxyItem(enabled: Bool) {
        NSLog("update system proxy state to \(enabled)")
        statusItem.button?.appearsDisabled = !enabled
        systemProxyItem.state = enabled ? NSOnState : NSOffState
    }
    @IBOutlet weak var systemProxyItem: NSMenuItem!
    @IBAction func systemProxyClicked(_ sender: Any) {
        systemProxyController.enabled = !systemProxyController.enabled
    }
    var systemProxyController: SystemProxyController! = nil


    // MARK: - configurations
    func showSetupGuide() {
        return
        
        guard let file = selectFile() else { return }

        if !configManager.importConfig(file: file) {
            _ = alert("invalid config file: \(file)")
            return
        }
        startProxy()

        var message = "Enable system proxy?"
        let hint = "Setting system proxy requires administrator privileges." +
"If you want to enable system proxy, please input your user password in the following system dialog.\n" +
"This is required only for ONCE."
        if systemProxyController.needInstall() {
            message += "\n\(hint)"
        }
        systemProxyController.port = port
        if confirm(message) {
            systemProxyController.enabled = true
        }

        autoSelectClicked(nil)
    }
    func reloadConfigurations() -> Bool {
        if !configManager.reloadConfigurations() { return false }

        startProxy()
        return true
    }
    func configClicked(sender: NSMenuItem) {
        let name = sender.title
        if !configManager.setConfiguration(name: name) {
            print("setConfiguration \(name) failed")
        } else {
            startProxy()
        }
    }
    func updateConfigList() {
        let menu = configurationsItem.submenu!
        let tag = 11
        menu.removeItems(withTag: tag)

        let currentConfig = configManager.currentConfiguration
        configurationsItem.title = "Config: \(currentConfig ?? "")"

        for name in configManager.configurations {
            let action = #selector(configClicked(sender:))
            let state = currentConfig == name
            let item = createMenuItem(title: name, tag: tag, state: state, action: action)
            menu.addItem(item)
        }
    }
    @IBAction func openConfigFolderClicked(_ sender: Any) {
        NSWorkspace.shared().openFile(configManager.configuraionFolder)
    }
    @IBAction func reloadConfigClicked(_ sender: Any) {
        _ = reloadConfigurations()
    }
    @IBOutlet weak var configurationsItem: NSMenuItem!
    let configManager = ConfigurationManager()


    // MARK: - servers
    @IBOutlet weak var autoSelectItem: NSMenuItem!
    @objc @IBAction func autoSelectClicked(_ sender: Any?) {
        guard let controller = serverController else { return }
        if !autoSelectItem.isEnabled { return }
        autoSelectItem.isEnabled = false
        sendNotification(title: "Servers Testing Started", text: "It will finish in 4 seconds.")
        controller.autoSelect { err, server in
            if err == nil && server != nil { // found ok, first time.
                let id = controller.currentServer!
                let ping = controller.internationalPing
                let text = "auto selected \(id)(\(miliseconds(ping)))"
                let title = "Servers Testing Finished"
                sendNotification(title: title, text: text)
                self.updateConnectivityInfo()
            } else if err == nil && server == nil { // found ok, second time.
                self.autoSelectItem.isEnabled = true
                self.updateServerList()
            } else if err != nil && server == nil { // found error.
                let text = "Your network connection is not connected to the Internet."
                let title = "Can't connect to Baidu"
                sendNotification(title: title, text: text)
                self.autoSelectItem.isEnabled = true
                self.updateServerList()
                self.updateConnectivityInfo()
            }
        }
    }
    func serverClicked(sender: NSMenuItem) {
        let name = sender.representedObject as! String
        serverController.currentServer = name
        updateServerList()
    }
    func updateServerList() {
        let tag = 10
        let menu = serversItem.submenu!
        menu.removeItems(withTag: tag)
        serversItem.title = "Servers"
        guard let controller = serverController else { return }

        let current = controller.currentServer
        serversItem.title = "Server: \(current ?? "")"

        let maxNameLength = controller.servers.map { $0.0.utf16.count as Int }.max()!
        for (name, pingValue) in controller.servers {
            let action = #selector(serverClicked(sender:))
            let state = current == name
            let item = createMenuItem(title: "", tag: tag, state: state, action: action)

            let nameRightPadded = name.padding(toLength: maxNameLength, withPad: " ", startingAt: 0)
            let title = "\(nameRightPadded) \t\(miliseconds(pingValue))"
            let attr = [NSFontAttributeName: NSFont.userFixedPitchFont(ofSize: 14.0)!]
            item.attributedTitle = NSAttributedString(string: title, attributes: attr)
            item.representedObject = name
            menu.addItem(item)
        }
    }
    @IBOutlet weak var serversItem: NSMenuItem!
    var serverController: ServerController! {
        return proxyService?.serverController
    }
    private var proxyServerManager: ProxyServerManager {
        return proxyService.proxyManager
    }
    private func startProxy() {
        proxyService?.stop()
        proxyService = ProxyService(config: configManager.current!)
        proxyService.start()
        
        systemProxyController.port = port
        systemProxyController.load()
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
        if serverController == nil { return }
        let baiduPing = serverController.domesticPing
        let googlePing = serverController.internationalPing
        var title = ""
        if !reachability.isReachable {
            title = "No Network"
        } else if baiduPing == -1 {
            title = "No Internet"
        } else if baiduPing == 0 || googlePing == 0 {
            title = "Testing..."
        } else {
            title = "Baidu \(miliseconds(baiduPing)), Google \(miliseconds(googlePing))"
        }
        connectivityItem.title = title
    }
    @IBOutlet weak var connectivityItem: NSMenuItem!

    func pingTest() {
        if !autoSelectItem.isEnabled { return }
        print("pingTesting...")
        autoSelectItem.isEnabled = false
        let start = Date()
        serverController.pingTest { err in
            let cost = Date().timeIntervalSince(start)
            delay(0.5 - cost) { // update at least 0.5s later to let user see the transition easily.
                self.autoSelectItem.isEnabled = true
                self.updateConnectivityInfo()
                self.updateServerList()
                print("pingTest done")
            }
        }
    }

    // MARK: -

    @IBAction func showLogClicked(_ sender: Any) {
        if let logfile = logFile {
            _ = runCommand(path: "/usr/bin/env", args: ["open", "-a", "Console", logfile])
        }
    }


    @IBAction func copyExportCommandClicked(_ sender: Any) {
        let proxy = "http://127.0.0.1:\(port + 1)"
        let content = "export https_proxy=\(proxy); export http_proxy=\(proxy)"
        copyString(string: content)
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
        startAtLoginItem.state = launchHelper.enabled ? NSOnState : NSOffState
    }
    let launchHelper = AutoLaunchHelper(identifier: "com.simpzan.Escalade.macOS.LaunchHelper")


    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared().open(URL(string: "https://github.com/simpzan/Escalade")!)
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApp.terminate(nil)
    }

    let manager = VPNManager()
    func vpnInit() {
        manager.monitorStatus { (_) in
            let state = self.manager.status
            NSLog("status changed to \(state.rawValue)")
        }
    }
    
    @IBOutlet weak var testButton: NSMenuItem!
    @IBAction func test(_ sender: Any) {
        NSLog("connectClicked")
        if manager.connected {
            manager.stopVPN()
        } else {
            manager.startVPN()
        }
    }
    func injected() {
        print("I've been injected-: \(self)")
        updateServerList()
    }

}
