//
//  NetworkTests.m
//  Escalade
//
//  Created by simpzan on 26/04/2018.
//

#import "NetworkTests.h"

@implementation NetworkTests

@end


void httpTest(NSString *dataUrl) {
    NSURL *url = [NSURL URLWithString:dataUrl];
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
                                              NSLog(@"response %ld, %d", (long)res.statusCode, (int)data.length);
                                          }];
    [downloadTask resume];
}


GCDAsyncSocket *sock;

@implementation GCDAsyncSocket(HttpTest)

+ (void)httpRequest:(NSString *)host :(uint16_t)port {
    sock = [[GCDAsyncSocket alloc]init];
    [sock setDelegate:sock delegateQueue:dispatch_get_main_queue()];
    NSError *err;
    BOOL result = [sock connectToHost:host onPort:port error:&err];
    if (!result) {
        NSLog(@"http request error, %@", err);
        return;
    }
    const char *requstHeader = "GET / HTTP/1.1\r\nConnection: close\r\n\r\n";
    NSData *data = [[NSData alloc] initWithBytes:requstHeader length:strlen(requstHeader)];
    [sock writeData:data withTimeout:-1 tag:55];
    [sock readDataWithTimeout:-1 tag:56];
    NSLog(@"%s %@", __FUNCTION__, host);
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%s %@", __FUNCTION__, host);
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s %ld", __FUNCTION__, tag);
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%s %@", __FUNCTION__, str);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"%s %@", __FUNCTION__, err);
    sock = nil;
}

@end
