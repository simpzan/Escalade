//
//  Utils.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/8/17.
//
//

import Cocoa

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
