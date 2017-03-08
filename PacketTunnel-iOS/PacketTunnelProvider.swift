//
//  PacketTunnelProvider.swift
//  PacketTunnel-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import NetworkExtension
import NEKit
import CocoaLumberjackSwift

class PacketTunnelProvider: NEPacketTunnelProvider {
    func getFactory(host: String, port: Int, encryption: String, password: String) -> AdapterFactory {
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
    func setupRuleManager() {
        let ssAdapterFactory = getFactory(host: "cn2t-52.hxg.cc",
                                          port: 59671,
                                          encryption: "rc4-md5",
                                          password: "")
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

    func getTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.0.2.2")
        settings.mtu = 1600
        settings.dnsSettings = NEDNSSettings(servers: ["114.114.114.114"])
        let v4Settings = NEIPv4Settings(addresses:["192.0.2.1"], subnetMasks:["255.255.255.0"])
        v4Settings.includedRoutes = [NEIPv4Route.default()]
        v4Settings.excludedRoutes = [NEIPv4Route(destinationAddress:"114.114.114.114", subnetMask:"255.255.255.255")]
        settings.iPv4Settings = v4Settings
//        settings.proxySettings = getProxySettings()
        return settings
    }
    func getProxySettings() -> NEProxySettings {
        let proxy = NEProxySettings()
        proxy.httpEnabled = true
        proxy.httpServer = NEProxyServer(address: httpProxyAddress, port: Int(httpProxyPort))
        proxy.httpsEnabled = true
        proxy.httpsServer = proxy.httpServer
        return proxy
    }

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        NSLog("startTunnel \(options)")

        DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
        DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
        ObserverFactory.currentFactory = DebugObserverFactory()

        self.startProxyServer()
        setTunnelNetworkSettings(getTunnelSettings()) { (error) in
            if error != nil {
                NSLog("\(#function) error:\(error)")
                return
            }
            self.startPacketProcessor()
            NSLog("connected")
            completionHandler(nil)
        }
    }

    func startPacketProcessor() {
        RawSocketFactory.TunnelProvider = self
        self.interface = TUNInterface(packetFlow: self.packetFlow)

        let ipRange = try! IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!)
        let fakeIPPool = IPPool(range: ipRange)
        let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: Port(port: 53), fakeIPPool: fakeIPPool)
        let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53))
        dnsServer.registerResolver(resolver)
        self.interface.register(stack: dnsServer)
        DNSServer.currentServer = dnsServer

        let udpStack = UDPDirectStack()
        self.interface.register(stack: udpStack)

        let tcpStack = TCPStack.stack
        tcpStack.proxyServer = self.httpProxyServer
        self.interface.register(stack: tcpStack)
        self.interface.start()
    }
    var interface: TUNInterface!

    func readTun() {
        packetFlow.readPackets { (packets, protocols) in
            NSLog("read packets \(protocols)")
            self.readTun()
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        interface.stop()
        httpProxyServer?.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        if let handler = completionHandler {
			handler(messageData)
		}
	}

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
	}

	override func wake() {
	}
}
