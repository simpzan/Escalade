//
//  API.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/19/17.
//
//

import Foundation
import CocoaLumberjackSwift

let switchProxyId = "switchProxy"
let getServersId = "getServers"
let autoSelectId = "autoSelect"
let pingDirectId = "pingDirect"
let pingProxyId = "pingProxy"

class APIServer {
    let serverController: ServerController
    init(_ serverController: ServerController) {
        self.serverController = serverController
    }
    var servers: [[String: String]] {
        let result = serverController.servers.map { (name, ping) -> [String: String] in
            return ["name": name, "ping": miliseconds(ping)]
        }
        return result
    }

    func stop() {
        removeAPI(getServersId)
        removeAPI(switchProxyId)
        removeAPI(autoSelectId)
    }
    func start() {
        addAPI(getServersId) { (_) -> NSCoding? in
            let result = self.servers
            DDLogInfo("get servers \(result.count)")
            return result as NSCoding?
        }
        addAPI(switchProxyId, callback: { (server) -> NSCoding? in
            let server = server as! String
            DDLogInfo("switch to server \(server)")
            self.serverController.currentServer = server
            return true as NSCoding?
        })
        addAsyncAPI(autoSelectId) { (input, done) in
            self.serverController.autoSelect(callback: { (err, server) in
                DDLogInfo("autoSelect callback \(err*) \(server*)")
                if server != nil { return }

                let output = self.servers
                done(output as NSCoding?)
            })
        }
        addAsyncAPI(pingDirectId) { (input, done) in
            self.serverController.factory.testDirect(timeout: 1) { err, result in
                if err != nil {
                    DDLogError("testDirect error \(err!)")
                    return done(nil)
                }
                DDLogInfo("testDirect \(result)")
                done(NSNumber(floatLiteral: result))
            }
        }
        addAsyncAPI(pingProxyId) { (input, done) in
            self.serverController.factory.testCurrent(timeout:1) { (err, result) in
                if (err != nil) {
                    DDLogError("testCurrent error \(err!)")
                    return done(nil)
                }
                DDLogInfo("testCurrent \(result)")
                done(NSNumber(floatLiteral: result))
            }
        }
    }
}

class APIClient {
    func convert(result: NSCoding?) -> [(String, String)]? {
        let servers = result as? [[String : String]]
        return servers?.map({ (server) -> (String, String) in
            return (server["name"]!, server["ping"]!)
        })
    }
    func autoSelect(callback: @escaping ([(String, String)]) -> Void) {
        callAsyncAPI(autoSelectId) { result in
            let result = self.convert(result: result)
            callback(result!)
        }
    }
    func getServers() -> [(String, String)]? {
        let result = callAPI(getServersId)
        return convert(result: result)
    }
    func getServersAsync(callback: @escaping ([(String, String)]?) -> Void) {
        callAsyncAPI(getServersId) { (result) in
            callback(self.convert(result: result))
        }
    }
    func switchServer(server: String) -> Bool {
        let result = callAPI(switchProxyId, obj: server as NSCoding?)
        return result as! Bool
    }
    public func pingDirect(callback: @escaping (Double?) -> Void) {
        callAsyncAPI(pingDirectId) { (result) in
            guard let number = result as? NSNumber else { return callback(nil) }
            callback(number.doubleValue)
        }
    }
    public func pingProxy(callback: @escaping (Double?) -> Void) {
        callAsyncAPI(pingProxyId) { (result) in
            guard let number = result as? NSNumber else { return callback(nil) }
            callback(number.doubleValue)
        }
    }
}
