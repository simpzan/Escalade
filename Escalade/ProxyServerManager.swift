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

    public init(config: Configuration) {
        RuleManager.currentManager = config.ruleManager
        if let port = config.proxyPort { self.port = UInt16(port) }

        let addr = IPAddress(fromString: address)
        socks5Server = GCDSOCKS5ProxyServer(address: addr, port: NEKit.Port(port: port))
        httpServer = GCDHTTPProxyServer(address: addr, port: NEKit.Port(port: port + 1))
    }

    public var port: UInt16 = 9990
    public let address: String = "127.0.0.1"

    private let socks5Server: GCDSOCKS5ProxyServer?
    public let httpServer: GCDHTTPProxyServer?

    public func stopProxyServers() {
        socks5Server?.stop()
        httpServer?.stop()
    }

    public func startProxyServers() {
        do {
            try socks5Server?.start()
            try httpServer?.start()
            DDLogInfo("proxy servers started at \(port)");
        } catch let error {
            DDLogError("Encounter an error when starting proxy server. \(error)")
        }
    }
}
