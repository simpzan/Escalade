import Foundation

class QueueFactory {
    private static let queueKey = DispatchSpecificKey<String>()

    static let queue: DispatchQueue = {
        let q = DispatchQueue(label: "NEKit.ProcessingQueue")
        q.setSpecific(key: QueueFactory.queueKey, value: "NEKit.ProcessingQueue")
        return q
    }()

    static func getQueue() -> DispatchQueue {
        return QueueFactory.queue
    }

    static func onQueue() -> Bool {
        return DispatchQueue.getSpecific(key: QueueFactory.queueKey) == "NEKit.ProcessingQueue"
    }

    static func executeOnQueueSynchronizedly<T>(block: () throws -> T ) rethrows -> T {
        if onQueue() {
            return try block()
        } else {
            return try getQueue().sync {
                return try block()
            }
        }
    }
    
    static func delay(_ delay: Double, closure: @escaping () -> Void) {
        let time = delay > 0 ? delay : 0;
        getQueue().asyncAfter(deadline: .now() + time, execute: closure)
    }
}
