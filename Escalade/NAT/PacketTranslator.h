//
//  PacketTranslator.h
//  Escalade
//
//  Created by simpzan on 22/04/2018.
//

#import <Foundation/Foundation.h>
#import <NEKit/NEKit-Swift.h>
#import "HostEndpoint.h"

@interface PacketTranslator : NSObject<IPStackProtocol>

- (instancetype)initWithInterfaceIp:(NSString *)interfaceIp fakeSourceIp:(NSString *)fakeSourceIp proxyServerIp:(NSString *)proxyServerIp port:(uint16_t)port;
+ (void)setInstance:(PacketTranslator *)instance;
+ (PacketTranslator *)getInstance;
- (HostEndpoint *)getOriginalEndpoint:(uint16_t)port;

@end

