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

class VpnTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        NSLog("\(#function, #line)")
        ensureVpnEnabled()
    }
    override func setUp() {
        super.setUp()
        NSLog("\(#function, #line)")
        api.setProxyEnabled(true)
        sleep(1)
    }
    override class func tearDown() {
        super.tearDown()
        NSLog("\(#function, #line)")
        ensureVpnDisabled()
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
        var socket: UdpSocketTest!
        waitUntil(timeout: 10) { (done) in
            socket = UdpSocketTest(host: "simpzan.com", port: 8877, data: request) { (err, response) in
                expect(err) == nil
                expect(response) == request
                done()
            }
        }
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

func socketHttpPing(url: String) {
    var socket: SocketHttpTest! = nil
    waitUntil(timeout: 4) { (done) in
        socket = SocketHttpTest(host: url, port: 80, callback: { (err:Error?, data) in
            expect(err) == nil
            expect(data!.count) > 0
            done()
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
        NSLog("\(data) \(response) \(err)")
        let res = response as! HTTPURLResponse
        done(res.statusCode == 200)
    }
    task.resume()
}
