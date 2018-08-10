//
//  EscaladeTests_macOS.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/10.
//
import Quick
import Nimble
@testable import Escalade_macOS

class NetworkSpec: QuickSpec {
    override func spec() {
        it("dns ok") {
            let result = [String]()
            expect(result).to(contain("159.89.119.178"))
        }
    }
}

