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
import NEKit

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

    override func spec() {
        describe("http ping tests") {
            it("ping ok") {
                let factory = self.getFactory(host: "cn2t-52.hxg.cc",
                                         port: 59671,
                                         encryption: "rc4-md5",
                                         password: "l6j0kU26cK")
                waitUntil(timeout: 3, action: { (done) in
                    httpPing(factory:factory, timeout: 2) { (error, result) in
                        print("ping result \(error) \(result)")
                        expect(result) < 2.5
                        expect(error).to(beNil())
                        done()
                    }
                })
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
        }
    }
}
