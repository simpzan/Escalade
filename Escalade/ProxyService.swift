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

    init(config: Configuration, provider: NEPacketTunnelProvider? = nil, defaults: UserDefaults = .standard) {
        proxyManager = ProxyServerManager(config: config)

        let factory = config.adapterFactoryManager.selectFactory
        serverController = ServerController(selectFactory: factory, defaults: defaults)

        if let provider = provider {
            tunController = TUNController(provider: provider, httpServer: proxyManager.socks5Server!)
        }
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
