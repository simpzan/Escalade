//
//  TCPPing.swift
//  Shadow
//
//  Created by Samuel Zhang on 16/10/1.
//
//

import Foundation

public enum PingError:Error {
    case PingTimeoutError, PingUnexpectedResultError, PingConnectError
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

    var callback: ((Error?, TimeInterval) -> Void)?

    func start(timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
        let request = ConnectSession(host: url.host!, port:80, fakeIPEnabled:false)
        let adapter = factory.getAdapterFor(session: request!)
        (adapter.socket as? GCDTCPSocket)?.verbose = true
        adapter.delegate = self
        adapter.openSocketWith(session: request!)
        self.adapter = adapter

        startTimestamp = Date()

        queue.asyncAfter(deadline: DispatchTime.now() + timeout) {
            if (!adapter.isDisconnected) {
                adapter.forceDisconnect()
                self.error = PingError.PingTimeoutError
                self.finish(Date())
            }
        }

        self.callback = callback
    }

    func didBecomeReadyToForwardWith(socket: SocketProtocol) {
        var path = url.path
        if path.characters.count == 0 { path = "/" }
        let requestContent = "HEAD \(path) HTTP/1.1\r\nHOST: \(url.host!)\r\n\r\n"
        adapter.write(data: requestContent.data(using: String.Encoding.utf8)!)
        adapter.readData()
    }
    func didRead(data: Data, from: SocketProtocol) {
        let response204Prefix = "HTTP/1.1 204 No Content\r\n"
        let response200Prefix = "HTTP/1.1 200 OK\r\n"
        let responsePrefix = url.path.hasSuffix("_204") ? response204Prefix : response200Prefix

        let res = String(data: data as Data, encoding: String.Encoding.utf8)
        error = res!.hasPrefix(responsePrefix) ? nil : PingError.PingUnexpectedResultError

        adapter.disconnect()
    }
    func didDisconnectWith(socket: SocketProtocol) {
        let now = Date()
        queue.async {
            self.finish(now)
        }
    }
    private var error: Error? = PingError.PingConnectError

    private func finish(_ now: Date) {
        if self.callback == nil { return }
        let diff = now.timeIntervalSince(startTimestamp)
        print("\(url) cost \(diff) \(error)")
        let result = error == nil ? diff : -diff
        self.callback?(self.error, result)
        self.callback = nil
    }

    func didConnectWith(adapterSocket: AdapterSocket) {}
    func didWrite(data: Data?, by: SocketProtocol) {}
    func didReceive(session: ConnectSession, from: ProxySocket) {}
    func updateAdapterWith(newAdapter: AdapterSocket) {}
}

public func httpPing(url: String = "http://gstatic.com/generate_204", factory: AdapterFactory,
                     timeout: TimeInterval, callback: @escaping (Error?, TimeInterval) -> Void) {
    let ping = HttpPing(factory: factory, url: URL(string: url)!)
    ping.start(timeout: timeout, callback: callback)
}
