//
//  main.m
//  Escalade
//
//  Created by Samuel Zhang on 3/13/17.
//
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

NSDictionary *_networkAddresses(struct ifaddrs *interfaces) {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:4];
    for (struct ifaddrs *addr = interfaces; addr != NULL; addr = addr->ifa_next) {
        if (addr->ifa_addr->sa_family == AF_INET) {
            NSString *name = [NSString stringWithUTF8String:addr->ifa_name];
            struct sockaddr_in *inAddr = (struct sockaddr_in *)addr->ifa_addr;
            NSString *address = [NSString stringWithUTF8String:inet_ntoa(inAddr->sin_addr)];
            [result setValue:address forKey:name];
        }
    }
    return result;
}
NSDictionary *getNetworkAddresses() {
    struct ifaddrs *interfaces = NULL;
    NSInteger success = getifaddrs(&interfaces);

    NSDictionary *result = NULL;
    if (success == 0) result = _networkAddresses(interfaces);
    else NSLog(@"ERROR: failed to getifaddrs: %d %s", errno, strerror(errno));

    freeifaddrs(interfaces);
    return result;
}
