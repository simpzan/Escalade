//
//  SystemProxyController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/10/17.
//
//

import Cocoa
import SystemConfiguration
import CocoaLumberjackSwift

class SystemProxyController {
    public init(configDir: String) {
        toolPath = "\(configDir)/SystemProxyConfig"
    }

    private let toolPath: String
    private let version = "0.1.0"

    private var persistedEnableState: Bool {
        get {
            return defaults.bool(forKey: systemProxyEnabledKey)
        }
        set(value) {
            defaults.set(value, forKey: systemProxyEnabledKey)
        }
    }
    private let defaults = UserDefaults.standard
    private let systemProxyEnabledKey = "systemProxyEnabled"

    public var port: UInt16 = 0

    public func load() {
        restoreSystemProxyState()
        NotificationCenter.default.addObserver(self, selector: #selector(clearSystemProxyState), name: NSNotification.Name.NSApplicationWillTerminate, object: nil)
    }
    private func restoreSystemProxyState() {
        if persistedEnableState {
            setProxy(enable: true)
        }
    }
    @objc
    private func clearSystemProxyState() {
        if enabled {
            setProxy(enable: false)
        }
    }

    typealias SystemProxyChangeCallback = () -> Void
    public func startMonitor(callback: @escaping SystemProxyChangeCallback) {
        func changed(pref: SCPreferences, notification: SCPreferencesNotification, info: UnsafeMutableRawPointer?) {
            guard notification.contains(.apply) && info != nil else { return }
            let controller = Unmanaged<SystemProxyController>.fromOpaque(info!).takeUnretainedValue()
            guard let callback = controller.callback else { return }
            DispatchQueue.main.async {
                callback()
            }
        }

        var context = SCPreferencesContext()
        context.info = UnsafeMutableRawPointer(Unmanaged<SystemProxyController>.passUnretained(self).toOpaque())
        if !SCPreferencesSetCallback(prefs, changed, &context) {
            DDLogError("SCPreferencesSetCallback failed")
            return
        }
        if !SCPreferencesSetDispatchQueue(prefs, queue) {
            DDLogError("SCPreferencesSetDispatchQueue failed")
            return
        }
        self.callback = callback
        monitoring = true
        callback()
    }
    public func stopMonitor() {
        SCPreferencesSetCallback(prefs, nil, nil)
        SCPreferencesSetDispatchQueue(prefs, nil)
        callback = nil
        monitoring = false
    }
    private let prefs = SCPreferencesCreate(nil, "Escalade" as CFString, nil)!
    private var monitoring = false
    private var callback: (SystemProxyChangeCallback)?
    private let queue = DispatchQueue(label: "com.simpzan.Escalade.SystemProxyController")

    public var enabled: Bool {
        get {
            return isEnabled()
        }
        set(state) {
            persistedEnableState = state
            setProxy(enable: state)
        }
    }
    private func isEnabled() -> Bool {
        guard let proxies = SCDynamicStoreCopyProxies(nil) as? [String: AnyObject] else {
            return false
        }
        func enabled(_ enableKey: CFString, _ hostKey: CFString, _ portKey: CFString, _ portNumber: UInt16) -> Bool {
            let enable = proxies[enableKey as String] as? NSNumber
            let host = proxies[hostKey as String] as? String
            let port = proxies[portKey as String] as? NSNumber
            return enable?.intValue == 1 && host == "127.0.0.1" && port?.uint16Value == portNumber
        }
        let p = port + 1
        let http = enabled(kCFNetworkProxiesHTTPEnable, kCFNetworkProxiesHTTPProxy, kCFNetworkProxiesHTTPPort, p)
        let https = enabled(kCFNetworkProxiesHTTPSEnable, kCFNetworkProxiesHTTPSProxy, kCFNetworkProxiesHTTPSPort, p)
        let socks = enabled(kCFNetworkProxiesSOCKSEnable, kCFNetworkProxiesSOCKSProxy, kCFNetworkProxiesSOCKSPort, port)
        return http && https && socks
    }
    private func setProxy(enable: Bool) {
        if needInstall() && !installCommand() {
            print("failed to install command")
            return
        }
        if port < 3 {
            print("invalid port number: \(port)")
            return
        }

        let state = enable ? "enable" : "disable"
        let args = [String(port), state]
        let out = runCommand(path: toolPath, args: args)
        print(out)
    }

    public func needInstall() -> Bool {
        guard FileManager.default.fileExists(atPath: toolPath) else { return true }

        let out = runCommand(path: toolPath, args: ["version"])
        return !out.output.contains(version)
    }
    private func installCommand() -> Bool {
        let installerPath = "\(Bundle.main.resourcePath!)/SystemProxyConfigInstaller.sh"
        let source = "do shell script \"bash \(installerPath)\" with administrator privileges"
        let appleScript = NSAppleScript(source: source)
        return appleScript?.executeAndReturnError(nil) != nil
    }
}
