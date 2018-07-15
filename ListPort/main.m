//
//  main.m
//  ListPort
//
//  Created by simpzan on 01/07/2018.
//

#import <Foundation/Foundation.h>
#include "ListPortProxy.h"
#include "ListPort.h"

typedef NSString *(*ListPortFunction)(uint32_t port, int *pid);

int listProcessUsingPort(const char *arg, ListPortFunction fn) {
    int port = atoi(arg);
    if (port <= 0) return -1;

    int pid = 0;
    NSString *program = fn(port, &pid);
    if (!program) {
        LOG_E("NotFound");
        return -1;
    }
    LOG_I("%d %s", pid, program.UTF8String);
    return 0;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) return ListPortServer();
        if (argc >= 3) return listProcessUsingPort(argv[2], &ListPortRPC);
        return listProcessUsingPort(argv[1], &ListPort);
    }
    return 0;
}
