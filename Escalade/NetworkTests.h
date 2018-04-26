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

void httpTest(NSString *dataUrl);

@interface GCDAsyncSocket(HttpTest) <GCDAsyncSocketDelegate>
+ (void)httpRequest:(NSString *)host :(uint16_t)port;
@end
