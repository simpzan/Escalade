//
//  VPNManager.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/10/17.
//
//

import Foundation
import CocoaLumberjackSwift
import NetworkExtension
import NEKit

class VPNManager {
    private func getFactory(host: String, port: Int, encryption: String, password: String) -> AdapterFactory {
        let protocolObfuscaterFactory = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
        let streamObfuscaterFactory = ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory()
        let algorithm = CryptoAlgorithm(rawValue: encryption.uppercased())
        let cryptoFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm!)
        return ShadowsocksAdapterFactory(serverHost: host,
                                         serverPort: port,
                                         protocolObfuscaterFactory: protocolObfuscaterFactory,
                                         cryptorFactory: cryptoFactory,
                                         streamObfuscaterFactory: streamObfuscaterFactory)
    }
    private func setupRuleManager() {
        let file = Bundle(for: type(of: self)).path(forResource: "config", ofType: "plist")!
        let config = NSDictionary(contentsOfFile: file)!
        let ssAdapterFactory = getFactory(host: config["host"] as! String,
                                          port: config["port"] as! Int,
                                          encryption: config["encryption"] as! String,
                                          password: config["password"] as! String)
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: DirectAdapterFactory())
        let allRule = AllRule(adapterFactory: ssAdapterFactory)
        let manager = RuleManager(fromRules: [chinaRule, allRule], appendDirect: true)
        RuleManager.currentManager = manager
    }
    func startProxyServer() {
        NSLog("startProxyServer")

        setupRuleManager()

        httpProxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: httpProxyAddress), port: Port(port: httpProxyPort))
        try! httpProxyServer!.start()

        NSLog("proxy started!")
    }
    var httpProxyServer: GCDProxyServer?


    public let httpProxyAddress = "127.0.0.1"
    public let httpProxyPort: UInt16 = 9090
    public let socksProxyPort: UInt16 = 9091


    func startPacketProcessor(packetFlow: NEPacketTunnelFlow) {
        Opt.MAXNWTCPSocketReadDataSize = 60 * 1024
        interface = TUNInterface(packetFlow: packetFlow)

        let ipRange = try! IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!)
        let fakeIPPool = IPPool(range: ipRange)
        let dnsServer = DNSServer(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53), fakeIPPool: fakeIPPool)
        let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53))
        dnsServer.registerResolver(resolver)
        interface.register(stack: dnsServer)
        DNSServer.currentServer = dnsServer

        let udpStack = UDPDirectStack()
        interface.register(stack: udpStack)

        let tcpStack = TCPStack.stack
        tcpStack.proxyServer = httpProxyServer
        interface.register(stack: tcpStack)

        interface.start()
    }
    private var interface: TUNInterface!


    let packetFlow: NEPacketTunnelFlow
    init(provider: NEPacketTunnelProvider) {
        RawSocketFactory.TunnelProvider = provider
        packetFlow = provider.packetFlow
        ObserverFactory.currentFactory = DebugObserverFactory()
    }

    public func start() {
        setupRuleManager()
        startProxyServer()
        startPacketProcessor(packetFlow: packetFlow)
        DDLogInfo("vpn started")
    }

    public func stop() {
        interface?.stop()
        httpProxyServer?.stop()
        DDLogInfo("vpn stopped")
    }

    public func restart() {
//        httpProxyServer?.stop()
//        try! httpProxyServer?.start()
    }

    func listenReachabilityChange() {
        func onReachabilityChange(_: Any) {
            DispatchQueue.main.async {
                self.restart()
            }
        }
        reachability.whenReachable = onReachabilityChange
        reachability.whenUnreachable = onReachabilityChange
        try? reachability.startNotifier()
    }
    let reachability = Reachability()!

}
