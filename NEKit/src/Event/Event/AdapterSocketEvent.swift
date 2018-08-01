import Foundation

public enum AdapterSocketEvent: EventType {
    public var description: String {
        switch self {
        case let .socketOpened(socket, withSession: session):
            return "\(socket) starts to connect to remote with session \(session)."
        case .disconnectCalled(let socket):
            return "\(socket), Disconnect is just called."
        case .forceDisconnectCalled(let socket):
            return "\(socket), Force disconnect is just called."
        case .disconnected(let socket):
            return "\(socket) disconnected."
        case let .readData(data, on: socket):
            return "\(socket), Received \(data.count) bytes data."
        case let .wroteData(data, on: socket):
            if let data = data {
                return "\(socket), Sent \(data.count) bytes data."
            } else {
                return "\(socket), Sent data."
            }
        case let .connected(socket):
            return "\(socket) connected to remote."
        case .readyForForward(let socket):
            return "\(socket) is ready to forward data."
        case let .errorOccured(error, on: socket):
            return "\(socket) encountered an error \(error)."
        }
    }

    case socketOpened(AdapterSocket, withSession: ConnectSession),
    disconnectCalled(AdapterSocket),
    forceDisconnectCalled(AdapterSocket),
    disconnected(AdapterSocket),
    readData(Data, on: AdapterSocket),
    wroteData(Data?, on: AdapterSocket),
    connected(AdapterSocket),
    readyForForward(AdapterSocket),
    errorOccured(Error, on: AdapterSocket)
}
