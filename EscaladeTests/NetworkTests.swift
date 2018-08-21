//
//  EscaladeTests_macOS.swift
//  EscaladeTests-macOS
//
//  Created by simpzan on 2018/8/10.
//
import Quick
import Nimble
#if os(iOS)
@testable import Escalade_iOS
#else
@testable import Escalade_macOS
#endif

class LeakTest {
    init() {
        let address = Utils.address(of: self)
        NSLog("\(address) \(#function, #line)")
    }
    deinit {
        let address = Utils.address(of: self)
        NSLog("\(address) \(#function, #line)")
    }
    func test() {
    }
}

extension RunLoop {
    func run(for seconds: TimeInterval) {
        let date = Date(timeIntervalSinceNow: seconds)
        self.run(until: date)
    }
}
class DispatchQueueTests: QuickSpec {
    override func spec() {
        it("runAfter ok") {
            let queue = DispatchQueue(label: "com.simpzan.test.2")
            var runned = false
            let task = queue.runAfter(0.5) {
                runned = true
            }
            _ = task
            RunLoop.current.run(for: 1)
            expect(runned) == true
        }
        it("runAfter cancel ok") {
            let queue = DispatchQueue(label: "com.simpzan.test.3")
            var runned = false
            let test = LeakTest()
            let task = queue.runAfter(100) {
                runned = true
                test.test()
            }
            task.cancel()
            sleep(2)
            expect(runned) == false
            // check the log to ensure the LeakTest object is deinited once this code block completes.
        }
    }
}

class NetworkTests: QuickSpec {
    override func spec() {
        it("dns ok") {
            let result = dnsTest("simpzan.com") as! [String]
            expect(result).to(contain("159.89.119.178"))
        }
        it("GCDUDPSocket ok") {
            let request = "hello from EscaladeTests with domain."
            var socket: GcdUdpSocketTest!
            waitUntil(timeout: 10) { (done) in
                socket = GcdUdpSocketTest(host: "simpzan.com", port: 8877, data: request) { (err, response) in
                    expect(err).to(beNil())
                    expect(response) == request
                    done()
                }
                _ = socket // to silence the compiler warning.
            }
        }
    }
}


class GcdUdpSocketTest: NSObject, RawUDPSocketDelegate {
    func didCancel(socket: RawUDPSocketProtocol) {
        NSLog("\(#function)")
    }
    
    typealias Callback = (Error?, String?) -> Void
    private let _callback: Callback
    private let _host: String
    private let _port: UInt16
    init(host: String, port: UInt16, data: String, callback: @escaping Callback) {
        _callback = callback
        _port = port
        _host = host
        super.init()
        start(data.data(using: .utf8)!)
    }

    var _socket: GCDUDPSocket!
    let _queue = DispatchQueue(label: "com.simpzan.test.udp")
    func start(_ data: Data) {
        _socket = GCDUDPSocket()
        _socket.delegate = self
        _ = _socket.bindEndpoint(_host, _port)
        _socket.write(data: data)
    }
    
    func didReceive(data: Data, from: RawUDPSocketProtocol) {
        let result = String(data: data, encoding: .utf8)
        _callback(nil, result)
    }
}

