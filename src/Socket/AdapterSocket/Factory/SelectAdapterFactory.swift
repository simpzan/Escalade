//
//  SelectAdapterFactory.swift
//  SpechtLite
//
//  Created by Samuel Zhang on 1/9/17.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation

public class SelectAdapterFactory: AdapterFactory {

    public var pingResults: [(String, TimeInterval)] = []
    private let factories: [String: AdapterFactory]

    private let currentIdKey = "currentIdKey"
    private var currentId_: String?
    private let defaults = UserDefaults.standard
    public var currentId: String {
        get {
            if currentId_ == nil {
                currentId_ = defaults.string(forKey: currentIdKey)
            }
            if currentId_ == nil || factories[currentId_!] == nil {
                return "direct"
            }
            return currentId_!
        }
        set(id) {
            currentId_ = id
            defaults.set(id, forKey: currentIdKey)
        }
    }

    public var selected: AdapterFactory? {
        get {
            return factories[self.currentId]
        }
    }

    public init(factories: [String: AdapterFactory]) {
        self.factories = factories
        for (id, _) in factories {
            pingResults.append((id, 0))
        }
    }

    override func getAdapterFor(session: ConnectSession) -> AdapterSocket {
        let factory = factories[currentId]
        return (factory?.getAdapterFor(session: session))!
    }


    public func pingSelected(callback: @escaping (Error?, TimeInterval) -> Void) {
        httpPing(factory: selected!, timeout: 2) { (err, result) in
            print("ping google result \(err) \(result)")
            let id = self.currentId
            let pingResult = err != nil ? -1 : result
            var pingResults = self.pingResults.filter { $0.0 != id }
            pingResults.insert((id, pingResult), at: 0)
            self.pingResults = pingResults
            callback(err, result)
        }
    }

    public func autoselect(timeout:TimeInterval, callback: @escaping ([(String, TimeInterval)]) -> Void) {
        var adapterIds: [(String,TimeInterval)] = []
        var total = self.factories.count

        for (id, factory) in factories {
            if id.hasSuffix("-") {
                total -= 1
                print("autoselect skip \(id)")
            }
            httpPing(factory: factory, timeout: timeout, callback: { (error, result) in
                print("ping \(id) result \(error) \(result)")
                let pingResult = error != nil ? -1 : result
                adapterIds.append((id, pingResult))
                if adapterIds.count == total {
                    self.sortAndSelectId(ids: adapterIds)
                    callback(self.pingResults)
                }
            })
        }
    }

    private func sortAndSelectId(ids: [(String, TimeInterval)]) {
        pingResults = ids.sorted { (item1, item2) -> Bool in
            if item1.1 == -1 {
                return false
            } else if item2.1 == -1 {
                return true
            } else {
                return item1.1 - item2.1 < 0
            }
        }

        let selected = pingResults.first { (item) -> Bool in
            return !(item.1 == -1 || item.0.hasSuffix("+"))
        }
        if let selected = selected {
            currentId = selected.0
        }
    }

}
