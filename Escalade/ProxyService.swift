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

    init?(provider: NEPacketTunnelProvider? = nil, defaults: UserDefaults = .standard) {
        proxyManager = ProxyServerManager()

        guard let adapterFactoryManager = createAdapterFactoryManager() else {
            DDLogError("failed to load servers.")
            return nil
        }

        let factory = adapterFactoryManager.selectFactory
        serverController = ServerController(selectFactory: factory, defaults: defaults)

        _provider = provider
        if let provider = provider {
            tunController = TUNController(provider: provider, httpServer: proxyManager.socks5Server!)
        }
        RuleManager.currentManager = createDefaultRules(adapterFactoryManager: adapterFactoryManager)
    }
    
    private func createDomainRule(ruleFile: String, adapter: AdapterFactory) -> Rule? {
        do {
            let filepath = Bundle.main.path(forResource: ruleFile, ofType: "rule")!
            let content = try String(contentsOfFile: filepath)
            let regexs = content.components(separatedBy: CharacterSet.newlines)
            let criteria = try! regexs.filter { (regex: String) -> Bool in
                return !regex.isEmpty
            }.map { (regex: String) -> DomainListRule.MatchCriterion in
                let re = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                return .regex(re)
            }
            return DomainListRule(adapterFactory: adapter, criteria: criteria)
        } catch let error {
            DDLogError("createDomainRule \(ruleFile) failed, \(error)")
            return nil
        }
    }
    private func createDefaultRules(adapterFactoryManager: AdapterFactoryManager) -> RuleManager {
        var rules: [Rule] = []
        if let directRule = createDomainRule(ruleFile: "DirectDomain", adapter: adapterFactoryManager["direct"]!) {
            rules.append(directRule)
        }
        if let proxyRule = createDomainRule(ruleFile: "ProxyDomain", adapter: adapterFactoryManager["proxy"]!) {
            rules.append(proxyRule)
        }
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: adapterFactoryManager["direct"]!)
        rules.append(chinaRule)
        let intranetRule = CountryRule(countryCode: "--", match: true, adapterFactory: adapterFactoryManager["direct"]!)
        rules.append(intranetRule)
        let allRule = AllRule(adapterFactory: adapterFactoryManager["proxy"]!)
        rules.append(allRule)
        return RuleManager(fromRules: rules)
    }
    
    private let queue = DispatchQueue(label: "com.simpzan.Escalade.ProxyServiceQueue")
    typealias ProxyServiceCallback = (Error?) -> Void
    public func start(callback: ProxyServiceCallback? = nil) {
        _provider?.setTunnelNetworkSettings(tunController?.getTunnelSettings()) { (error) in
            if let err = error {
                DDLogError("setTunnelNetworkSettings failed, \(err).")
            } else {
                self.queue.sync { self._start() }
            }
            callback?(error)
        }
    }
    public func stop(callback: ProxyServiceCallback? = nil) {
        queue.sync { self._stop() }
        _provider?.setTunnelNetworkSettings(nil) { (error) in
            callback?(error)
        }
    }
    let _provider: NEPacketTunnelProvider?

    private func _start() {
        guard !running else { return }
        
        serverController.onCurrentServerChanged = { [weak self] in
            self?.proxyManager.resetInactives()
        }
        
        DDLogInfo("starting")
        proxyManager.startProxyServers()
        tunController?.start()
        running = true
        DDLogInfo("started")
    }
    private func _stop() {
        guard running else { return }
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
