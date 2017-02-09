//
//  ConfigurationManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Cocoa
import NEKit

class ConfigurationManager: NSObject {
    public var configurations : [String] {
        return profiles.keys.sorted()
    }

    public var currentConfiguration: String? {
        get {
            // load from defaults
            // validate
            // use the first one as default
            return configurations.first
        }
        set(name) {
            // validate
            guard name != nil && isValidConfig(name: name!) else { return }
            // save to defaults
            // apply config
            applyConfiguration(name: name)
        }
    }

    public func reloadConfigurations() {
        print("\(#function)")
        profiles = loadAllConfigurations()
        applyConfiguration()
    }

    public lazy var configuraionFolder: String = {
        let fm = FileManager.default
        let appSupportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let path = appSupportDir.appendingPathComponent("Escalade", isDirectory: true).relativePath

        var isDir: ObjCBool = false
        let exist = fm.fileExists(atPath: path, isDirectory: &isDir)
        if exist && !isDir.boolValue {
            try! fm.removeItem(atPath: path)
            try! fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        if !exist {
            try! fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }()


    // MARK: - 
    private var profiles: [String:String] = [:]
    private func isValidConfig(name: String) -> Bool {
        return profiles[name] != nil
    }
    private func loadConfiguration(content: String) -> Configuration? {
        let configuration = Configuration()
        do {
            try configuration.load(fromConfigString: content)
        } catch let error {
            print("Error when parsing profile file: \(error)")
            return nil
        }
        return configuration
    }
    private func loadAllConfigurations() -> [String:String] {
        let fm = FileManager.default
        let yamlFiles = try! fm.contentsOfDirectory(atPath: configuraionFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }

        var configs: [String:String] = [:]
        for file in yamlFiles {
            let name = (file as NSString).deletingPathExtension
            let fullpath = (configuraionFolder as NSString).appendingPathComponent(file)
            let content = try? String(contentsOfFile: fullpath, encoding: String.Encoding.utf8)
            if content == nil { continue }

            if loadConfiguration(content: content!) == nil { continue }

            configs[name] = content
        }
        return configs
    }

    // MARK: -
    private func applyConfiguration(name: String? = nil) {
        let key = name ?? currentConfiguration
        guard key != nil, let content = profiles[key!] else {
            print("config \(name) not found")
            return
        }

        guard let config = loadConfiguration(content: content) else { return }
        RuleManager.currentManager = config.ruleManager
        serverController = ServerController(manager: config.adapterFactoryManager)

        let port = UInt16(config.proxyPort ?? 9090)
        proxyServerManager.startProxyServers(port: port, address: "127.0.0.1")
    }
    private let proxyServerManager = ProxyServerManager()
    public var serverController: ServerController?

    func injected() {
        print("I've been injected-: \(self)")
    }
}
