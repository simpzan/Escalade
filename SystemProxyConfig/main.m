//
//  main.m
//  SystemProxyConfig
//
//  Created by Samuel Zhang on 2/10/17.
//
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSDictionary *getProxySetting(int port, int enabled) {
    NSNumber *enabledNumber = [NSNumber numberWithInt:enabled];
    NSString *host = @"127.0.0.1";
    NSNumber *socksPortNumber = [NSNumber numberWithInt:port];
    NSNumber *httpPortNumber = [NSNumber numberWithInt:port + 1];
    NSArray *exceptions = @[
                            @"10.0.0.0/8",
                            @"172.16.0.0/12",
                            @"192.168.0.0/16",
                            @"127.0.0.1",
                            @"localhost",
                            @"*.local"
                            ];

    NSMutableDictionary *setting = [[NSMutableDictionary alloc] init];

    [setting setObject:enabledNumber forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
    [setting setObject:host forKey:(NSString *)kCFNetworkProxiesHTTPProxy];
    [setting setObject:httpPortNumber forKey:(NSString*)kCFNetworkProxiesHTTPPort];

    [setting setObject:enabledNumber forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
    [setting setObject:host forKey:(NSString *)kCFNetworkProxiesHTTPSProxy];
    [setting setObject:httpPortNumber forKey:(NSString*)kCFNetworkProxiesHTTPSPort];

    [setting setObject:enabledNumber forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
    [setting setObject:host forKey:(NSString *)kCFNetworkProxiesSOCKSProxy];
    [setting setObject:socksPortNumber forKey:(NSString*)kCFNetworkProxiesSOCKSPort];

    [setting setObject:exceptions forKey:(NSString*)kCFNetworkProxiesExceptionsList];

    return setting;
}

void setProxyForInterfaces(int port, int enabled, SCPreferencesRef prefRef) {
    NSArray *validInterfaces = @[@"AirPort", @"Wi-Fi", @"Ethernet"];
    NSDictionary *networks = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    for (NSString *name in [networks allKeys]) {
        NSDictionary *props = [networks objectForKey:name];
        NSString *hardware = [props valueForKeyPath:@"Interface.Hardware"];
        if (![validInterfaces containsObject:hardware]) continue;

        NSDictionary *setting = getProxySetting(port, enabled);
        NSString* path = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, name, kSCEntNetProxies];
        SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)path, (__bridge CFDictionaryRef)setting);
    }
}

int setSystemProxy(int port, int enabled) {
    AuthorizationFlags authFlags = kAuthorizationFlagExtendRights
    | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
    AuthorizationRef authRef;
    OSStatus authErr = AuthorizationCreate(nil, nil, authFlags, &authRef);
    if (authErr != noErr) return 1;

    if (authRef == NULL) return 2;

    SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("SpechtLite"), nil, authRef);
    setProxyForInterfaces(port, enabled, prefRef);
    SCPreferencesCommitChanges(prefRef);
    SCPreferencesApplyChanges(prefRef);

    AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    return 0;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc == 2 && !strcmp(argv[1], "version")) {
            const char *version = "0.1.0";
            printf("%s\n", version);
        } else if (argc == 3) {
            const char *portString = argv[1];
            const char *state = argv[2];
            int port = atoi(portString);
            int enabled = !strcmp("enable", state) ? 1 : 0;
            int result = setSystemProxy(port, enabled);
            printf("setSystemProxy %s %s, result %d\n", portString, state, result);
        } else {
            printf("Usage: ProxyConfig <port> <enable/disable>\n");
        }
    }
    return 0;
}
