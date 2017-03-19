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
            return self.servers as NSCoding?
        }
        addAPI(switchProxyId, callback: { (server) -> NSCoding? in
            let server = server as! String
            DDLogInfo("switch to server \(server)")
            self.serverController.currentServer = server
            return true as NSCoding?
        })
        addAsyncAPI(autoSelectId) { (input, done) in
            self.serverController.autoSelect(callback: { (err, server) in
                DDLogInfo("autoSelect callback \(err) \(server)")
                if server != nil { return }

                let output = self.servers
                done(output as NSCoding?)
            })
        }
    }
}

class APIClient {
    func autoSelect(callback: @escaping ([(String, String)]) -> Void) {
        callAsyncAPI(autoSelectId) { result in
            let pingResults = result as! [[String : String]]
            let result = pingResults.map({ (server) -> (String, String) in
                return (server["name"]!, server["ping"]!)
            })
            callback(result)
        }
    }
    func getServers() -> [String : TimeInterval] {
        let result = callAPI(getServersId)
        return result as! [String : TimeInterval]
    }
    func switchServer(server: String) -> Bool {
        let result = callAPI(switchProxyId)
        return result as! Bool
    }
}
