//
//  Utils.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Foundation

public func getContainerDir(groupId: String, subdir: String) -> String {
    let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId)!.path
    return path + subdir
}

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
    var remaining = 0
    var unitIndex = 0
    for i in 0...(units.count) {
        if count < step {
            unitIndex = i
            break
        }
        remaining = count % step
        count /= step
    }
    let fraction = remaining == 0 ? "" : ".\(remaining/102)"
    return "\(count)\(fraction)\(units[unitIndex])"
}

extension Bundle {
    func fileContent(_ file: String) -> String? {
        let filename = file as NSString
        let ext = filename.pathExtension
        let name = filename.deletingPathExtension
        guard let url = self.url(forResource: name, withExtension: ext) else { return nil }

        return try? String(contentsOf: url)
    }
}

postfix operator *
extension Optional {
    static postfix func *(o: Optional) -> String {
        return o.description
    }
    var description: String {
        if self == nil { return "nil" }
        return "\(self!)"
    }
}
