//
//  RPC.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
//
//

import Foundation
import MMWormhole
import CocoaLumberjackSwift

let configKey = "config"

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

func callAsyncAPI(_ id: String, obj: NSCoding? = nil, timeout: TimeInterval = 5,
                  callback: @escaping (NSCoding?) -> Void) {
    let id2 = replyId(id)
    var done = false
    wormhole.listenForMessage(withIdentifier: id2) { (obj) in
        done = true
        wormhole.stopListeningForMessage(withIdentifier: id2)
        callback(obj as! NSCoding?)
    }
    delay(timeout) {
        if done { return }
        DDLogWarn("callAsyncAPI timeout \(id) \(obj)")
        wormhole.stopListeningForMessage(withIdentifier: id2)
        callback(nil)
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
    if !done {
        DDLogWarn("callAPI timeout \(id) \(obj)")
    }
    return result
}
