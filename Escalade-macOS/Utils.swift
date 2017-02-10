//
//  Utils.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Cocoa


public func runCommand(path: String, args: [String]) -> (output: String, error: String, exitCode: Int32) {
    print("\(path) \(args)")
    let task = Process()
    task.launchPath = path
    task.arguments = args

    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe
    task.launch()

    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: outdata, encoding: String.Encoding.utf8)

    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    let error_output = String(data: errdata, encoding: String.Encoding.utf8)

    task.waitUntilExit()
    let status = task.terminationStatus

    return (output!, error_output!, status)
}

func copyString(string: String) {
    let pasteboard = NSPasteboard.general()
    pasteboard.clearContents()
    pasteboard.setString(string, forType: NSStringPboardType)
}

func sendNotification(title: String, text: String) {
    let notification = NSUserNotification()
    notification.title = title
    notification.informativeText = text
    NSUserNotificationCenter.default.deliver(notification)
}

func miliseconds(fromSecond time: TimeInterval) -> String {
    let pingResult = Int(time * 1000.0)
    let pingStatus = "\(pingResult)ms"
    return pingStatus
}

extension NSObject {
    func createMenuItem(title: String, tag: Int, state: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title
        item.tag = tag
        item.state = state ? NSOnState : NSOffState
        item.toolTip = title
        item.target = self
        item.action = action
        return item
    }
}

extension NSMenu {
    func removeItems(withTag tag: Int) {
        let itemsToKeep = items.filter { $0.tag != tag }
        print("keeping \(itemsToKeep.count) items")
        removeAllItems()
        itemsToKeep.forEach { addItem($0) }
    }
}
