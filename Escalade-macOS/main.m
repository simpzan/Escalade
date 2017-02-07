//
//  main.m
//  Escalade
//
//  Created by Samuel Zhang on 2/7/17.
//
//

#import <Foundation/Foundation.h>

// From here to end of file added by Injection Plugin //

#ifdef DEBUG
#define INJECTION_PORT 31452
static char _inMainFilePath[] = __FILE__;
static const char *_inIPAddresses[] = {"10.126.52.103", "127.0.0.1", 0};

#define INJECTION_ENABLED
#import "/tmp/injectionforxcode/BundleInjection.h"
#endif
