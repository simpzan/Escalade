//
//  TCPPing.swift
//  Shadow
//
//  Created by Samuel Zhang on 16/10/1.
//
//

import Foundation

public enum PingError:Error {
    case PingTimeoutError, PingUnexpectedResultError
}

class HttpPing : SocketDelegate {

    let queue = DispatchQueue.main

    var adapter: AdapterSocket!
    let factory: AdapterFactory
    init(factory: AdapterFactory) {
        self.factory = factory
    }

    var startTimestamp: Date!

    var done = false
    var callback: ((Error?, TimeInterval) -> Void)?

    func start(timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
        let request = ConnectSession(host:"www.google.com", port:80, fakeIPEnabled:false)
        let adapter = factory.getAdapterFor(session: request!)
        adapter.delegate = self
        adapter.openSocketWith(session: request!)
        self.adapter = adapter

        startTimestamp = Date()

        queue.asyncAfter(deadline: DispatchTime.now() + timeout) {
            if (!self.done) {
                adapter.forceDisconnect()
                self.finish(error: PingError.PingTimeoutError)
            }
        }

        self.callback = callback
    }

    func finish(error: Error?) -> Void {
        let result = Date().timeIntervalSince(startTimestamp)
        self.callback?(error, result)
        self.callback = nil
    }

    func didBecomeReadyToForwardWith(socket: SocketProtocol) {
        let requestContent = "GET /generate_204 HTTP/1.1\r\nHOST: www.google.com\r\n\r\n"
        adapter.write(data: requestContent.data(using: String.Encoding.utf8)!)
        adapter.readData()
    }
    func didRead(data: Data, from: SocketProtocol) {
        done = true
        let res = String(data: data as Data, encoding: String.Encoding.utf8)
        let responseContentPrefix = "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\n"
        if res!.hasPrefix(responseContentPrefix) {
            finish(error: nil)
        } else {
            finish(error: PingError.PingUnexpectedResultError)
        }
        adapter.disconnect()
    }

    func didConnectWith(adapterSocket: AdapterSocket) {}
    func didDisconnectWith(socket: SocketProtocol) {}
    func didWrite(data: Data?, by: SocketProtocol) {}
    func didReceive(session: ConnectSession, from: ProxySocket) {}
    func updateAdapterWith(newAdapter: AdapterSocket) {}
}

public func httpPing(factory: AdapterFactory, timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
    let ping = HttpPing(factory: factory)
    ping.start(timeout: timeout, callback: callback)
}
