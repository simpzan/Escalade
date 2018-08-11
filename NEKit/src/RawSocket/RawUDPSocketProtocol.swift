//
//  RawUDPSocketProtocol.swift
//  NEKit
//
//  Created by simpzan on 2018/8/11.
//  Copyright © 2018 Zhuhao Wang. All rights reserved.
//

import Foundation

public protocol RawUDPSocketProtocol: class {

    /// The delegate instance.
    var delegate: RawUDPSocketDelegate? { get set }

    var timeout: Int { get set }
    
    func bindEndpoint(_ host: String, _ port: UInt16) -> Bool

    /**
     Send data to remote.
     
     - parameter data: The data to send.
     */
    func write(data: Data)
    
    func disconnect()
}

public protocol RawUDPSocketDelegate: class {
    /**
     Socket did receive data from remote.
     
     - parameter data: The data.
     - parameter from: The socket the data is read from.
     */
    func didReceive(data: Data, from: RawUDPSocketProtocol)
    
    func didCancel(socket: RawUDPSocketProtocol)
}
