//
//  Utils.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Foundation

public func filesize(_ file: String) -> UInt64? {
    guard let attr = try? FileManager.default.attributesOfItem(atPath: file) else { return nil }
    return attr[FileAttributeKey.size] as? UInt64
}

public func delay(_ delay: Double, closure: @escaping () -> Void) {
    let time = delay > 0 ? delay : 0;
    DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: closure)
}

func miliseconds(_ time: TimeInterval) -> String {
    if time == 0 { return "" }
    if time < 0 { return "Failed" }
    let pingResult = Int(time * 1000.0)
    let pingStatus = "\(pingResult)ms"
    return pingStatus
}

func readableSize(_ byteCount: Int) -> String {
    let units = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB", "NB", "DB", "CB"]
    let step = 1024
    var count = byteCount
    for i in 0...(units.count) {
        if count < step { return "\(count)\(units[i])" }
        count /= step
    }
    return ""
}
