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

    init(config: Configuration, provider: NEPacketTunnelProvider? = nil) {
        proxyManager = ProxyServerManager(config: config)

        let factory = config.adapterFactoryManager.selectFactory
        serverController = ServerController(selectFactory: factory)

        if let provider = provider {
            tunController = TUNController(provider: provider, httpServer: proxyManager.httpServer!)
        }
    }

    func start() {
        proxyManager.startProxyServers()
        tunController?.start()
    }

    func stop() {
        tunController?.stop()
        proxyManager.stopProxyServers()
    }

    func restart() {
        stop()
        start()
    }

}
