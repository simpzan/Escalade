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

public let interfaceIp = "192.0.2.1"

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

        let nat = PacketTranslator(interfaceIp: interfaceIp, fakeSourceIp: "192.0.2.3", proxyServerIp: httpProxyServer.address?.presentation, port: httpProxyServer.port.value)
        PacketTranslator.setInstance(nat)
        interface.register(stack: nat!)
//        let tcpStack = TCPStack.stack
//        tcpStack.proxyServer = httpProxyServer
//        interface.register(stack: tcpStack)
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
    private let httpProxyServer: GCDProxyServer

    public init(provider: NEPacketTunnelProvider, httpServer: GCDProxyServer) {
        RawSocketFactory.TunnelProvider = provider
        interface = TUNInterface(packetFlow: provider.packetFlow)
        httpProxyServer = httpServer

        Opt.MAXNWTCPSocketReadDataSize = 60 * 1024
    }

    public func getTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.mtu = 1500
        settings.dnsSettings = NEDNSSettings(servers: [dns])
        let v4Settings = NEIPv4Settings(addresses:[interfaceIp], subnetMasks:["255.255.255.0"])
        v4Settings.includedRoutes = [NEIPv4Route.default()]
//        v4Settings.excludedRoutes = [NEIPv4Route(destinationAddress:"114.114.114.114", subnetMask:"255.255.255.255")]
        settings.ipv4Settings = v4Settings
        settings.proxySettings = getProxySettings()
        return settings
    }
    private func getProxySettings() -> NEProxySettings {
        let proxy = NEProxySettings()
        proxy.httpEnabled = true
        let httpPort = Int(httpProxyServer.port.value) + 1
        proxy.httpServer = NEProxyServer(address: "127.0.0.1", port: httpPort)
        proxy.httpsEnabled = true
        proxy.httpsServer = proxy.httpServer
//        proxy.autoProxyConfigurationEnabled = true
//        proxy.proxyAutoConfigurationURL
        proxy.excludeSimpleHostnames = true
        proxy.matchDomains = [""]
        return proxy
    }

}


