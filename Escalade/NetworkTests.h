//
//  NetworkTests.h
//  Escalade
//
//  Created by simpzan on 26/04/2018.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>

@interface NetworkTests : NSObject

@end

void NSURLSessionHttpTest(NSString *dataUrl);
NSArray *dnsTest(NSString *domain);
void udpSend(NSString *addr, uint16_t port, NSString *message);

@interface GCDAsyncSocket(HttpTest) <GCDAsyncSocketDelegate>
+ (void)httpRequest:(NSString *)host :(uint16_t)port;
@end
