//
//  ConfigurationManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Foundation
import NEKit
import CocoaLumberjackSwift

class ConfigurationManager: NSObject {
    public var configurations : [String] {
        return profiles.keys.sorted()
    }

    public func setConfiguration(name: String) -> Bool {
        if applyConfiguration(name: name) {
            defaults.set(name, forKey: currentConfigKey)
        }
        return true
    }
    public var currentConfiguration: String? {
        let config = defaults.string(forKey: currentConfigKey)
        if isValidConfig(name: config) { return config }
        return configurations.first
    }
    private let defaults = UserDefaults.standard
    private let currentConfigKey = "currentConfig"

    public func reloadConfigurations() -> Bool {
        print("\(#function)")
        profiles = loadAllConfigurations()
        return applyConfiguration()
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

    public func importConfig(file: String) -> Bool {
        guard loadConfigurationFile(file: file) != nil else { return false }

        let filename = (file as NSString).lastPathComponent
        let destPath = "\(configuraionFolder)/\(filename)"
        try? FileManager.default.copyItem(atPath: file, toPath: destPath)
        return reloadConfigurations()
    }

    // MARK: -
    private var profiles: [String:String] = [:]
    private func isValidConfig(name: String!) -> Bool {
        if name == nil { return false }
        return profiles[name] != nil
    }
    private func loadConfigurationFile(file: String) -> (String, Configuration)? {
        guard let size = filesize(file), size <= 1024 * 1024 else { return nil }
        guard let content = try? String(contentsOfFile: file) else { return nil }
        guard let result = loadConfiguration(content: content) else { return nil }
        return (content, result)
    }
    private func loadConfiguration(content: String) -> Configuration? {
        let configuration = Configuration()
        do {
            try configuration.load(fromConfigString: content)
        } catch let error {
            DDLogError("Error when parsing profile file: \(error)")
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
            guard let result = loadConfigurationFile(file: fullpath) else { continue }

            configs[name] = result.0
        }
        return configs
    }

    // MARK: -
    private func applyConfiguration(name: String? = nil) -> Bool {
        let key = name ?? currentConfiguration
        guard key != nil, let content = profiles[key!] else {
            DDLogError("config \(name) not found")
            return false
        }

        guard let config = loadConfiguration(content: content) else { return false }

        proxyServerManager.initWithConfig(config: config)
        return true
    }
    public let proxyServerManager = ProxyServerManager()

    func injected() {
        print("I've been injected-: \(self)")
    }
}
