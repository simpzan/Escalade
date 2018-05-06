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

    public var port: UInt16 {
        set(p) {
            if thePort != p {
                thePort = p
                callback?(enabled)
            }
        }
        get {
            return thePort
        }
    }
    private var thePort: UInt16 = 0

    public func load() {
        restoreSystemProxyState()
        NotificationCenter.default.addObserver(self, selector: #selector(clearSystemProxyState), name: NSApplication.willTerminateNotification, object: nil)
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

    typealias SystemProxyChangeCallback = (Bool) -> Void
    public func startMonitor(callback: @escaping SystemProxyChangeCallback) {
        if !SCDynamicStoreSetNotificationKeys(store, ["State:/Network/Global/Proxies"] as CFArray, nil) {
            return DDLogError("SCDynamicStoreSetNotificationKeys failed")
        }
        if !SCDynamicStoreSetDispatchQueue(store, DispatchQueue.main) {
            return DDLogError("SCDynamicStoreSetDispatchQueue failed")
        }
        self.callback = callback
        callback(self.enabled)
    }
    public func stopMonitor() {
        if !SCDynamicStoreSetNotificationKeys(store, nil, nil) {
            return DDLogError("SCDynamicStoreSetNotificationKeys nil failed")
        }
        if !SCDynamicStoreSetDispatchQueue(store, nil) {
            return DDLogError("SCDynamicStoreSetDispatchQueue nil failed")
        }
        callback = nil
    }
    private var callback: (SystemProxyChangeCallback)?
    private lazy var store: SCDynamicStore = {
        let changed: SCDynamicStoreCallBack = { dynamicStore, keys, context in
            guard let info = context else { return }
            let controller = Unmanaged<SystemProxyController>.fromOpaque(info).takeUnretainedValue()
            controller.callback?(controller.enabled)
        }
        var context = SCDynamicStoreContext()
        context.info = UnsafeMutableRawPointer(Unmanaged<SystemProxyController>.passUnretained(self).toOpaque())
        let dcAddress = withUnsafeMutablePointer(to: &context, {UnsafeMutablePointer<SCDynamicStoreContext>($0)})
        return SCDynamicStoreCreate(nil, "Escalade" as CFString, changed, dcAddress)!
    }()

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
            return print("failed to install command")
        }
        if port < 3 {
            return print("invalid port number: \(port)")
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
