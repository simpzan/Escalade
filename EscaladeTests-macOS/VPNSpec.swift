//
//  VPNSpec.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/10.
//

import Quick
import Nimble
import NetworkExtension
@testable import Escalade_macOS

class VPNSpec: QuickSpec {
    override func spec() {
        let vpn = VPNManager.shared
        beforeEach {
            waitUntil(timeout: 5) { (done) in
                NSLog("ensure vpn enabled")
                if vpn.connected { return done() }

                vpn.monitorStatus(callback: { (status) in
                    if status == .connected { done() }
                })
                vpn.startVPN()
            }
        }
        afterEach {
            waitUntil(timeout: 3, action: { (done) in
                NSLog("disabling vpn")
                vpn.monitorStatus(callback: { (status) in
                    if status == .disconnected { done() }
                })
                vpn.stopVPN()
            })
        }
        describe("when vpn enabled") {
            it("ping twitter ok.") {
                self.urlSessionHttpPing(url: "http://twitter.com")
            }
            it("ping qq ok, too.") {
                self.urlSessionHttpPing(url: "http://qq.com")
            }
            it("ping qq with socket ok.") {
                self.socketHttpPing(url: "qq.com")
            }
            it("ping twitter with socket ok.") {
                self.socketHttpPing(url: "twitter.com")
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
    }
    
    func socketHttpPing(url: String) {
        var socket: SocketHttpTest! = nil
        waitUntil(timeout: 4) { (done) in
            socket = SocketHttpTest(host: url, port: 80, callback: { (err:Error?, data) in
                expect(err) == nil
                done()
            })
        }
    }
    
    func urlSessionHttpPing(url: String) {
        waitUntil(timeout: 3, action: { (done) in
            self.httpPing(url: url, done: { (result) in
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
}

