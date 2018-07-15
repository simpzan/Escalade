//
//  ListPortProxy.h
//  Escalade
//
//  Created by simpzan on 07/07/2018.
//

#import <Foundation/Foundation.h>

NSString *ListPortRPC(uint32_t port, int *processId);

#ifdef LISTPORT
int ListPortServer(void);
#endif
