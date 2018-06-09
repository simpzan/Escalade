import Foundation

public enum ProxySocketEvent: EventType {
    public var description: String {
        switch self {
        case .socketOpened(let socket):
            return "\(socket), Start processing data."
        case .disconnectCalled(let socket):
            return "\(socket), Disconnect is just called."
        case .forceDisconnectCalled(let socket):
            return "\(socket), Force disconnect is just called."
        case .disconnected(let socket):
            return "\(socket) disconnected."
        case let .receivedRequest(session, on: socket):
            return "\(socket) received request \(session)."
        case let .readData(data, on: socket):
            return "\(socket), Received \(data.count) bytes data."
        case let .wroteData(data, on: socket):
            if let data = data {
                return "\(socket), Sent \(data.count) bytes data."
            } else {
                return "\(socket), Sent data."
            }
        case let .askedToResponseTo(adapter, on: socket):
            return "\(socket) is asked to respond to adapter \(adapter)."
        case .readyForForward(let socket):
            return "\(socket) is ready to forward data."
        case let .errorOccured(error, on: socket):
            return "\(socket) encountered an error \(error)."
        }
    }

    case socketOpened(ProxySocket),
    disconnectCalled(ProxySocket),
    forceDisconnectCalled(ProxySocket),
    disconnected(ProxySocket),
    receivedRequest(ConnectSession, on: ProxySocket),
    readData(Data, on: ProxySocket),
    wroteData(Data?, on: ProxySocket),
    askedToResponseTo(AdapterSocket, on: ProxySocket),
    readyForForward(ProxySocket),
    errorOccured(Error, on: ProxySocket)
}
