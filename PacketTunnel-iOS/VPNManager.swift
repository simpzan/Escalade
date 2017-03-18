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

    lazy var dnsServer: DNSServer = {
        let ipRange = try! IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!)
        let fakeIPPool = IPPool(range: ipRange)
        let dnsServer = DNSServer(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53), fakeIPPool: fakeIPPool)
        DNSServer.currentServer = dnsServer
        return dnsServer
    }();
    private func setupPacketProcessor() {
        let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: Port(port: 53))
        dnsServer.registerResolver(resolver)
        interface.register(stack: dnsServer)

        let udpStack = UDPDirectStack()
        interface.register(stack: udpStack)

        let tcpStack = TCPStack.stack
        tcpStack.proxyServer = proxyServerManager.httpServer!
        interface.register(stack: tcpStack)
    }


    let configManager = ConfigurationManager()
    var serverController: ServerController? {
        return proxyServerManager.serverController
    }
    var proxyServerManager: ProxyServerManager {
        return configManager.proxyServerManager
    }
    public var httpProxyAddress: String {
        return proxyServerManager.address
    }
    public var httpProxyPort: UInt16 {
        return proxyServerManager.port
    }

    private var interface: TUNInterface!

    public init(provider: NEPacketTunnelProvider) {
        ObserverFactory.currentFactory = DebugObserverFactory()
        RawSocketFactory.TunnelProvider = provider
        Opt.MAXNWTCPSocketReadDataSize = 60 * 1024

        if !configManager.reloadConfigurations() {
            DDLogError("load config failed")
        }

        interface = TUNInterface(packetFlow: provider.packetFlow)

        connectivityState = getConnectivityState()
    }

    public func reset() {
        let state = getConnectivityState()
        if connectivityState == state { return }

        DDLogInfo("connectivity changed: \(connectivityState) -> \(state)")
        connectivityState = state

        stop()
        start()
    }
    private var connectivityState: ConnectivityState = .none

    public func start() {
        if connectivityState == .none { return DDLogInfo("no connectvity, do not start vpn.") }
        queue.sync {
            proxyServerManager.startProxyServers()
            self.setupPacketProcessor()
            self.interface?.start()
            DDLogInfo("vpn started")
        }
    }

    public func stop() {
        queue.sync {
            self.interface?.stop()
            proxyServerManager.stopProxyServers()
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
