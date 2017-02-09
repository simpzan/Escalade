//
//  ProxyServerManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Cocoa
import NEKit

class ProxyServerManager: NSObject {

    private var socks5Server: GCDSOCKS5ProxyServer?
    private var httpServer: GCDHTTPProxyServer?

    private func stopProxyServers() {
        socks5Server?.stop()
        socks5Server = nil
        httpServer?.stop()
        httpServer = nil
    }

    func startProxyServers(port: UInt16, address: String) {
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
