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

class VPNManager: NSObject {
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

    private func setupPacketProcessor() {
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
    }

    public let httpProxyAddress = "127.0.0.1"
    public let httpProxyPort: UInt16 = 9090
    public let socksProxyPort: UInt16 = 9091

    private var interface: TUNInterface!
    private var httpProxyServer: GCDProxyServer?

    init(provider: NEPacketTunnelProvider) {
        super.init()

        ObserverFactory.currentFactory = DebugObserverFactory()
        RawSocketFactory.TunnelProvider = provider
        Opt.MAXNWTCPSocketReadDataSize = 60 * 1024

        setupRuleManager()
        httpProxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: httpProxyAddress), port: Port(port: httpProxyPort))

        interface = TUNInterface(packetFlow: provider.packetFlow)

        connectivityState = getConnectivityState()
        provider.addObserver(self, forKeyPath: "defaultPath", options: [.new], context: nil)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let state = getConnectivityState()
        if connectivityState == state { return }

        DDLogInfo("connectivity changed: \(connectivityState) -> \(state)")
        connectivityState = state

        stop()
        if state != .none { start() }

    }
    private var connectivityState = ConnectivityState.none

    public func start() {
        queue.sync {
            try! self.httpProxyServer?.start()
            self.setupPacketProcessor()
            self.interface?.start()
            DDLogInfo("vpn started")
        }
    }

    public func stop() {
        queue.sync {
            self.interface?.stop()
            self.httpProxyServer?.stop()
            DDLogInfo("vpn stopped")
        }
    }

    let queue = DispatchQueue(label: "com.simpzan.Escalade.iOS")
}


func getConnectivityState() -> ConnectivityState {
    let addrs = getNetworkAddresses()

    var result = ConnectivityState.none
    if addrs?["en0"] != nil { result = .wifi }
    else if addrs?["pdp_ip0"] != nil { result = .celluar }

    DDLogDebug("connectivity state \(result), addrs \(addrs)")
    return result
}
enum ConnectivityState {
    case wifi, celluar, none
}
