//
//  ListPort.h
//  ListPort
//
//  Created by simpzan on 01/07/2018.
//

#import <Foundation/Foundation.h>

#define LOG_I(format, args...) printf(format "\n", ##args)
#define LOG_E(format, args...) printf(format "\n", ##args)
#define ERRNO(format, args...) printf(format " failed, %s\n", ##args, strerror(errno))

NSString *ListPort(uint32_t port, int *processId);
