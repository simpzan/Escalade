//
//  HostEndpoint.m
//  Escalade
//
//  Created by simpzan on 22/04/2018.
//

#import "HostEndpoint.h"

@implementation HostEndpoint

- (instancetype)initWithHostname:(NSString *)name port:(uint16_t)port {
    self = [super init];
    _hostname = name;
    _port = port;
    return self;
}

+ (instancetype)endpointWithHostname:(NSString *)name port:(uint16_t)port {
    return [[HostEndpoint alloc]initWithHostname:name port:port];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%u", _hostname, _port];
}

@end
