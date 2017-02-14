//
//  ServerController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Cocoa
import NEKit
import CocoaLumberjackSwift

class ServerController: NSObject {
    public var servers: [(String, TimeInterval)] {
        return factory.servers.map { server in
            let ping = factory.pingValue(forServer: server)
            return (server, ping)
        }.sorted(by: { (item1, item2) -> Bool in
            let ping1 = item1.1, ping2 = item2.1
            if ping1 > 0 && ping2 > 0 {
                return ping1 < ping2
            } else {
                return ping1 > ping2
            }
        })
    }

    public var currentServer: String? {
        get {
            return factory.current
        }
        set(name) {
            if name == nil { return }
            factory.current = name!
            defaults.set(name, forKey: currentServerKey)
        }
    }
    private let defaults = UserDefaults.standard
    private let currentServerKey = "currentServer"

    public var domesticPing: TimeInterval {
        return factory.domesticPing
    }
    public var internationalPing: TimeInterval {
        return factory.pingValue(forServer: factory.current)
    }

    public enum AutoSelectError: Error {
        case DirectPingError, ProxyPingError
    }
    public func autoSelect(callback: @escaping (Error?, String?) -> Void) {
        factory.testDirect { err, result in
            DDLogInfo("ping direct when selecting: \(err) \(result)")
            if err != nil {
                callback(AutoSelectError.DirectPingError, nil)
                return
            }
            var selected: String? = nil
            self.factory.autoSelect(timeout: 2) { server in
                if server != nil {
                    selected = server
                    callback(nil, server)
                } else if selected != nil {
                    DDLogInfo("auto select: \(selected) \(self.servers)")
                    callback(nil, nil)
                } else {
                    DDLogInfo("auto select failed: \(self.servers)")
                    callback(AutoSelectError.ProxyPingError, nil)
                }
            }
        }
    }
    public func pingTest(callback: @escaping (Error?) -> Void) {
        var count = 0
        func done() {
            count += 1
            if count == 2 {
                callback(nil)
            }
        }
        factory.testDirect { err, result in
            DDLogInfo("ping direct: \(err) \(result)")
            done()
        }
        factory.testCurrent { err, result in
            DDLogInfo("ping proxy: \(err) \(result)")
            done()
        }
    }

    public init(selectFactory: SelectAdapterFactory) {
        factory = selectFactory
        if let name = defaults.string(forKey: currentServerKey) {
            factory.current = name
        }
    }
    private let factory: SelectAdapterFactory
}
