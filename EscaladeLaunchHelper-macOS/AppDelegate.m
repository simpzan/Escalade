//
//  AppDelegate.m
//  EscaladeLaunchHelper-macOS
//
//  Created by Samuel Zhang on 2/12/17.
//
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];

    NSString *bundleId = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
    NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleId];
    if (runningApps.count == 0) {
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
