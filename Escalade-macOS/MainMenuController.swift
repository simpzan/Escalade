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

        configManager.reloadConfigurations()

        systemProxyController.port = configManager.port!
        systemProxyController.load()
        updateSystemProxyItem()

        updateConfigList()
        updateServerList()
        updateConnectivityInfo()
        updateNetworkTrafficItem()
    }
    @IBOutlet weak var mainMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)

    func menuWillOpen(_ menu: NSMenu) {
        pingTest()
        trafficMonitor.startUpdate { self.updateNetworkTrafficItem(rate: $0) }
    }
    func menuDidClose(_ menu: NSMenu) {
        trafficMonitor.stopUpdate()
    }

    // MARK: -
    func updateNetworkTrafficItem(rate: (Int, Int) = (0, 0)) {
        let (rx, tx) = rate
        let title = "⬇︎ \(rx)/s, ⬆︎ \(tx)/s"
        print(title)
        networkTrafficItem.title = title
    }
    let trafficMonitor = TrafficMonitor.shared
    @IBOutlet weak var networkTrafficItem: NSMenuItem!


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
    func configClicked(sender: NSMenuItem) {
        let name = sender.title
        print("server \(name)")
        configManager.currentConfiguration = name
        updateConfigList()
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
        configManager.reloadConfigurations()
    }
    @IBOutlet weak var configurationsItem: NSMenuItem!
    let configManager = ConfigurationManager()


    // MARK: - servers
    @IBAction func autoSelectClicked(_ sender: Any) {
        guard let controller = configManager.serverController else { return }

        let item = sender as! NSMenuItem
        item.isEnabled = false
        sendNotification(title: "Servers Testing Started", text: "It will finish in 4 seconds.")
        controller.autoSelectServer { err in
            item.isEnabled = true
            var text, title: String
            if err != nil {
                text = "Your network connection is not connected to the Internet."
                title = "Can't connect to Baidu"
            } else {
                let id = controller.currentServer!
                let ping = controller.internationalPing
                text = "auto selected \(id)(\(ping))"
                title = "Servers Testing Finished"
            }
            sendNotification(title: title, text: text)
            self.updateServerList()
        }
    }
    func serverClicked(sender: NSMenuItem) {
        let name = sender.representedObject as! String
        print("server \(name)")
        guard let controller = configManager.serverController else { return }

        controller.currentServer = name
        updateServerList()
    }
    func updateServerList() {
        guard let controller = configManager.serverController else { return }

        let tag = 10
        let menu = serversItem.submenu!
        menu.removeItems(withTag: tag)

        let currentId = controller.currentServer
        for (name, pingValue) in controller.servers {
            let title = "\(name) \t\t\(pingValue)s"
            let action = #selector(serverClicked(sender:))
            let state = currentId == name
            let item = createMenuItem(title: title, tag: tag, state: state, action: action)
            item.representedObject = name
            menu.addItem(item)
        }
    }
    @IBOutlet weak var serversItem: NSMenuItem!

    func updateConnectivityInfo() {
        guard let controller = configManager.serverController else { return }

        let baiduPing = controller.domesticPing
        let googlePing = controller.internationalPing
        var title = ""
        if baiduPing == -1 {
            title = "No Network"
        } else if baiduPing == 0 || googlePing == 0 {
            title = "Testing..."
        } else {
            title = "Baidu \(baiduPing)s, Google \(googlePing)s"
        }
        connectivityItem.title = title
    }
    @IBOutlet weak var connectivityItem: NSMenuItem!

    func pingTest() {
        guard let controller = configManager.serverController else { return }
        // disable autoselect
        controller.pingTest { err in
            // enable autoselect
            self.updateConnectivityInfo()
            self.updateServerList()
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
    }

}
