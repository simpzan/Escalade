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
let getConnectionsId = "getConnections"

class APIServer {
    let proxyService: ProxyService
    var serverController: ServerController {
        return proxyService.serverController
    }
    init(_ proxyService: ProxyService) {
        self.proxyService = proxyService
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
        addAsyncAPI(getConnectionsId) { (input, done) in
            let connections = self.proxyService.proxyManager.dump()
            let output = try? JSONEncoder().encode(connections)
            let result = output as NSData?
            done(result)
        }
    }
}

public class APIClient {
    static let shared = APIClient()
    
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
    func getConnections(callback:  @escaping ([ConnectionRecord]?) -> Void) {
        callAsyncAPI(getConnectionsId) { (data) in
            guard let result = data as? Data else { return callback(nil) }
            let connections = try? JSONDecoder().decode([ConnectionRecord].self, from: result)
            callback(connections)
        }
    }
}


let startTrafficMonitorId = "startTrafficMonitor"
let trafficUpdateId = "trafficUpdate"
let stopTrafficMonitorId = "stopTrafficMointor"

class TrafficMonitorServer {
    init() {
        wormhole.listenForMessage(withIdentifier: startTrafficMonitorId) { (_) in
            TrafficMonitor.shared.startUpdate { (rx: Int, tx: Int) in
                DDLogDebug("rx \(rx), tx \(tx)")
                let traffic: [String: Int] = [ "rx": rx, "tx": tx ]
                wormhole.passMessageObject(traffic as NSDictionary, identifier: trafficUpdateId)
            }
        }
        wormhole.listenForMessage(withIdentifier: stopTrafficMonitorId) { (_) in
            TrafficMonitor.shared.stopUpdate()
        }
    }
    deinit {
        wormhole.stopListeningForMessage(withIdentifier: startTrafficMonitorId)
        wormhole.stopListeningForMessage(withIdentifier: stopTrafficMonitorId)
    }
}

class TrafficMonitorClient {
    public typealias UpdateCallback = (Int, Int) -> Void
    var _callback: UpdateCallback?
    
    init() {
        wormhole.listenForMessage(withIdentifier: trafficUpdateId) { (obj) in
            guard let traffic = obj as? [String: Int] else { return }
            if let rx = traffic["rx"], let tx = traffic["tx"]  { self._callback?(rx, tx) }
        }
    }
    deinit {
        wormhole.stopListeningForMessage(withIdentifier: trafficUpdateId)
    }
    
    func startUpdate(callback: @escaping UpdateCallback) {
        _callback = callback
        wormhole.passMessageObject(nil, identifier: startTrafficMonitorId)
        DDLogInfo("traffic monitor started.")
    }
    
    func stopUpdate() {
        wormhole.passMessageObject(nil, identifier: stopTrafficMonitorId)
        _callback = nil
        DDLogInfo("traffic monitor stopped.")
    }
}
