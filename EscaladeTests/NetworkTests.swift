//
//  EscaladeTests_macOS.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/10.
//
import XCTest
import Nimble
#if os(iOS)
@testable import Escalade_iOS
#else
@testable import Escalade_macOS
#endif

class NetworkTests: XCTestCase {
    func testDnsOk() {
        let result = dnsTest("simpzan.com") as! [String]
        expect(result).to(contain("159.89.119.178"))
    }
    func testGcdUdpSocketOk() {
        let request = "hello from EscaladeTests with domain."
        var socket: GcdUdpSocketTest!
        waitUntil(timeout: 10) { (done) in
            socket = GcdUdpSocketTest(host: "simpzan.com", port: 8877, data: request) { (err, response) in
                expect(err) == nil
                expect(response) == request
                done()
            }
        }
    }
}


class GcdUdpSocketTest: NSObject, RawUDPSocketDelegate {
    func didCancel(socket: RawUDPSocketProtocol) {
        NSLog("\(#function)")
    }
    
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

    var _socket: GCDUDPSocket!
    let _queue = DispatchQueue(label: "com.simpzan.test.udp")
    func start(_ data: Data) {
        _socket = GCDUDPSocket()
        _socket.delegate = self
        _ = _socket.bindEndpoint(_host, _port)
        _socket.write(data: data)
    }
    
    func didReceive(data: Data, from: RawUDPSocketProtocol) {
        let result = String(data: data, encoding: .utf8)
        _callback(nil, result)
    }
}

