//
//  ProxyServerManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Foundation
import NEKit
import CocoaLumberjackSwift

class ProxyServerManager: NSObject {
    let delayFunc: ProxyServer.DelayFunc = {
        let highWaterMark = 14 * 1024 * 1024
        let memory = memoryUsage()
        let ratio = Double(memory) / Double(highWaterMark)
        if ratio < 0.8 { return 0 }
        if ratio < 0.9 {
            DDLogInfo("memory \(memory), \(ratio).")
            return 0.2
        }
        DDLogWarn("memory \(memory), \(ratio).")
        return 0.5
    }
    
    public init(host: String, thePort: UInt16) {
        address = host
        port = thePort
        let addr = IPAddress(fromString: address)
        socks5Server = NATProxyServer(address: addr, port: NEKit.Port(port: port))
        socks5Server?.delayFunc = delayFunc
        let httpAddr = IPAddress(fromString: "127.0.0.1")
        httpServer = GCDHTTPProxyServer(address: httpAddr, port: NEKit.Port(port: port + 1))
        httpServer?.delayFunc = delayFunc
        
        if defaults.bool(forKey: shareProxyEnabledKey) {
            publicHttpProxyServer = GCDHTTPProxyServer(address: nil, port: Port(port: port + 2))
            publicHttpProxyServer?.delayFunc = delayFunc
        }
    }
    var publicHttpProxyServer: GCDHTTPProxyServer? = nil

    public var port: UInt16
    public let address: String

    public let socks5Server: GCDProxyServer?
    public let httpServer: GCDHTTPProxyServer?

    public func stopProxyServers() {
        socks5Server?.stop()
        httpServer?.stop()
        publicHttpProxyServer?.stop()
    }
    
    public func dump() -> [ConnectionRecord] {
        guard let sock5 = socks5Server, let http = httpServer else { return [] }
        let sock5Connections = sock5.dump()
        let httpConnections = http.dump()
        let internalConnections = sock5Connections + httpConnections
        if let externalHttpConnections = publicHttpProxyServer?.dump() {
            return internalConnections + externalHttpConnections
        }
        return internalConnections
    }
    public func resetInactives() {
        DDLogInfo("reset inactive tunnels.")
        socks5Server?.resetInactives()
        httpServer?.resetInactives()
        publicHttpProxyServer?.resetInactives()
    }

    public func startProxyServers() {
        do {
            try socks5Server?.start()
            try httpServer?.start()
            try publicHttpProxyServer?.start()
            DDLogInfo("proxy servers started at \(port)");
        } catch let error {
            DDLogError("Encounter an error when starting proxy server. \(error)")
        }
    }
    
    public func setShareProxyState(_ state: Bool) {
        let oldState = publicHttpProxyServer != nil
        if !oldState && state {
            publicHttpProxyServer = GCDHTTPProxyServer(address: nil, port: Port(port: port + 2))
            try? publicHttpProxyServer?.start()
        } else if oldState && !state {
            publicHttpProxyServer?.stop()
            publicHttpProxyServer = nil
        }
        DDLogInfo("share proxy state changed, \(oldState) -> \(state).")
        defaults.set(state, forKey: shareProxyEnabledKey)
    }
    public func getSharedProxyState() -> String? {
        if publicHttpProxyServer == nil { return nil }
        return "127.0.0.1:\(port + 2)"
    }
}

private let shareProxyEnabledKey = "shareProxyEnabled"
