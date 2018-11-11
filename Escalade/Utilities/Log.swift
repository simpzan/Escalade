//
//  Log.swift
//  Escalade
//
//  Created by simpzan on 2018/8/6.
//

import Foundation
import CocoaLumberjackSwift
import NEKit

public func setupLog() {
    ObserverFactory.currentFactory = ESObserverFactory()

    let levelRaw = defaults.integer(forKey: logLevelKey)
    let level: DDLogLevel = levelRaw == 0 ? .info : DDLogLevel(rawValue: UInt(levelRaw))!
    
    let path = getContainerDir(groupId: groupId, subdir: "/Logs/")
    setupLog(level, path)
    setLogLevel(level)
}

public func setLogLevel(_ level: DDLogLevel) {
    DDLogInfo("log level changing, \(ddLogLevel.rawValue) -> \(level.rawValue).")
    ddLogLevel = level
    defaultDebugLevel = level
    defaults.set(level.rawValue, forKey: logLevelKey)
}

public func getLogLevel() -> DDLogLevel {
    let levelRaw = defaults.integer(forKey: logLevelKey)
    DDLogInfo("log level \(levelRaw)")
    guard let level = DDLogLevel(rawValue: UInt(levelRaw)) else { return .info }
    
    switch level {
    case DDLogLevel.off: return .info
    default: return level
    }
}

private let logLevelKey = "logLevel"
