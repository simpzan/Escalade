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
    let url: URL
    init(factory: AdapterFactory, url: URL) {
        self.factory = factory
        self.url = url
    }

    var startTimestamp: Date!

    var done = false
    var callback: ((Error?, TimeInterval) -> Void)?

    func start(timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
        let request = ConnectSession(host: url.host!, port:80, fakeIPEnabled:false)
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
        queue.async {
            self.callback?(error, result)
            self.callback = nil
        }
    }

    func didBecomeReadyToForwardWith(socket: SocketProtocol) {
        var path = url.path
        if path.characters.count == 0 { path = "/" }
        let requestContent = "HEAD \(path) HTTP/1.1\r\nHOST: \(url.host!)\r\n\r\n"
        adapter.write(data: requestContent.data(using: String.Encoding.utf8)!)
        adapter.readData()
    }
    func didRead(data: Data, from: SocketProtocol) {
        done = true

        let response204Prefix = "HTTP/1.1 204 No Content\r\n"
        let response200Prefix = "HTTP/1.1 200 OK\r\n"
        let responsePrefix = url.path.hasSuffix("_204") ? response204Prefix : response200Prefix

        let res = String(data: data as Data, encoding: String.Encoding.utf8)
        let error = res!.hasPrefix(responsePrefix) ? nil : PingError.PingUnexpectedResultError
        finish(error: error)

        adapter.disconnect()
    }

    func didConnectWith(adapterSocket: AdapterSocket) {}
    func didDisconnectWith(socket: SocketProtocol) {}
    func didWrite(data: Data?, by: SocketProtocol) {}
    func didReceive(session: ConnectSession, from: ProxySocket) {}
    func updateAdapterWith(newAdapter: AdapterSocket) {}
}

public func httpPing(url: String = "http://gstatic.com/generate_204", factory: AdapterFactory,
                     timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
    let ping = HttpPing(factory: factory, url: URL(string: url)!)
    ping.start(timeout: timeout, callback: callback)
}
