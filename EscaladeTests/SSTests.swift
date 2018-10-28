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
import CocoaLumberjackSwift

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
func proxyTest(url:String, factory: AdapterFactory) {
    let timeout: TimeInterval = 4
    waitUntil(timeout: timeout + 1, action: { (done) in
        httpPing(url: url, factory: factory, timeout: timeout) { (error, result) in
            print("ping result \(url) \(error) \(result)")
            expect(result) < timeout + 0.5
            expect(error).to(beNil())
            done()
        }
    })
}
class ShadowsocksSpec: QuickSpec {
    override func spec() {
        describe("ss tests") {
            fit("ping google") {
                let factory = getFactory(host: "hk1-sta12.3a8kf.website",
                                              port: 21652,
                                              encryption: "chacha20-ietf-poly1305",
                                              password: "X8gS58DUAkrJxPF")
                let url = "http://google.com/generate_204"
                proxyTest(url: url, factory: factory)
            }
        }
    }
}
