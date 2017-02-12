//
//  AutoLaunchHelper.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/12/17.
//
//

import Cocoa
import ServiceManagement

class AutoLaunchHelper: NSObject {
    init(identifier: String) {
        self.identifier = identifier
    }
    let identifier: String

    public var enabled: Bool {
        return defaults.bool(forKey: defaultKey)
    }
    private let defaults = UserDefaults.standard
    private var defaultKey: String {
        return "SMLoginItem-" + identifier
    }

    public func setEnabled(enabled: Bool) -> Bool {
        if SMLoginItemSetEnabled(identifier as CFString, enabled) {
            defaults.set(enabled, forKey: defaultKey)
            return true
        }
        return false
    }

    public func validate() -> Bool {
        if setEnabled(enabled: enabled) {
            return true
        }
        defaults.removeObject(forKey: defaultKey)
        return false
    }

}
