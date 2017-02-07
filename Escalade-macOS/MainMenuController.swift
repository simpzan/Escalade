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
