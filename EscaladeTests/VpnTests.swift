//
//  VpnTests.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/12.
//
import XCTest
import Nimble
import NetworkExtension

#if os(iOS)
@testable import Escalade_iOS
#else
@testable import Escalade_macOS
#endif

class VpnTests2: VpnTests {}

class VpnTests: XCTestCase {
    static var enableCalled = 0
    static var disableCalled = 0
    override class func setUp() {
        super.setUp()
        if (enableCalled == 0) { ensureVpnEnabled() }
        enableCalled += 1
    }
    override class func tearDown() {
        super.tearDown()
        NSLog("\(#function, #line)")
        disableCalled += 1
        if (disableCalled == 2) { ensureVpnDisabled() }
    }
    override func setUp() {
        super.setUp()
        NSLog("\(#function, #line)")
        api.setProxyEnabled(true)
        sleep(1)
    }
    override func tearDown() {
        super.tearDown()
        NSLog("\(#function, #line)")
        api.setProxyEnabled(false)
        sleep(1)
    }
    let api = APIClient.shared

    func testPingTwitterOk() {
        urlSessionHttpPing(url: "http://twitter.com")
    }
    func testPingQQOk() {
        urlSessionHttpPing(url: "http://qq.com")
    }
    func pingQQWithSocketOk() {
        socketHttpPing(url: "qq.com")
    }
    func pingTwitterWithSocketOk() {
        socketHttpPing(url: "twitter.com")
    }
    let fakeIpPrefix = "198.18."
    func testDnsBaiduReturnsRealIp() {
        let ips = dnsTest("baidu.com") as! [String]
        NSLog("ips for baidu.com \(ips)")
        let ip = ips[0]
        expect(ip).notTo(beginWith(fakeIpPrefix))
    }
    func testDnsGoogleReturnsFakeIp() {
        let ip = dnsTest("google.com").first as! String
        expect(ip).to(beginWith(fakeIpPrefix))
    }
    func testUdpWithIpOk() {
        let request = "hello from EscaladeTests with ip"
        let response = udpSend("159.89.119.178", 8877, request)
        expect(request) == response
    }
    func testUdpWithDomainOk() {
        let request = "hello from EscaladeTests with domain."
        udpSocketTest(request)
    }
}

func ensureVpnEnabled() {
    waitUntil(timeout: 5) { (done) in
        NSLog("ensure vpn enabled")
        if vpn.connected { return done() }

        vpn.monitorStatus(callback: { (status) in
            if status == .connected { done() }
        })
        vpn.startVPN()
    }
}
func ensureVpnDisabled() {
    waitUntil(timeout: 3, action: { (done) in
        NSLog("disabling vpn")
        vpn.monitorStatus(callback: { (status) in
            if status == .disconnected { done() }
        })
        vpn.stopVPN()
    })
}
let vpn = VPNManager.shared

func udpSocketTest(_ request: String) {
    var socket: UdpSocketTest!
    waitUntil(timeout: 4) { (done) in
        socket = UdpSocketTest(host: "simpzan.com", port: 8877, data: request) { (err, response) in
            expect(err).to(beNil())
            expect(response) == request
            done()
            _ = socket // to silence the compiler warning.
        }
    }
}
func socketHttpPing(url: String) {
    var socket: SocketHttpTest! = nil
    waitUntil(timeout: 4) { (done) in
        socket = SocketHttpTest(host: url, port: 80, callback: { (err:Error?, data) in
            expect(err).to(beNil())
            expect(data!.count) > 0
            done()
            _ = socket // to silence the compiler warning.
        })
    }
}

func urlSessionHttpPing(url: String) {
    waitUntil(timeout: 3, action: { (done) in
        httpPing(url: url, done: { (result) in
            expect(result) == true
            done()
        })
    })
}
func httpPing(url: String, done: @escaping (Bool) -> Void) {
    let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, err) in
        guard let res = response as? HTTPURLResponse else {
            return done(false)
        }
        let result = res.statusCode == 200 && err == nil
        done(result)
    }
    task.resume()
}
