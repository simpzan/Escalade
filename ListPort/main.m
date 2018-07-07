//
//  main.m
//  ListPort
//
//  Created by simpzan on 01/07/2018.
//

#import <Foundation/Foundation.h>
#include "ListPort.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int port = -1;
        if (argc >= 2) {
            port = atoi(argv[1]);
        } else {
            scanf ("%d", &port);
        }
        if (port <= 0) return -1;
        
        int pid = 0;
        NSString *program = ListPort(port, &pid);
        if (!program) {
            LOG_E("NotFound");
            return -1;
        }
        LOG_I("%d %s", pid, program.UTF8String);
    }
    return 0;
}
