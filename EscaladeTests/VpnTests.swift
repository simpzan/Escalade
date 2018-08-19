//
//  VpnTests.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/12.
//
import Quick
import Nimble
import NetworkExtension

#if os(iOS)
@testable import Escalade_iOS
#else
@testable import Escalade_macOS
#endif

var disableVpnAfterTests = true

class VPNTests: QuickSpec {
    override class func setUp() {
        super.setUp()
        ensureVpnEnabled()
    }
    override class func tearDown() {
        super.tearDown()
        if disableVpnAfterTests { ensureVpnDisabled() }
    }
    override func spec() {
        sharedExamples("vpn cases") {
            let api = APIClient.shared
            beforeEach {
                api.setProxyEnabled(true)
                usleep(500 * 1000)
            }
            afterEach {
                api.setProxyEnabled(false)
                usleep(500 * 1000)
            }
            it("ping twitter ok.") {
                urlSessionHttpPing(url: "http://twitter.com")
            }
            it("ping baidu ok, too.") {
                urlSessionHttpPing(url: "http://bdstatic.com")
            }
            it("ping baidu with socket ok.") {
                socketHttpPing(url: "bdstatic.com")
            }
            it("ping twitter with socket ok.") {
                socketHttpPing(url: "twitter.com")
            }
            
            let fakeIpPrefix = "198.18."
            it("dns baidu returns real ip.") {
                let ips = dnsTest("baidu.com") as! [String]
                NSLog("ips for baidu.com \(ips)")
                let ip = ips[0]
                expect(ip).notTo(beginWith(fakeIpPrefix))
            }
            it("dns google returns fake ip.") {
                let ip = dnsTest("google.com").first as! String
                expect(ip).to(beginWith(fakeIpPrefix))
            }
            
            it("udp with ip ok") {
                let request = "hello from EscaladeTests"
                let response = udpSend("159.89.119.178", 8877, request)
                expect(request) == response
            }
            it("udp with domain ok") {
                let request = "hello from EscaladeTests with domain."
                udpSocketTest(request)
            }
        }
//        fcontext("leak tests") {
//            itBehavesLike("vpn cases")
//            disableVpnAfterTests = false
//        }
        itBehavesLike("vpn cases")
        itBehavesLike("vpn cases")
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
    waitUntil(timeout: 6) { (done) in
        socket = SocketHttpTest(host: url, port: 80, callback: { (err:Error?, data) in
            if let err = err {
                let error = err as NSError
                expect(error.code) == GCDAsyncSocketError.closedError.rawValue
                NSLog("error \(error)")
            }
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
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "HEAD"
    let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
//        NSLog("\(err) \(data) \(response)")
        guard let res = response as? HTTPURLResponse else {
            return done(false)
        }
        let result = res.statusCode == 200 && err == nil
        done(result)
    }
    task.resume()
}
