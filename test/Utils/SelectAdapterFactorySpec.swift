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
import Yaml

let c1 = "{ id: us-40, type: ss, host: us-40.hxg.cc, port: 59671, method: rc4-md5, password: l6j0kU26cK }"
let c2 = "{ id: cn2t-52, type: ss, host: cn2t-52.hxg.cc, port: 59671, method: rc4-md5, password: l6j0kU26cK }"
let configString = "adapter:\n  - \(c1)\n  - \(c2)"

class SelectAdapterFactorySpec: QuickSpec {

    override func spec() {
        describe("select adapter factory") {

            it("auto select") {
                let config = try! Yaml.load(configString)
                let manager = try! AdapterFactoryParser.parseAdapterFactoryManager(config["adapter"])
                let factory = manager["proxy"] as! SelectAdapterFactory

                UserDefaults.standard.removeObject(forKey: "currentIdKey")

                let id = factory.currentId
                expect(id).to(equal("direct"))
                let connect = ConnectSession(host: "www.google.com", port: 80, fakeIPEnabled: false)
                let adapter = factory.getAdapterFor(session: connect!)
                expect(adapter).to(beAKindOf(DirectAdapter.self))
                let timeout:TimeInterval = 2
                waitUntil(timeout: timeout + 1, action: { (done) in
                    factory.autoselect(timeout: timeout, callback: { (ids) in
                        print("ids \(ids)")
                        let id = factory.currentId
                        expect(id).to(equal("cn2t-52"))
                        let adapter = factory.getAdapterFor(session: connect!)
                        expect(adapter).to(beAKindOf(ShadowsocksAdapter.self))
                        done()
                    })
                })
            }


        }
    }
}
