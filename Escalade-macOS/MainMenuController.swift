//
//  MainMenuController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa

class MainMenuController: NSObject, NSMenuDelegate {

    override func awakeFromNib() {
        statusItem.title = "Escalade"
        statusItem.menu = mainMenu

        mainMenu.delegate = self

        updateSystemProxyItem()
        reloadConfigurations()
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

        pingTest()
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
    func updateSystemProxyItem() {
        systemProxyItem.state = systemProxyController.enabled ? NSOnState : NSOffState
    }
    @IBOutlet weak var systemProxyItem: NSMenuItem!
    @IBAction func systemProxyClicked(_ sender: Any) {
        systemProxyController.enabled = !systemProxyController.enabled
        updateSystemProxyItem()
    }
    let systemProxyController = SystemProxyController()


    // MARK: - configurations
    func reloadConfigurations() {
        serverController = configManager.reloadConfigurations()
        if serverController == nil { return }

        systemProxyController.port = configManager.port!
        systemProxyController.load()
    }
    func configClicked(sender: NSMenuItem) {
        let name = sender.title
        let controller = configManager.setConfiguration(name: name)
        if controller == nil {
            print("setConfiguration \(name) failed")
        } else {
            serverController = controller
        }
    }
    func updateConfigList() {
        let menu = configurationsItem.submenu!
        let tag = 11
        menu.removeItems(withTag: tag)

        let currentConfig = configManager.currentConfiguration
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
        reloadConfigurations()
    }
    @IBOutlet weak var configurationsItem: NSMenuItem!
    let configManager = ConfigurationManager()


    // MARK: - servers
    var autoSelecting = false
    @IBAction func autoSelectClicked(_ sender: Any) {
        guard let controller = serverController else { return }
        let item = sender as! NSMenuItem
        item.isEnabled = false
        autoSelecting = true
        sendNotification(title: "Servers Testing Started", text: "It will finish in 4 seconds.")
        controller.autoSelectServer { err in
            item.isEnabled = true
            self.autoSelecting = false
            var text, title: String
            if err != nil {
                text = "Your network connection is not connected to the Internet."
                title = "Can't connect to Baidu"
            } else {
                let id = controller.currentServer!
                let ping = controller.internationalPing
                text = "auto selected \(id)(\(miliseconds(ping)))"
                title = "Servers Testing Finished"
            }
            sendNotification(title: title, text: text)
            self.updateServerList()
            self.updateConnectivityInfo()
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
        guard let controller = serverController else { return }

        let currentId = controller.currentServer
        for (name, pingValue) in controller.servers {
            let title = "\(name) \t\t\t \(miliseconds(pingValue))"
            let action = #selector(serverClicked(sender:))
            let state = currentId == name
            let item = createMenuItem(title: title, tag: tag, state: state, action: action)
            item.representedObject = name
            menu.addItem(item)
        }
    }
    @IBOutlet weak var serversItem: NSMenuItem!
    var serverController: ServerController!


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
        if autoSelecting { return }
        print("pingTesting...")
        // disable autoselect
        serverController.pingTest { err in
            // enable autoselect
            self.updateConnectivityInfo()
            self.updateServerList()
            print("pingTest done")
        }
    }

    // MARK: -

    @IBAction func showLogClicked(_ sender: Any) {
    }
    @IBAction func copyExportCommandClicked(_ sender: Any) {
        var proxy = ""
        if let port = configManager.port {
            proxy = "http://127.0.0.1:\(port + 1)"
        }
        let content = "export https_proxy=\(proxy); export http_proxy=\(proxy)"
        copyString(string: content)
    }
    @IBAction func checkUpdatesClicked(_ sender: Any) {
    }
    @IBAction func startAtLoginClicked(_ sender: Any) {
    }
    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared().open(URL(string: "https://github.com/simpzan/Escalade")!)
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApp.terminate(nil)
    }

    class func injected() {
        print("I've been injected+: \(self)")
    }
    func injected() {
        print("I've been injected-: \(self)")
        updateServerList()
    }

}
