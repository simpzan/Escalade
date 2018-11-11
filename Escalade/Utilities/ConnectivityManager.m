//
//  ConnectivityManager.m
//  Escalade
//
//  Created by simpzan on 28/04/2018.
//

#import "ConnectivityManager.h"
#import "Utils.h"
#import "Log.h"

static char *networkTypeStrings[] = {"None", "Wifi", "Cellular"};
static NSString *_keyPath = @"defaultPath";

static NetworkType getCurrentNetworkType() {
    NSDictionary *addrs = getNetworkAddresses();
    if (addrs[@"en0"]) return Wifi;
    if (addrs[@"pdp_ip0"]) return Cellular;
    return None;
}

@implementation ConnectivityManager {
    NEProvider *_provider;
    NetworkChangedCallback _callback;
    NetworkType _type;
}

- (instancetype)initWithProvider:(NEProvider *)provider {
    if (self = [super init]) {
        _provider = provider;
        _type = getCurrentNetworkType();
    }
    return self;
}

- (void)listenNetworkChange:(NetworkChangedCallback)callback {
    [_provider addObserver:self forKeyPath:_keyPath options:NSKeyValueObservingOptionNew context:NULL];
    _callback = callback;
}

- (void)stopListening {
    [_provider removeObserver:self forKeyPath:_keyPath];
    _callback = NULL;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NetworkType newType = getCurrentNetworkType();
    DDLogDebug(@"defaultPath updated to %s", networkTypeStrings[newType]);
    if (newType == _type) return;
    
    NetworkType oldType = _type;
    _type = newType;
    _callback(oldType, newType);
}

@end
