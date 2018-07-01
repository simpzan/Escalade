//
//  main.m
//  ListPort
//
//  Created by simpzan on 01/07/2018.
//

#import <Foundation/Foundation.h>
#include "listPort.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) return -1;
        int port = atoi(argv[1]);
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
