//
//  AEAD.h
//  NEKit
//
//  Created by simpzan on 2018/10/27.
//  Copyright © 2018 Zhuhao Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AEADAlgorithm) {
    AEAD_CHACHA20IETFPOLY1305,
    AEAD_AES256GCM,
};

@interface AEAD : NSObject
- (instancetype)initWithMasterKey:(NSData *)key :(NSData *)salt :(AEADAlgorithm)algorithm;
- (NSData *)encrypted:(NSData *)plainData;
- (NSData *)decrypted:(NSData *)cipherData;
@end

NS_ASSUME_NONNULL_END
