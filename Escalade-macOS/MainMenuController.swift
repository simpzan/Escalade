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
    }

    override func awakeFromNib() {
        statusItem.title = "Escalade"
        statusItem.menu = mainMenu

        mainMenu.delegate = self
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
