//
//  File.swift
//  Escalade
//
//  Created by simpzan on 01/07/2018.
//

import Foundation

public class Historian {
    public static let shared = Historian()
    
    public var connections = [ConnectionRecord]()
    
    func record(tunnel: Tunnel) {
        guard let session = tunnel.proxySocket.session else { return }
        
        let remote = "\(session.host):\(session.port)"
        let local = ""
        let rule = session.matchedRule?.description ?? ""
    
        let record = ConnectionRecord(remoteEndpoint: remote, localEndpoint: local, matchedRule: rule, rx: tunnel.rx, tx: tunnel.tx, active: false)
        connections.append(record)
    }
    
}


public struct ConnectionRecord: Codable {
    public let remoteEndpoint: String
    public let localEndpoint: String
    public let matchedRule: String
    public let rx: Int
    public let tx: Int
    public let active: Bool
}
