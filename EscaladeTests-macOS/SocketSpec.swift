//
//  SocketSpec.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/10.
//

import Foundation
import CocoaAsyncSocket

class UdpSocketTest: NSObject, GCDAsyncUdpSocketDelegate {
    typealias Callback = (Error?, String?) -> Void
    private let _callback: Callback
    private let _host: String
    private let _port: UInt16
    init(host: String, port: UInt16, data: String, callback: @escaping Callback) {
        _callback = callback
        _port = port
        _host = host
        super.init()
        start(data.data(using: .utf8)!)
    }

    var _socket: GCDAsyncUdpSocket!
    let _queue = DispatchQueue(label: "com.simpzan.test.udp")
    func start(_ data: Data) {
        _socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: _queue);
        try! _socket.bind(toPort: 0)
        _socket.send(data, toHost: _host, port: _port, withTimeout: 2, tag: 1)
        try! _socket.beginReceiving()
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data,
            fromAddress address: Data, withFilterContext filterContext: Any?) {
        let result = String(data: data, encoding: .utf8)
        _callback(nil, result)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        _callback(error, nil)
    }
}

class SocketHttpTest: NSObject, GCDAsyncSocketDelegate {
    typealias Callback = (Error?, Data?) -> Void
    private let _callback: Callback
    private let _host: String
    private let _port: UInt16
    private var _data = Data()
    init(host: String, port:UInt16, callback: @escaping Callback) {
        _callback = callback
        _port = port
        _host = host
        super.init()
        start()
    }
    
    var _socket: GCDAsyncSocket!
    let queue = DispatchQueue(label: "com.simpzan.test")
    
    func start() {
        _socket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
        try! _socket.connect(toHost: _host, onPort: _port)
        let request = "GET / HTTP/1.1\r\nConnection: close\r\n\r\n"
        _socket.write(request.data(using: .utf8)!, withTimeout: 5, tag: 1)
        _socket.readData(withTimeout: -1, tag: 2)
        NSLog("\(#function)")
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        NSLog("\(#function) \(data.count)")
        _data.append(data)
        sock.readData(withTimeout: -1, tag: 2)
    }
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        NSLog("\(#function)")
    }
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        NSLog("\(#function)")
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        NSLog("\(#function)")
        _callback(err, _data)
    }
}
