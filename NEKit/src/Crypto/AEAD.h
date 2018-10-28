//
//  AEAD.h
//  NEKit
//
//  Created by simpzan on 2018/10/27.
//  Copyright © 2018 Zhuhao Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AEAD : NSObject
- (instancetype)initWithMasterKey:(NSData *)key :(NSData *)salt;
- (NSData *)encrypted:(NSData *)plainData;
- (NSData *)decrypted:(NSData *)cipherData;
@end

NS_ASSUME_NONNULL_END
