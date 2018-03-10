//
//  AppDelegate.swift
//  Escalade-macOS
//
//  Created by Samuel Zhang on 2/7/17.
//
//

import Cocoa

public let appId = "simpzan.Escalade-macOS"
public let groupId = "group." + appId
public let providerBundleIdentifier = appId + ".PacketTunnel-macOS"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var mainMenuController: MainMenuController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let id = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: id)
        if runningApps.count > 1 {
            _ = alert("Another app with same bundle id is already running! Please quit that app first.")
            NSApp.terminate(nil)
        } else {
            if !mainMenuController.reloadConfigurations() {
                mainMenuController.showSetupGuide()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

