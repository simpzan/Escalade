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

void udpSend(NSString *addr, uint16_t port, NSString *message) {
    const char *address = [addr cStringUsingEncoding:NSUTF8StringEncoding];
    const char *msg = [message cStringUsingEncoding:NSUTF8StringEncoding];
    int s;
    struct sockaddr_in server;
    
    /* Create a datagram socket in the internet domain and use the
     * default protocol (UDP).
     */
    if ((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        NSLog(@"socket()");
        return;
    }
    
    /* Set up the server name */
    server.sin_family      = AF_INET;            /* Internet Domain    */
    server.sin_port        = htons(port);               /* Server Port        */
    server.sin_addr.s_addr = inet_addr(address); /* Server's Address   */
    
    /* Send the message in buf to the server */
    if (sendto(s, msg, (strlen(msg)+1), 0,
               (struct sockaddr *)&server, sizeof(server)) < 0) {
        NSLog(@"sendto()");
        return;
    }
    
    /* Deallocate the socket */
    close(s);
    NSLog(@"udpSend %s:%d, %s", address, port, msg);
}

#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

#ifndef   NI_MAXHOST
#define   NI_MAXHOST 1025
#endif

void dnsTest(NSString *aDomain) {
    const char *domain = [aDomain cStringUsingEncoding:NSUTF8StringEncoding];
    struct addrinfo *result;
    struct addrinfo *res;
    int error;
    
    /* resolve the domain name into a list of addresses */
    error = getaddrinfo(domain, NULL, NULL, &result);
    if (error != 0) {
        NSLog(@"error in getaddrinfo: %s\n", gai_strerror(error));
        return;
    }
    
    /* loop over all returned results and do inverse lookup */
    for (res = result; res != NULL; res = res->ai_next) {
        char hostname[NI_MAXHOST] = "";
        
        error = getnameinfo(res->ai_addr, res->ai_addrlen, hostname, NI_MAXHOST, NULL, 0, 0);
        if (error != 0) {
            NSLog(@"error in getnameinfo: %s\n", gai_strerror(error));
            continue;
        }
        if (*hostname != '\0')
            NSLog(@"hostname: %s\n", hostname);
    }
    
    freeaddrinfo(result);
    return;
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
