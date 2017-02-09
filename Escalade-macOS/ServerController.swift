//
//  ServerController.swift
//  Escalade
//
//  Created by Samuel Zhang on 2/9/17.
//
//

import Cocoa
import NEKit

class ServerController: NSObject {
    public var servers: [String] {
        guard let factory = selectFactory else { return [] }
        return factory.pingResults.map{ $0.0 }
    }
    public var currentServer: String? {
        get {
            return selectFactory?.currentId
        }
        set(name) {
            if name != nil {
                selectFactory?.currentId = name!
            }
        }
    }
    public func autoSelectServer() {

    }
    public func pingTest() {

    }

    public init(manager: AdapterFactoryManager) {
        selectFactory = manager.selectFactory
        directFactory = manager.directFactory
    }

    private var selectFactory: SelectAdapterFactory?
    private var directFactory: DirectAdapterFactory?

}
