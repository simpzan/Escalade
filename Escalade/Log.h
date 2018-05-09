//
//  Log.h
//  CocoaLumberjack
//
//  Created by simpzan on 25/04/2018.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;
int setupLog(DDLogLevel level, NSString *logDir);
NSString *getLogFilePath(void);
