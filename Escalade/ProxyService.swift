//
//  ProxyService.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
//
//

import Foundation
import NetworkExtension
import NEKit
import CocoaLumberjackSwift

class ProxyService {
    let proxyManager: ProxyServerManager
    let serverController: ServerController
    var tunController: TUNController? = nil
    var running = false;

    init(adapterFactoryManager: AdapterFactoryManager, provider: NEPacketTunnelProvider? = nil, defaults: UserDefaults = .standard) {
        ObserverFactory.currentFactory = DebugObserverFactory()

        proxyManager = ProxyServerManager()

        let factory = adapterFactoryManager.selectFactory
        serverController = ServerController(selectFactory: factory, defaults: defaults)

        if let provider = provider {
            tunController = TUNController(provider: provider, httpServer: proxyManager.socks5Server!)
        }
        RuleManager.currentManager = createDefaultRules(adapterFactoryManager: adapterFactoryManager)
    }
    
    private func createDefaultRules(adapterFactoryManager: AdapterFactoryManager) -> RuleManager {
        var rules: [Rule] = []
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: adapterFactoryManager["direct"]!)
        rules.append(chinaRule)
        let intranetRule = CountryRule(countryCode: "--", match: true, adapterFactory: adapterFactoryManager["direct"]!)
        rules.append(intranetRule)
        let allRule = AllRule(adapterFactory: adapterFactoryManager["proxy"]!)
        rules.append(allRule)
        return RuleManager(fromRules: rules)
    }

    func start() {
        DDLogInfo("starting")
        proxyManager.startProxyServers()
        tunController?.start()
        running = true
        DDLogInfo("started")
    }

    func stop() {
        DDLogInfo("stopping")
        tunController?.stop()
        proxyManager.stopProxyServers()
        running = false
        DDLogInfo("stopped")
    }

    func restart() {
        stop()
        start()
    }
    func toggle() {
        if running { stop() }
        else { start() }
    }
}
