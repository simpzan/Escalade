//
//  Utils.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Cocoa

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
