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

