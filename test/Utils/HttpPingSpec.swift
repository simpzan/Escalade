//
//  HttpPingSpec.swift
//  NEKit
//
//  Created by Samuel Zhang on 1/9/17.
//  Copyright © 2017 Zhuhao Wang. All rights reserved.
//

import Foundation

import Quick
import Nimble
@testable import NEKit

class HttpPingSpec: QuickSpec {

    func getFactory(host: String, port: Int, encryption: String, password: String) -> AdapterFactory {
        let protocolObfuscaterFactory = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
        let streamObfuscaterFactory = ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory()
        let algorithm = CryptoAlgorithm(rawValue: encryption.uppercased())
        let cryptoFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm!)

        let factory = ShadowsocksAdapterFactory(serverHost: host,
                                                serverPort: port,
                                                protocolObfuscaterFactory: protocolObfuscaterFactory,
                                                cryptorFactory: cryptoFactory,
                                                streamObfuscaterFactory: streamObfuscaterFactory)
        return factory
    }

    func directTest(url: String) {
        let factory = DirectAdapterFactory()
        let timeout:TimeInterval = 1
        waitUntil(timeout: timeout + 1, action: { (done) in
            httpPing(url: url, factory: factory, timeout: timeout, callback: { (error, result) in
                print("ping result \(url): \(error) \(result)")
                expect(result) < timeout + 0.5
                expect(error).to(beNil())
                done()
            })
        })
    }

    func proxyTest(url:String, proxy: String) {
        let factory = self.getFactory(host: proxy,
                                      port: 59671,
                                      encryption: "rc4-md5",
                                      password: "l6j0kU26cK")
        let timeout: TimeInterval = 4
        waitUntil(timeout: timeout + 1, action: { (done) in
            httpPing(url: url, factory: factory, timeout: timeout) { (error, result) in
                print("ping result \(url) \(proxy) \(error) \(result)")
                expect(result) < timeout + 0.5
                expect(error).to(beNil())
                done()
            }
        })
    }

    override func spec() {
        describe("http ping tests") {
            it("ping google") {
                self.proxyTest(url: "http://google.com/generate_204", proxy: "cn2t-52.hxg.cc")
            }

            it("ping gstatic") {
                self.proxyTest(url: "http://gstatic.com/generate_204", proxy: "cn2t-52.hxg.cc")
            }

            it("ping timeout") {
                let factory = self.getFactory(host: "cn2t-64.hxg",
                                              port: 59671,
                                              encryption: "rc4-md5",
                                              password: "l6j0kU26cK")
                waitUntil(timeout: 3, action: { (done) in
                    httpPing(factory:factory, timeout: 1) { (error, result) in
                        print("ping result \(error) \(result)")
                        expect(result) >= 1
                        expect(error).toNot(beNil())
                        done()
                    }
                })
            }

            it("direct ping baidu.com") {
                self.directTest(url: "http://baidu.com")
            }

            it("direct ping bdstatic.com") {
                self.directTest(url: "http://bdstatic.com")
            }

            it("direct ping miui.com") {
                self.directTest(url: "http://connect.rom.miui.com/generate_204")
            }

            it("direct ping sinaapp.com") {
                self.directTest(url: "http://http204.sinaapp.com/generate_204")
            }

        }
    }
}
