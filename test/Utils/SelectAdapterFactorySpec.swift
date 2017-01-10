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

class SelectAdapterFactorySpec: QuickSpec {

    override func spec() {
        describe("select adapter factory") {

            it("auto select") {
                let configFile = "/Users/simpzan/.SpechtLite/xxx.yaml"
                let profile = try! String(contentsOfFile: configFile)
                let configuration = NEKit.Configuration()

                try! configuration.load(fromConfigString: profile)
                let manager = configuration.adapterFactoryManager
                let factory = SelectAdapterFactory(manager: manager!)

                waitUntil(timeout: 3, action: { (done) in
                    factory.autoselect(callback: { (ids) in
                        print("ids \(ids)")
                        done()
                    })
                })
            }
            
        }
    }
}
