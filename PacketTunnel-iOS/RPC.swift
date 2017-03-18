//
//  RPC.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
//
//

import Foundation
import MMWormhole

let switchProxyId = "switchProxy"
let getServersId = "getServers"

typealias APIHandler = (Void) -> Void

let wormhole = MMWormhole(applicationGroupIdentifier: "group.com.simpzan.Escalade-iOS", optionalDirectory: "wormhole")

func addAPI(id: String, callback: @escaping (NSCoding?) -> NSCoding?) -> APIHandler {
    wormhole.listenForMessage(withIdentifier: id) { (obj) in
        let output = callback(obj as! NSCoding?)
        wormhole.passMessageObject(output, identifier: id + ".reply")
    }

    return {
        wormhole.stopListeningForMessage(withIdentifier: id)
    }
}

func callAPIAsync(id: String, obj: NSCoding? = nil, callback: @escaping (NSCoding?) -> Void) {
    let replyId = id + ".reply"
    wormhole.listenForMessage(withIdentifier: replyId) { (obj) in
        wormhole.stopListeningForMessage(withIdentifier: replyId)
        callback(obj as! NSCoding?)
    }
    wormhole.passMessageObject(obj, identifier: id)
}
func callAPI(id: String, obj: NSCoding? = nil) -> NSCoding? {
    var result: NSCoding? = nil
    var done = false
    callAPIAsync(id: id, obj: obj) { (obj) in
        result = obj
        done = true
    }
    let now = Date()
    while !done && -now.timeIntervalSinceNow < 0.5 {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
    return result
}
