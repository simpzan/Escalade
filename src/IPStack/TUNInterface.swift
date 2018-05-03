import Foundation
import NetworkExtension
import CocoaLumberjackSwift

/// TUN interface provide a scheme to register a set of IP Stacks (implementing `IPStackProtocol`) to process IP packets from a virtual TUN interface.
open class TUNInterface {
    fileprivate weak var packetFlow: NEPacketTunnelFlow?
    fileprivate var stacks: [IPStackProtocol] = []
    
    /**
     Initialize TUN interface with a packet flow.
     
     - parameter packetFlow: The packet flow to work with.
     */
    public init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }

    private var running = false
    /**
     Start processing packets, this should be called after registering all IP stacks.
     
     A stopped interface should never start again. Create a new interface instead.
     */
    open func start() {
        QueueFactory.executeOnQueueSynchronizedly {
            self.running = true
            for stack in self.stacks {
                stack.start()
            }
            
            self.readPackets()
        }
    }
    
    /**
     Stop processing packets, this should be called before releasing the interface.
     */
    open func stop() {
        QueueFactory.executeOnQueueSynchronizedly {
            self.running = false
            
            for stack in self.stacks {
                stack.stop()
            }
            self.stacks = []
        }
    }

    /**
     Register a new IP stack.
     
     When a packet is read from TUN interface (the packet flow), it is passed into each IP stack according to the registration order until one of them takes it in.
     
     - parameter stack: The IP stack to append to the stack list.
     */
    open func register(stack: IPStackProtocol) {
        QueueFactory.executeOnQueueSynchronizedly {
            stack.outputFunc = self.generateOutputBlock()
            self.stacks.append(stack)
        }
    }
    
    fileprivate func readPackets() {
        packetFlow?.readPackets { packets, versions in
            QueueFactory.getQueue().async {
                for (i, packet) in packets.enumerated() {
                    let stack = self.stacks.first { $0.input(packet: packet, version: versions[i]) }
                    if let s = stack { DDLogVerbose("packet \(packet) found processor \(s)") }
                    else { DDLogError("packet \(packet) not processed!") }
                }
            }
            
            if self.running { self.readPackets() }
        }
    }
    
    fileprivate func generateOutputBlock() -> ([Data], [NSNumber]) -> Void {
        return { [weak self] packets, versions in
            if let this = self, this.running {
                this.packetFlow?.writePackets(packets, withProtocols: versions)
            }
        }
    }
}
