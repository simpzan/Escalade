//
//  GCDUDPSocket.swift
//  NEKit
//
//  Created by simpzan on 2018/8/11.
//  Copyright © 2018 Zhuhao Wang. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import CocoaLumberjackSwift

public class GCDUDPSocket: NSObject, RawUDPSocketProtocol, GCDAsyncUdpSocketDelegate {
    public var timeout: Int = Opt.UDPSocketActiveTimeout
    
    public override init() {
        super.init()
        DDLogInfo("\(self) init")
    }
    deinit {
        DDLogInfo("\(self) deinit, tx \(tx), rx \(rx)")
    }
    
    var _socket: GCDAsyncUdpSocket!
    public func bindEndpoint(_ host: String, _ port: UInt16) -> Bool {
        let queue = QueueFactory.getQueue()
        _socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
        try! _socket.connect(toHost: host, onPort: port)
        try! _socket.beginReceiving()
        let result = _socket.isConnected()
        DDLogInfo("\(self) \(host):\(port), \(result)")
        return true
    }
    
    public weak var delegate: RawUDPSocketDelegate?
    
    var rx = 0
    var tx = 0
    public func write(data: Data) {
        _socket.send(data, withTimeout: -1, tag: 1)
        tx += data.count
    }
    
    public func disconnect() {
        _socket.closeAfterSending()
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        rx += data.count
        delegate?.didReceive(data: data, from: self)
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        DDLogError("\(self) send data failed, \(String(describing: error))")
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        delegate?.didCancel(socket: self)
    }
}
