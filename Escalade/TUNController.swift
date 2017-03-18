//
//  TUNController.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
//
//

import Foundation
import CocoaLumberjackSwift
import NetworkExtension
import NEKit

class TUNController {

    private lazy var dnsServer: DNSServer = {
        let ipRange = try! IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!)
        let fakeIPPool = IPPool(range: ipRange)
        let dnsServer = DNSServer(address: IPAddress(fromString: self.dns)!, port: Port(port: 53), fakeIPPool: fakeIPPool)
        DNSServer.currentServer = dnsServer
        return dnsServer
    }();
    private func setupPacketProcessor() {
        let resolver = UDPDNSResolver(address: IPAddress(fromString: dns)!, port: Port(port: 53))
        dnsServer.registerResolver(resolver)
        interface.register(stack: dnsServer)

        let udpStack = UDPDirectStack()
        interface.register(stack: udpStack)

        let tcpStack = TCPStack.stack
        tcpStack.proxyServer = httpProxyServer
        interface.register(stack: tcpStack)
    }

    public func start() {
        setupPacketProcessor()
        interface?.start()
    }

    public func stop() {
        interface?.stop()
    }

    let dns = "114.114.114.114"

    private var interface: TUNInterface!
    private let httpProxyServer: GCDHTTPProxyServer

    public init(provider: NEPacketTunnelProvider, httpServer: GCDHTTPProxyServer) {
        RawSocketFactory.TunnelProvider = provider
        interface = TUNInterface(packetFlow: provider.packetFlow)
        httpProxyServer = httpServer

        ObserverFactory.currentFactory = DebugObserverFactory()
        Opt.MAXNWTCPSocketReadDataSize = 60 * 1024
    }

    public func getTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.mtu = 1500
        settings.dnsSettings = NEDNSSettings(servers: [dns])
        let v4Settings = NEIPv4Settings(addresses:["192.0.2.1"], subnetMasks:["255.255.255.0"])
        v4Settings.includedRoutes = [NEIPv4Route.default()]
//        v4Settings.excludedRoutes = [NEIPv4Route(destinationAddress:"114.114.114.114", subnetMask:"255.255.255.255")]
        settings.iPv4Settings = v4Settings
//        settings.proxySettings = getProxySettings()
        return settings
    }
    private func getProxySettings() -> NEProxySettings {
        let proxy = NEProxySettings()
        proxy.httpEnabled = true
        proxy.httpServer = NEProxyServer(address: (httpProxyServer.address?.presentation)!, port: Int(httpProxyServer.port.value))
        proxy.httpsEnabled = true
        proxy.httpsServer = proxy.httpServer
//        proxy.autoProxyConfigurationEnabled = true
//        proxy.proxyAutoConfigurationURL
        proxy.excludeSimpleHostnames = true
        proxy.matchDomains = []
        return proxy
    }

}


