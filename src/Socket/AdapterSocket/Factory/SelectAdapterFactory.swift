//
//  SelectAdapterFactory.swift
//  SpechtLite
//
//  Created by Samuel Zhang on 1/9/17.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation

public class SelectAdapterFactory: AdapterFactory {

    public init(factories: [String: AdapterFactory], directFactory: AdapterFactory) {
        self.factories = factories
        self.directFactory = directFactory
    }

    override func getAdapterFor(session: ConnectSession) -> AdapterSocket {
        return currentFactory.getAdapterFor(session: session)
    }

    // MARK: -
    public var servers: [String] {
        return factories.keys.sorted()
    }
    private let factories: [String: AdapterFactory]
    private let directFactory: AdapterFactory

    public var current: String {
        get {
            if isValid(server: _current) { return _current }
            return servers.first ?? "direct"
        }
        set(name) {
            if isValid(server: name) { _current = name }
        }
    }
    private var _current: String! = nil
    private func isValid(server: String!) -> Bool {
        return server != nil && factories[server] != nil
    }
    private var currentFactory: AdapterFactory {
        return factories[current] ?? directFactory
    }

    // MARK: -
    public func pingValue(forServer server: String) -> TimeInterval {
        return _pingResults[server] ?? 0
    }
    private var _pingResults: [String: TimeInterval] = [:]


    public func testCurrent(callback: @escaping (Error?, TimeInterval) -> Void) {
        let id = current
        httpPing(factory: currentFactory, timeout: 2) { (err, result) in
            self._pingResults[id] = result
            callback(err, result)
        }
    }

    public func testDirect(callback: @escaping (Error?, TimeInterval) -> Void) {
        httpPing(url: "http://bdstatic.com/", factory: directFactory, timeout: 2) { (err, result) in
            self.domesticPing = result
            callback(err, result)
        }
    }
    public var domesticPing: TimeInterval = 0


    public func autoSelect(timeout: TimeInterval, callback: @escaping (String?) -> Void) {
        var fastestFound = false
        func pingDone(server: String, ping: TimeInterval) {
            self._pingResults[server] = ping
            if !fastestFound && !server.hasSuffix("+") {
                fastestFound = true
                self._current = server
                callback(server) // optionally called once with server name when found ok.
            }
        }

        let serversToTest = servers.filter { !$0.hasSuffix("-") }
        let total = serversToTest.count
        var count = 0
        for server in serversToTest {
            let factory = factories[server]!
            httpPing(factory: factory, timeout: timeout) {
                pingDone(server: server, ping: $1)

                count += 1
                if count == total { callback(nil) }
            }
        }
    }
}
