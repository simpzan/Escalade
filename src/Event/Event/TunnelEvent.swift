import Foundation

public enum TunnelEvent: EventType {
    public var description: String {
        switch self {
        case .opened(let tunnel):
            return "\(tunnel) starts processing data."
        case .closeCalled(let tunnel):
            return "\(tunnel), Close is called."
        case .forceCloseCalled(let tunnel):
            return "\(tunnel), Force close is called."
        case let .receivedRequest(request, from: _, on: tunnel):
            return "\(tunnel) received request \(request)."
        case let .receivedReadySignal(socket, currentReady: signal, on: tunnel):
            if signal == 1 {
                return "\(tunnel) received ready-for-forward signal from \(socket)."
            } else {
                return "\(tunnel) received ready-for-forward signal from \(socket). Start forwarding data."
            }
        case let .proxySocketReadData(data, from: socket, on: tunnel):
            return "\(tunnel) received \(data.count) bytes from \(socket)."
        case let .proxySocketWroteData(data, by: socket, on: tunnel):
            if let data = data {
                return "\(tunnel), \(socket) sent \(data.count) bytes data."
            } else {
                return "\(tunnel), \(socket) sent data."
            }
        case let .adapterSocketReadData(data, from: socket, on: tunnel):
            return "\(tunnel) received \(data.count) bytes from \(socket)."
        case let .adapterSocketWroteData(data, by: socket, on: tunnel):
            if let data = data {
                return "\(tunnel), \(socket) sent \(data.count) bytes data."
            } else {
                return "\(tunnel), \(socket) sent data."
            }
        case let .connectedToRemote(socket, on: tunnel):
            return "\(tunnel), \(socket) connected to remote successfully."
        case let .updatingAdapterSocket(from: old, to: new, on: tunnel):
            return "\(tunnel), Updating adapter socket from \(old) to \(new)."
        case .closed(let tunnel):
            return "\(tunnel) closed."
        }
    }

    case opened(Tunnel),
    closeCalled(Tunnel),
    forceCloseCalled(Tunnel),
    receivedRequest(ConnectSession, from: ProxySocket, on: Tunnel),
    receivedReadySignal(SocketProtocol, currentReady: Int, on: Tunnel),
    proxySocketReadData(Data, from: ProxySocket, on: Tunnel),
    proxySocketWroteData(Data?, by: ProxySocket, on: Tunnel),
    adapterSocketReadData(Data, from: AdapterSocket, on: Tunnel),
    adapterSocketWroteData(Data?, by: AdapterSocket, on: Tunnel),
    connectedToRemote(AdapterSocket, on: Tunnel),
    updatingAdapterSocket(from: AdapterSocket, to: AdapterSocket, on: Tunnel),
    closed(Tunnel)
}
