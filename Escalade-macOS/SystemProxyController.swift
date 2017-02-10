//
//  SystemProxyController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/10/17.
//
//

import Cocoa

class SystemProxyController: NSObject {
    private let toolPath = "/Library/Application Support/Escalade/SystemProxyConfig"
    private let version = "0.1.0"

    private let defaults = UserDefaults.standard
    private let systemProxyEnabledKey = "systemProxyEnabled"

    public var port: UInt16 = 0

    public func load() {
        restoreSystemProxyState()
        NotificationCenter.default.addObserver(self, selector: #selector(clearSystemProxyState), name: NSNotification.Name.NSApplicationWillTerminate, object: nil)
    }
    private func restoreSystemProxyState() {
        if enabled {
            setProxy(enable: true)
        }
    }
    @objc
    private func clearSystemProxyState() {
        if enabled {
            setProxy(enable: false)
        }
    }

    public var enabled: Bool {
        get {
            return defaults.bool(forKey: systemProxyEnabledKey)
        }
        set(state) {
            defaults.set(state, forKey: systemProxyEnabledKey)
            setProxy(enable: state)
        }
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

    private func needInstall() -> Bool {
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
