//
//  ProxyServerManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Foundation
import NEKit

class ProxyServerManager: NSObject {

    public func initWithConfig(config: Configuration) {
        RuleManager.currentManager = config.ruleManager
        serverController = ServerController(selectFactory: config.adapterFactoryManager.selectFactory)
        if let port = config.proxyPort { self.port = UInt16(port) }
    }

    public var serverController: ServerController?
    public var port: UInt16 = 9990
    public var address: String = "127.0.0.1"

    private var socks5Server: GCDSOCKS5ProxyServer?
    public var httpServer: GCDHTTPProxyServer?

    public func stopProxyServers() {
        socks5Server?.stop()
        socks5Server = nil
        httpServer?.stop()
        httpServer = nil
    }

    public func startProxyServers() {
        stopProxyServers()

        let addr = IPAddress(fromString: address)
        let socks5Server = GCDSOCKS5ProxyServer(address: addr, port: NEKit.Port(port: port))
        let httpServer = GCDHTTPProxyServer(address: addr, port: NEKit.Port(port: port + 1))
        do {
            try socks5Server.start()
            self.socks5Server = socks5Server
            try httpServer.start()
            self.httpServer = httpServer
        } catch let error {
            print("Encounter an error when starting proxy server. \(error)")
            socks5Server.stop()
            httpServer.stop()
        }
    }
}
