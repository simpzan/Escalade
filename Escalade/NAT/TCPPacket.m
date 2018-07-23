//
//  TCPPacket.m
//  PacketTunnel
//
//  Created by simpzan on 05/03/2018.
//  Copyright © 2018 simpzan. All rights reserved.
//

#import "TCPPacket.h"
#import "Utils.h"
#import "Checksum.h"

@interface TCPPacket() {
    NSMutableData *_data;
    uint8_t *_bytes;
}
@end

@implementation TCPPacket

- (instancetype)initWithData:(NSData *)data {
    if (self = [super init]) {
        _data = [data mutableCopy];
        _bytes = [_data mutableBytes];
        _protocol = *(_bytes + 9);
        _ipHeaderSize = (*_bytes & 0x0F) * 4;
    }
    return self;
}

- (uint16_t)sourcePort {
    return getPort(_bytes + _ipHeaderSize);
}
- (void)setSourcePort:(uint16_t)sourcePort {
    void *data = [_data mutableBytes] + _ipHeaderSize;
    setPort(data, sourcePort);
}

- (uint16_t)destinationPort {
    return getPort(_bytes + _ipHeaderSize + 2);
}
- (void)setDestinationPort:(uint16_t)destinationPort {
    void *data = [_data mutableBytes] + _ipHeaderSize + 2;
    setPort(data, destinationPort);
}

- (NSString *)sourceAddress {
    return getAddress(_bytes + 12);
}
- (void)setSourceAddress:(NSString *)sourceAddress {
    setAddress([_data mutableBytes] + 12, sourceAddress);
}

- (NSString *)destinationAddress {
    return getAddress(_bytes + 16);
}
- (void)setDestinationAddress:(NSString *)destinationAddress {
    setAddress([_data mutableBytes] + 16, destinationAddress);
}

- (NSData *)raw {
    computeChecksums(_bytes);
    return _data;
}

- (NSData *)udpData {
    uint64_t len = _data.length - _ipHeaderSize - 8;
    return [_data subdataWithRange:NSMakeRange(_ipHeaderSize + 8, len)];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%u -> %@:%u", self.sourceAddress, self.sourcePort, self.destinationAddress, self.destinationPort];
}

@end
