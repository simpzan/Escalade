//
//  ConnectivityManager.h
//  Escalade
//
//  Created by simpzan on 28/04/2018.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>


typedef NS_ENUM(NSInteger, NetworkType) {
    None,
    Wifi,
    Cellular,
};


@interface ConnectivityManager : NSObject

- (instancetype)initWithProvider:(NEProvider *)provider;

typedef void (^NetworkChangedCallback)(NetworkType from, NetworkType to);
- (void)listenNetworkChange:(NetworkChangedCallback)callback;
- (void)stopListening;

@end
