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
//        let record = ConnectionRecord(tunnel: tunnel)
//        connections.append(record)
    }
    
}


public struct ConnectionRecord: Codable {
    public let remoteEndpoint: String
    public let localEndpoint: String
    public let matchedRule: String
    public let rx: Int
    public let tx: Int
    public var active: Bool {
        return closedTime == nil
    }
    public let createdTime: Date
    public let closedTime: Date?
    public let pid: Int?
    public let program: String?
    public let userAgent: String?
    
    init(tunnel: Tunnel) {
        let session = tunnel.proxySocket.session
        remoteEndpoint = session != nil ? session!.endpoint : ""
        localEndpoint = ""
        matchedRule = session?.matchedRule?.description ?? ""
        
        rx = tunnel.rx
        tx = tunnel.tx
        createdTime = tunnel.createdTime
        closedTime = tunnel.closedTime
        pid = tunnel.clientPid
        program = tunnel.clientProgram
        userAgent = tunnel.userAgent
    }
}
