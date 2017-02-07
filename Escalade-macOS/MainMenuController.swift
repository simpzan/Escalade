//
//  MainMenuController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa

class MainMenuController: NSObject {

    @IBOutlet weak var mainMenu: NSMenu!

    let statusItem = NSStatusBar.system().statusItem(withLength: -1)

    override func awakeFromNib() {
        statusItem.title = "Escalade"
        statusItem.menu = mainMenu
    }
}
