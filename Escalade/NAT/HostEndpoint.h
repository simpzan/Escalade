//
//  HostEndpoint.h
//  Escalade
//
//  Created by simpzan on 22/04/2018.
//

#import <Foundation/Foundation.h>

@interface HostEndpoint : NSObject

+ (instancetype)endpointWithHostname:(NSString *)name port:(uint16_t)port;

@property(readonly) NSString *hostname;
@property(readonly) uint16_t port;

@end
