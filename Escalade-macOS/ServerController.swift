//
//  ServerController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Cocoa
import NEKit

class ServerController: NSObject {
    public var servers: [String] {
        guard let factory = selectFactory else { return [] }
        return factory.pingResults.map{ $0.0 }
    }
    public var currentServer: String? {
        get {
            return selectFactory?.currentId
        }
        set(name) {
            if name != nil {
                selectFactory?.currentId = name!
            }
        }
    }
    public func pingValue(ofServer server: String) -> TimeInterval {
        let item = selectFactory?.pingResults.first { $0.0 == server }
        if item == nil { return 0 }
        return (item?.1)!
    }
    public func autoSelectServer(callback: @escaping (Error?) -> Void) {
        func pingProxy() {
            selectFactory?.autoselect(timeout:2, callback: { (pingResults) in
                callback(nil)
            })
        }
        directTest() { (err, result) in
            if err != nil {
                callback(err)
            } else {
                pingProxy()
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
        directTest { (err, result) in
            done()
        }
        selectFactory!.pingSelected { (err, result) in
            done()
        }
    }

    public init(manager: AdapterFactoryManager) {
        selectFactory = manager.selectFactory
        directFactory = manager.directFactory
    }

    private var selectFactory: SelectAdapterFactory?
    private var directFactory: DirectAdapterFactory?

    private func directTest(callback: @escaping (Error?, TimeInterval) -> Void) {
        httpPing(url: "http://bdstatic.com/", factory: directFactory!, timeout: 2) { (err, result) in
            print("ping baidu result \(err) \(result)")
            if err != nil {
                self.domesticPing = -1
            } else {
                self.domesticPing = result
            }
            callback(err, result)
        }
    }
    var domesticPing: TimeInterval = 0

}
