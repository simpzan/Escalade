//
//  AppDelegate.swift
//  Escalade-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import UIKit
import CocoaLumberjackSwift
import SVProgressHUD
import Fabric
import Crashlytics

public let appId = "com.simpzan.Escalade.iOS"
public let groupId = "group." + appId
public let providerBundleIdentifier = appId + ".PacketTunnel"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        let path = getContainerDir(groupId: groupId, subdir: "/Logs/Escalade/")
        setupLog(.debug, path)
        SVProgressHUD.setMinimumDismissTimeInterval(0.5)
        SVProgressHUD.setDefaultMaskType(.clear)

        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func getConfigListViewController() -> ViewController? {
        guard let navVC = window?.rootViewController as? UINavigationController else { return nil }
        return navVC.viewControllers.first as? ViewController
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        DDLogInfo("imported url \(url)")
        guard let yaml = try? String(contentsOf: url, encoding:.utf8) else {
            SVProgressHUD.showError(withStatus: "invalid UTF8 text file");
            DDLogError("failed to load the url using utf8, \(url)")
            return false
        }
        guard let vc = getConfigListViewController(), vc.loadConfig(yaml: yaml) else {
            SVProgressHUD.showError(withStatus: "invalid yaml file")
            DDLogError("failed to load the yaml file: \(yaml)")
            return false
        }
        saveDefaults(key: configKey, value: yaml)
        SVProgressHUD.showSuccess(withStatus: "config file imported")
        return true
    }
}

