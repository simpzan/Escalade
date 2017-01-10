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

    public var currentId: String = "direct"

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

    public func autoselect(callback: @escaping ([(String, TimeInterval)]) -> Void) {
        var adapterIds: [(String,TimeInterval)] = []
        let total = self.factories.count
        for (id, factory) in factories {
            httpPing(factory: factory, timeout: 2, callback: { (error, result) in
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
            return !(item.1 == -1 || item.0.hasSuffix("*"))
        }
        if let selected = selected {
            currentId = selected.0
        }
    }

}
