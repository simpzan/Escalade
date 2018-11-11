//
//  EscaladeService.swift
//  Escalade
//
//  Created by simpzan on 2018/11/11.
//

import Foundation
import CocoaLumberjackSwift

public protocol EscaladeService {
    typealias ProxyCallback = (Error?) -> Void

    func startProxy(done: @escaping ProxyCallback)
    func stopProxy(done: @escaping ProxyCallback)
    var isProxyRunning: Bool { get }
    func listenProxyStateChange(callback: @escaping (Bool) -> Void)
    
    func getSharedProxy() -> String?
    func setSharedProxy(state: Bool)
    
    func autoSelect(callback: @escaping ([(String, String)]) -> Void)
    func setCurrentServer(server: String) -> Bool
    
    func pingDirect(callback: @escaping (Double?) -> Void)
    func pingProxy(callback: @escaping (Double?) -> Void)
}

private class LocalEscaladeService: EscaladeService {
    func getSharedProxy() -> String? {
        let result = service?.proxyManager.getSharedProxyState()
        return result
    }
    func setSharedProxy(state: Bool) {
        service?.proxyManager.setShareProxyState(state)
    }

    func pingDirect(callback: @escaping (Double?) -> Void) {
        service?.serverController.factory.testCurrent(timeout:1) { (err, result) in
            DDLogInfo("testCurrent \(err*) \(result)")
            callback(result)
        }
    }
    func pingProxy(callback: @escaping (Double?) -> Void) {
        service?.serverController.factory.testDirect(timeout: 1) { err, result in
            DDLogInfo("testDirect \(err*) \(result)")
            callback(result)
        }
    }

    func setCurrentServer(server: String) -> Bool {
        DDLogInfo("switch to server \(server)")
        service?.serverController.currentServer = server
        return true
    }
    func autoSelect(callback: @escaping ([(String, String)]) -> Void) {
        guard let serverController = service?.serverController else { return }
        serverController.autoSelect { (err, server) in
            DDLogInfo("autoSelect callback \(err*) \(server*)")
            if server != nil { return }

            let result = serverController.servers.map { (name, ping) -> (String, String) in
                return (name, miliseconds(ping))
            }
            callback(result)
        }
    }
    
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
