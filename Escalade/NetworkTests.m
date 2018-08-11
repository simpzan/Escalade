//
//  NetworkTests.m
//  Escalade
//
//  Created by simpzan on 26/04/2018.
//

#import "NetworkTests.h"

@implementation NetworkTests

@end

#include <netdb.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

typedef struct sockaddr sockaddr;
static inline void setSocketTimeout(int socket, int seconds) {
    struct timeval tv;
    tv.tv_sec = seconds;
    tv.tv_usec = 0;
    int result = setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    if (result < 0) {
        NSLog(@"setsockopt receive timeout to %ds failed, %d %s", seconds, errno, strerror(errno));
    }
    result = setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    if (result < 0) {
        NSLog(@"setsockopt send timeout to %d failed, %d %s", seconds, errno, strerror(errno));
    }
}
static inline NSString *_udpSend(int socket, sockaddr *addr, NSString *msg) {
    socklen_t addrSize = sizeof(sockaddr);
    ssize_t result = sendto(socket, msg.UTF8String, msg.length, 0, addr, addrSize);
    if (result < 0) {
        NSLog(@"sendto() failed, %s", strerror(errno));
        return NULL;
    }
    char tmp[1024] = {0};
    result = recvfrom(socket, tmp, sizeof(tmp), 0, addr, &addrSize);
    if (result < 0) NSLog(@"recvfrom error, %d %s", errno, strerror(errno));
    return [NSString stringWithUTF8String:tmp];
}
NSString *udpSend(NSString *addr, uint16_t port, NSString *message) {
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
        NSLog(@"socket()");
        return NULL;
    }
    setSocketTimeout(s, 3);
    struct sockaddr_in server;
    server.sin_family      = AF_INET;
    server.sin_port        = htons(port);
    server.sin_addr.s_addr = inet_addr(addr.UTF8String);
    NSString *result = _udpSend(s, (sockaddr *)&server, message);
    close(s);
    NSLog(@"sent '%@', received '%@'.", message, result);
    return result;
}

#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

#ifndef   NI_MAXHOST
#define   NI_MAXHOST 1025
#endif

NSArray *dnsTest(NSString *aDomain) {
    const char *domain = [aDomain cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *ips = [NSMutableArray array];
    struct addrinfo *result;
    int error = getaddrinfo(domain, NULL, NULL, &result);
    if (error != 0) {
        NSLog(@"error in getaddrinfo: %s\n", gai_strerror(error));
        return ips;
    }
    
    for (struct addrinfo *res = result; res != NULL; res = res->ai_next) {
        char hostname[NI_MAXHOST] = "";
        
        error = getnameinfo(res->ai_addr, res->ai_addrlen, hostname, NI_MAXHOST, NULL, 0, 0);
        if (error != 0) {
            NSLog(@"error in getnameinfo: %s\n", gai_strerror(error));
            continue;
        }
        if (*hostname != '\0') {
            NSString *ip = [NSString stringWithUTF8String:hostname];
            [ips addObject:ip];
        }
    }
    freeaddrinfo(result);
    return ips;
}


void NSURLSessionHttpTest(NSString *dataUrl) {
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
