//
//  ServersPersistence.swift
//  Escalade
//
//  Created by simpzan on 24/06/2018.
//

import Foundation
import CocoaLumberjackSwift
import NEKit

public func importServers(url: URL) -> Bool {
    DDLogInfo("imported url \(url)")
    guard let data = try? Data(contentsOf: url) else {
        DDLogError("failed to load file at \(url)")
        return false
    }
    guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else {
        DDLogError("malformed json file at \(url)")
        return false
    }
    guard let dict = obj as? [String:AnyObject], let servers = dict["configs"] as? [[String: String]] else {
        DDLogError("unrecognized json file")
        return false
    }
    
    defaults.set(servers, forKey: serversKey)
    DDLogInfo("imported \(servers)")
    return true
}

private func createShadowsocksFactory(server: [String: String]) -> ShadowsocksAdapterFactory? {
    guard let host = server["server"], let p = server["server_port"], let port = Int(p) else {
        DDLogError("invalid host or port, \(server)")
        return nil
    }
    guard let method = server["method"], let algorithm = CryptoAlgorithm(rawValue: method.uppercased()) else {
        DDLogError("invalid encryption method, \(server)")
        return nil
    }
    guard let password = server["password"] else {
        DDLogError("invalid password, \(server)")
        return nil
    }
    let cryptoFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm)
    let protocolObfuscaterFactory = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
    let streamObfuscaterFactory = ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory()
    return ShadowsocksAdapterFactory(serverHost: host, serverPort: port,
            protocolObfuscaterFactory: protocolObfuscaterFactory,
            cryptorFactory: cryptoFactory,
            streamObfuscaterFactory: streamObfuscaterFactory)
}
public func createAdapterFactoryManager() -> AdapterFactoryManager? {
    guard let servers = defaults.array(forKey: serversKey) as? [[String: String]], servers.count > 0 else {
        DDLogError("no saved servers.")
        return nil
    }
    var factoryDict: [String: AdapterFactory] = [:]
    for server in servers {
        if let id = server["remarks"], let factory = createShadowsocksFactory(server: server)  {
            factoryDict[id] = factory
        } else {
            DDLogError("failed to load server \(server)")
        }
    }
    return AdapterFactoryManager(factoryDict: factoryDict)
}
