import Foundation

public enum ProxyServerEvent: EventType {
    public var description: String {
        switch self {
        case let .newSocketAccepted(socket, onServer: server):
            return "\(server) just accepted a new socket \(socket)."
        case let .tunnelClosed(tunnel, onServer: server):
            return "\(server), \(tunnel) just closed."
        case .started(let server):
            return "\(server) started."
        case .stopped(let server):
            return "\(server) stopped."
        }
    }

    case newSocketAccepted(ProxySocket, onServer: ProxyServer), tunnelClosed(Tunnel, onServer: ProxyServer), started(ProxyServer), stopped(ProxyServer)
}
