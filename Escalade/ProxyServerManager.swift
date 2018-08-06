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

    public init(thePort: UInt16 = 0) {
        if thePort > 0 { port = thePort }
        let addr = IPAddress(fromString: address)
        socks5Server = NATProxyServer(address: addr, port: NEKit.Port(port: port))
        let httpAddr = IPAddress(fromString: "127.0.0.1")
        httpServer = GCDHTTPProxyServer(address: httpAddr, port: NEKit.Port(port: port + 1))
        
        if defaults.bool(forKey: shareProxyEnabledKey) {
            publicHttpProxyServer = GCDHTTPProxyServer(address: nil, port: Port(port: port + 2))
        }
    }
    var publicHttpProxyServer: GCDHTTPProxyServer? = nil

    public var port: UInt16 = 19990

    public let address: String = interfaceIp

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
