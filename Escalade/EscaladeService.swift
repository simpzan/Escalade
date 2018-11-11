//
//  EscaladeService.swift
//  Escalade
//
//  Created by simpzan on 2018/11/11.
//

import Foundation

public protocol EscaladeService {
    typealias ProxyCallback = (Error?) -> Void

    func startProxy(done: @escaping ProxyCallback)
    func stopProxy(done: @escaping ProxyCallback)
    var isProxyRunning: Bool { get }
    func listenProxyStateChange(callback: @escaping (Bool) -> Void)
    
}

private class LocalEscaladeService: EscaladeService {
    func listenProxyStateChange(callback: @escaping (Bool) -> Void) {
        proxyUpdateCallback = callback
    }
    
    var proxyUpdateCallback: ((Bool) -> Void)? = nil
    var isProxyRunning: Bool = false
    private func setProxyState(_ state: Bool) {
        guard state != isProxyRunning else { return }
        isProxyRunning = state
        proxyUpdateCallback?(state)
    }
    
    let service = ProxyService(provider: nil, defaults: defaults)
    
    func startProxy(done: @escaping (Error?) -> Void) {
        service?.start { (err) in
            done(err)
            self.setProxyState(err == nil)
        }
    }
    func stopProxy(done: @escaping (Error?) -> Void) {
        service?.stop { (err) in
            done(err)
            self.setProxyState(false)
        }
    }
    
}

//private class RemoteEscaladeService: EscaladeService {
//
//}


public func createEscaladeService(rpcMode: Bool = false) -> EscaladeService {
    return LocalEscaladeService()
}
