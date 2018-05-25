//
//  Utils.h
//  PacketTunnel
//
//  Created by simpzan on 07/03/2018.
//  Copyright © 2018 simpzan. All rights reserved.
//

#import <Foundation/Foundation.h>

int boundInterface(int socket, NSString *address);

NSString *getAddress(const void *data);
void setAddress(void *data, NSString *address);

uint16_t getPort(const void *data);
void setPort(void *data, uint16_t port);

void delay(double delayInSeconds, void(^callback)(void));

NSString *getContainingAppId(void);
NSString *getSharedAppGroupId(void);

@interface NSArray(Functional)
- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block;
- (id)findFirstObjectUsingBlock:(BOOL (^)(id obj, NSUInteger idx))predicate;
@end


@interface NSData(Hex)
- (NSString*)hexRepresentation;
@end

NSDictionary *getNetworkAddresses(void);

int64_t memoryUsage(void);
double cpuUsage(void);
