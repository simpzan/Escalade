//
//  MainMenuController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa

class MainMenuController: NSObject, NSMenuDelegate {

    @IBOutlet weak var mainMenu: NSMenu!

    let statusItem = NSStatusBar.system().statusItem(withLength: -1)
    @IBOutlet weak var networkTrafficItem: NSMenuItem!
    @IBOutlet weak var connectivityItem: NSMenuItem!
    @IBOutlet weak var serversItem: NSMenuItem!
    @IBOutlet weak var configurationsItem: NSMenuItem!

    @IBAction func autoSelectClicked(_ sender: Any) {
    }
    @IBAction func openConfigFolderClicked(_ sender: Any) {
    }
    @IBAction func reloadConfigClicked(_ sender: Any) {
        configManager.reloadConfigurations()
    }
    @IBAction func systemProxyClicked(_ sender: Any) {
    }
    @IBAction func showLogClicked(_ sender: Any) {
    }
    @IBAction func copyExportCommandClicked(_ sender: Any) {
    }
    @IBAction func checkUpdatesClicked(_ sender: Any) {
    }
    @IBAction func startAtLoginClicked(_ sender: Any) {
    }
    @IBAction func helpClicked(_ sender: Any) {
    }
    @IBAction func quitClicked(_ sender: Any) {
        NSApp.terminate(nil)
    }

    let configManager = ConfigurationManager()

    func configClicked(sender: NSMenuItem) {
        let name = sender.title
        print("server \(name)")
        configManager.currentConfiguration = name
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

    func serverClicked(sender: NSMenuItem) {
        let name = sender.toolTip!
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
        for name in controller.servers {
            let action = #selector(serverClicked(sender:))
            let state = currentId == name
            let item = createMenuItem(title: name, tag: tag, state: state, action: action)
            menu.addItem(item)
        }
    }

    override func awakeFromNib() {
        statusItem.title = "Escalade"
        statusItem.menu = mainMenu

        mainMenu.delegate = self

        configManager.reloadConfigurations()
        updateConfigList()
        updateServerList()
    }

    func menuWillOpen(_ menu: NSMenu) {
        print("open")
    }
    func menuDidClose(_ menu: NSMenu) {
        print("close")
    }
    
    class func injected() {
        print("I've been injected+: \(self)")
    }
    func injected() {
        print("I've been injected-: \(self)")
    }

}
