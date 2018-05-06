//
//  UtilsCocoa.swift
//  Escalade
//
//  Created by Samuel Zhang on 3/18/17.
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
    let output = String(data: outdata, encoding: .utf8)

    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    let error_output = String(data: errdata, encoding: .utf8)

    task.waitUntilExit()
    let status = task.terminationStatus

    return (output!, error_output!, status)
}

func sendNotification(title: String, text: String) {
    let notification = NSUserNotification()
    notification.title = title
    notification.informativeText = text
    NSUserNotificationCenter.default.deliver(notification)
}

public func selectFile() -> String? {
    let dialog = NSOpenPanel()
    if dialog.runModal() == .OK {
        return dialog.url?.path
    }
    return nil
}

public func alert(_ title: String, buttons: [String] = ["OK"]) -> Int {
    let alert = NSAlert()
    buttons.forEach { alert.addButton(withTitle: $0) }
    alert.messageText = title
    let result = alert.runModal()
    return result.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
}

public func confirm(_ title: String) -> Bool {
    return alert(title, buttons: ["OK", "Cancel"]) == 0
}

func copyString(string: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
}

extension NSObject {
    func createMenuItem(title: String, tag: Int, state: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title
        item.tag = tag
        item.state = state ? .on : .off
        item.toolTip = title
        item.target = self
        item.action = action
        return item
    }
}

extension NSMenu {
    func removeItems(withTag tag: Int) {
        let itemsToKeep = items.filter { $0.tag != tag }
        removeAllItems()
        itemsToKeep.forEach { addItem($0) }
    }
}
