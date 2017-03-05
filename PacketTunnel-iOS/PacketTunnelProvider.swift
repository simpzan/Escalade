//
//  PacketTunnelProvider.swift
//  PacketTunnel-iOS
//
//  Created by Samuel Zhang on 3/5/17.
//
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
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
        settings.proxySettings = getProxySettings()
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
        setTunnelNetworkSettings(getTunnelSettings()) { (error) in
            if error != nil {
                NSLog("\(#function) error:\(error)")
                return
            }
            NSLog("connected")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
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
