//
//  API.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/19/17.
//
//

import Foundation
import CocoaLumberjackSwift

class APIServer {
    let serverController: ServerController
    init(_ serverController: ServerController) {
        self.serverController = serverController
    }
    var servers: [String: TimeInterval] {
        var servers: [String: TimeInterval] = [:]
        serverController.servers.forEach({ (server) in
            servers[server.0] = server.1
        })
        return servers
    }

    var getServersHandler: APIHandler? = nil
    var switchServerHandler: APIHandler? = nil
    var autoSelectHandler: APIHandler? = nil
    func stop() {
        getServersHandler?(); getServersHandler = nil
        switchServerHandler?(); switchServerHandler = nil
        autoSelectHandler?(); autoSelectHandler = nil
    }
    func start() {
        getServersHandler = addAPI(id: getServersId) { (_) -> NSCoding? in
            return self.servers as NSCoding?
        }
        switchServerHandler = addAPI(id: switchProxyId, callback: { (server) -> NSCoding? in
            let server = server as! String
            DDLogInfo("switch to server \(server)")
            self.serverController.currentServer = server
            return true as NSCoding?
        })
        autoSelectHandler = addAPIAsync(id: autoSelectId) { (input, done) in
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
    func autoSelect(callback: @escaping ([String : TimeInterval]) -> Void) {
        callAPIAsync(id: autoSelectId) { result in
            let pingResults = result as! [String : TimeInterval]
            callback(pingResults)
        }
    }
    func getServers() -> [String : TimeInterval] {
        let result = callAPI(id: getServersId)
        return result as! [String : TimeInterval]
    }
    func switchServer(server: String) -> Bool {
        let result = callAPI(id: switchProxyId)
        return result as! Bool
    }
}
