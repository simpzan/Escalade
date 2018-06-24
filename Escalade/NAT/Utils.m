//
//  Utils.m
//  PacketTunnel
//
//  Created by simpzan on 07/03/2018.
//  Copyright © 2018 simpzan. All rights reserved.
//

#import <ifaddrs.h>
#import <net/if.h>
#import <arpa/inet.h>
#import "Utils.h"
#import "Log.h"
#define NSLog(...) DDLogInfo(__VA_ARGS__);

static NSString *getIfName(NSString *ip) {
    struct ifaddrs *interfaces = NULL;
    NSInteger result = getifaddrs(&interfaces);
    if (result != 0) {
        NSLog(@"getifaddrs error, %s", strerror(errno));
        return NULL;
    }

    NSString *ifName = NULL;
    for (struct ifaddrs *itr = interfaces; itr; itr = itr->ifa_next) {
        if (itr->ifa_addr->sa_family != AF_INET) continue;

        NSString* ifaName = [NSString stringWithUTF8String:itr->ifa_name];
        NSString* address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) itr->ifa_addr)->sin_addr)];
//        NSString* mask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) itr->ifa_netmask)->sin_addr)];
//        NSString* gateway = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) itr->ifa_dstaddr)->sin_addr)];
//        NSLog(@"%@;%@;%@;%@",ifaName,address,mask,gateway);
        if ([address isEqualToString:ip]) {
            ifName = ifaName;
            break;
        }
    }
    freeifaddrs(interfaces);
    return ifName;
}
int boundInterface(int socket, NSString *address) {
    NSString *name = getIfName(address);
    if (!name) {
        return -1;
    }

    int ifIndex = if_nametoindex([name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (ifIndex == 0) {
        NSLog(@"if_nametoindex error, %s", strerror(errno));
        return -1;
    }

    int status = setsockopt(socket, IPPROTO_IP, IP_BOUND_IF, &ifIndex, sizeof(ifIndex));
    if (status == -1) {
        NSLog(@"setsockopt IP_BOUND_IF error, %s", strerror(errno));
        return -1;
    }
    NSLog(@"set IP_BOUND_IF ok");
    return 0;
}
NSString *getAddress(const void *data) {
    char str[128] = {0};
    const char *result = inet_ntop(AF_INET, data, str, sizeof(str));
    if (!result) {
        NSLog(@"inet_ntop failed, %s", strerror(errno));
        return nil;
    }
    return [NSString stringWithUTF8String:result];
}
void setAddress(void *data, NSString *address) {
    int result = inet_pton(AF_INET, [address UTF8String], data);
    if (result != 1) {
        NSLog(@"inet_pton(%@) failed , %s", address, strerror(errno));
    }
}

uint16_t getPort(const void *data) {
    uint16_t result = *(const uint16_t *)data;
    return ntohs(result);
}
void setPort(void *data, uint16_t port) {
    uint16_t *result = (uint16_t *)data;
    *result = htons(port);
}


void delay(double delayInSeconds, void(^callback)(void)){
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
}

NSString *getContainingAppId() {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleId = bundle.bundleIdentifier;
    if (bundle.infoDictionary[@"NSExtension"]) {
        bundleId = [bundleId stringByDeletingPathExtension];
    }
    return bundleId;
}

NSString *getSharedAppGroupId() {
    NSString *bundleId = getContainingAppId();
    return [@"group." stringByAppendingString:bundleId];
}

@implementation NSArray(Functional)
- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:block(obj, idx)];
    }];
    return result;
}
- (id)findFirstObjectUsingBlock:(BOOL (^)(id ojb, NSUInteger idx))predicate {
    __block id result = nil;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (predicate(obj, idx)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}
- (void)test{
    NSArray<NSNumber *> * a = @[@1, @2];
    [a findFirstObjectUsingBlock:^BOOL(id obj, NSUInteger idx) {
        return YES;
    }];
}
@end

@implementation NSData(Hex)
- (NSString*)hexRepresentation {
    BOOL spaces = YES;
    const unsigned char* bytes = (const unsigned char*)[self bytes];
    NSUInteger nbBytes = [self length];
    //If spaces is true, insert a space every this many input bytes (twice this many output characters).
    static const NSUInteger spaceEveryThisManyBytes = 4UL;
    //If spaces is true, insert a line-break instead of a space every this many spaces.
    static const NSUInteger lineBreakEveryThisManySpaces = 4UL;
    const NSUInteger lineBreakEveryThisManyBytes = spaceEveryThisManyBytes * lineBreakEveryThisManySpaces;
    NSUInteger strLen = 2*nbBytes + (spaces ? nbBytes/spaceEveryThisManyBytes : 0);

    NSMutableString* hex = [[NSMutableString alloc] initWithCapacity:strLen];
    for (NSUInteger i=0; i<nbBytes; ) {
        [hex appendFormat:@"%02X", bytes[i]];
        //We need to increment here so that the every-n-bytes computations are right.
        ++i;

        if (spaces) {
            if (i % lineBreakEveryThisManyBytes == 0) [hex appendString:@"\n"];
            else if (i % spaceEveryThisManyBytes == 0) [hex appendString:@" "];
        }
    }
    return hex;
}
@end


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
NSDictionary *getNetworkAddresses(void) {
    struct ifaddrs *interfaces = NULL;
    NSInteger success = getifaddrs(&interfaces);
    
    NSDictionary *result = NULL;
    if (success == 0) result = _networkAddresses(interfaces);
    else NSLog(@"ERROR: failed to getifaddrs: %d %s", errno, strerror(errno));
    
    freeifaddrs(interfaces);
    return result;
}

#import <mach/mach.h>

int64_t memoryUsage(void) {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (result != KERN_SUCCESS) {
        DDLogError(@"Error with task_info(): %s", mach_error_string(result));
        return 0;
    }
    return vmInfo.phys_footprint;
}

// http://stackoverflow.com/questions/8223348/ios-get-cpu-usage-from-application
double cpuUsage(void) {
    thread_array_t threads;
    mach_msg_type_number_t threadCount;
    kern_return_t result = task_threads(mach_task_self(), &threads, &threadCount);
    if (result != KERN_SUCCESS) {
        DDLogError(@"Error with task_threads(): %s", mach_error_string(result));
        return -1;
    }
    double usage = 0;
    for (int i = 0; i < threadCount; i++) {
        thread_info_data_t info;
        mach_msg_type_number_t infoCount = THREAD_INFO_MAX;
        result = thread_info(threads[i], THREAD_BASIC_INFO, (thread_info_t) info, &infoCount);
        if (result != KERN_SUCCESS) {
            DDLogError(@"Error with thread_info(): %s", mach_error_string(result));
            usage = -1;
            break;
        }
        thread_basic_info_t threadBasicInfo = (thread_basic_info_t) info;
        if ((threadBasicInfo->flags & TH_FLAGS_IDLE) == 0) {
            double threadUsage = threadBasicInfo->cpu_usage;
            usage += threadUsage / TH_USAGE_SCALE;
        }
    }
    vm_deallocate(mach_task_self(), (vm_offset_t) threads, threadCount * sizeof(thread_t));
    return usage * 100.0;
}

double systemCpuUsage(void) {
    static host_cpu_load_info_data_t previousInfo = {0, 0, 0, 0};

    host_cpu_load_info_data_t info;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&info, &count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    natural_t user   = info.cpu_ticks[CPU_STATE_USER] - previousInfo.cpu_ticks[CPU_STATE_USER];
    natural_t nice   = info.cpu_ticks[CPU_STATE_NICE] - previousInfo.cpu_ticks[CPU_STATE_NICE];
    natural_t system = info.cpu_ticks[CPU_STATE_SYSTEM] - previousInfo.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle   = info.cpu_ticks[CPU_STATE_IDLE] - previousInfo.cpu_ticks[CPU_STATE_IDLE];
    natural_t total  = user + nice + system + idle;
    previousInfo    = info;
    return (user + nice + system) * 100.0 / total;
}
