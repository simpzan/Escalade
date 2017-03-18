//
//  Log.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/19/17.
//
//

import Foundation
import CocoaLumberjackSwift


private let fileLogger: DDFileLogger? = {
    defaultDebugLevel = .info
    DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs

    let logger = DDFileLogger()!
    logger.rollingFrequency = TimeInterval(60*60*12)
    logger.logFileManager.maximumNumberOfLogFiles = 3
    DDLog.add(logger, with: .debug)
    return logger
}()
public var logFile: String? {
    return fileLogger?.logFileManager?.sortedLogFilePaths?.first
}
