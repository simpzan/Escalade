//
//  RPC.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
//
//

import Foundation
import MMWormhole

let configKey = "config"

let groupId = "group.com.simpzan.Escalade-iOS"
let defaults = UserDefaults(suiteName: groupId)!
func save(key: String, value: String) {
    defaults.set(value, forKey: key)
}
func load(key: String) -> String? {
    return defaults.string(forKey: key)
}

typealias APICallback = (NSCoding?) -> NSCoding?
typealias DoneCallback = (NSCoding?) -> Void
typealias AsyncAPICallback = (NSCoding?, @escaping DoneCallback) -> Void

private let wormhole = MMWormhole(applicationGroupIdentifier: groupId, optionalDirectory: "wormhole")
private func replyId(_ id: String) -> String {
    return id + ".reply"
}

func removeAPI(_ id: String) {
    wormhole.stopListeningForMessage(withIdentifier: id)
}

func addAsyncAPI(_ id: String, callback: @escaping AsyncAPICallback) {
    wormhole.listenForMessage(withIdentifier: id) { (obj) in
        callback(obj as! NSCoding?) { output in
            wormhole.passMessageObject(output, identifier: replyId(id))
        }
    }
}
func addAPI(_ id: String, callback: @escaping APICallback) {
    wormhole.listenForMessage(withIdentifier: id) { (obj) in
        let output = callback(obj as! NSCoding?)
        wormhole.passMessageObject(output, identifier: replyId(id))
    }
}

func callAsyncAPI(_ id: String, obj: NSCoding? = nil, callback: @escaping (NSCoding?) -> Void) {
    let id2 = replyId(id)
    wormhole.listenForMessage(withIdentifier: id2) { (obj) in
        wormhole.stopListeningForMessage(withIdentifier: id2)
        callback(obj as! NSCoding?)
    }
    wormhole.passMessageObject(obj, identifier: id)
}
func callAPI(_ id: String, obj: NSCoding? = nil) -> NSCoding? {
    var result: NSCoding? = nil
    var done = false
    callAsyncAPI(id, obj: obj) { (obj) in
        result = obj
        done = true
    }
    let now = Date()
    while !done && -now.timeIntervalSinceNow < 0.5 {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
    return result
}
