//
//  AEAD.m
//  NEKit
//
//  Created by simpzan on 2018/10/27.
//  Copyright © 2018 Zhuhao Wang. All rights reserved.
//

#import "AEAD.h"
#import <Sodium/Sodium.h>
#import <CommonCrypto/CommonCrypto.h>

static NSData *generateSubkey(NSData *masterKey, NSData *salt, const char *info) {
    NSMutableData *prk = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, salt.bytes, salt.length, masterKey.bytes, masterKey.length, prk.mutableBytes);
    
    NSMutableData *subkey = [NSMutableData data];
    NSUInteger length = 32;
    int count = (int)ceil(length / (float)CC_SHA1_DIGEST_LENGTH);

    NSMutableData *mixin = [NSMutableData data];
    for (uint8_t i=1; i<=count; ++i) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA1, prk.bytes, prk.length);

        CCHmacUpdate(&ctx, mixin.bytes, mixin.length);
        CCHmacUpdate(&ctx, info, strlen(info));
        CCHmacUpdate(&ctx, &i, 1);
        
        if (mixin.length == 0) [mixin increaseLengthBy:CC_SHA1_DIGEST_LENGTH];
        CCHmacFinal(&ctx, mixin.mutableBytes);
        [subkey appendData:mixin];
    }
    return [subkey subdataWithRange:NSMakeRange(0, length)];
}

int tag_len = 16;
int chunk_size_len = 2;

@implementation AEAD {
    NSData *subkey;
    NSMutableData *nonce;
    NSMutableData *buffer;
}
- (instancetype)initWithMasterKey:(NSData *)key :(NSData *)salt {
    self = [super init];
    const char *info = "ss-subkey";
    subkey = generateSubkey(key, salt, info);
    nonce = [NSMutableData dataWithLength:12];
    buffer = [NSMutableData data];
    return self;
}
- (NSData *)encrypted:(NSData *)plainData {
    int cipherLength = tag_len * 2 + plainData.length + chunk_size_len;
    NSMutableData *cipherData = [NSMutableData dataWithLength:cipherLength];
    uint8_t *cipher = cipherData.mutableBytes;
    
    uint16_t len = htons(plainData.length);
    unsigned long long actualLength = 0;
    int err = crypto_aead_chacha20poly1305_ietf_encrypt(cipher, &actualLength, &len, chunk_size_len, NULL, 0, NULL, nonce.bytes, subkey.bytes);
    assert(err == 0);
    assert(actualLength == chunk_size_len + tag_len);
    sodium_increment(nonce.mutableBytes, nonce.length);

    cipher += actualLength;
    err = crypto_aead_chacha20poly1305_ietf_encrypt(cipher, &actualLength, plainData.bytes, plainData.length, NULL, 0, NULL, nonce.bytes, subkey.bytes);
    assert(err == 0);
    assert(actualLength == plainData.length + tag_len);
    sodium_increment(nonce.mutableBytes, nonce.length);
    
    return cipherData;
}
- (int)_decrypted:(NSData *)cipherData :(NSMutableData *)outputData {
    if (cipherData.length <= tag_len * 2 + chunk_size_len) return 0;

    const void *cipher = cipherData.bytes;
    uint16_t len = 0;
    unsigned long long actualLength = 0;
    int cipherLen = chunk_size_len + tag_len;
    int err = crypto_aead_chacha20poly1305_ietf_decrypt(&len, &actualLength, NULL, cipher, cipherLen, NULL, 0, nonce.bytes, subkey.bytes);
    assert(err == 0);
    assert(actualLength == chunk_size_len);
    len = ntohs(len);
    assert(len > 0);
    
    int chunkLength = 2 * tag_len + chunk_size_len + len;
    if (cipherData.length < chunkLength) return 0;

    sodium_increment(nonce.mutableBytes, nonce.length);

    cipher += tag_len + chunk_size_len;
    NSMutableData *plainData = [NSMutableData dataWithLength:len];
    err = crypto_aead_chacha20poly1305_ietf_decrypt(plainData.mutableBytes, &actualLength, NULL, cipher, len + tag_len, NULL, 0, nonce.bytes, subkey.bytes);
    assert(err == 0);
    assert(actualLength == len);
    sodium_increment(nonce.mutableBytes, nonce.length);

    [outputData appendData:plainData];
    return chunkLength;
}
- (NSData *)decrypted:(NSData *)cipherData {
    [buffer appendData:cipherData];
    NSMutableData *plainData = [NSMutableData dataWithCapacity:buffer.length];
    while (true) {
        int result = [self _decrypted:buffer :plainData];
        if (result <= 0) break;
        
        NSUInteger len = buffer.length;
        assert(result <= (int)len);
        len -= (NSUInteger)result;
        buffer = [NSMutableData dataWithBytes:buffer.bytes + result length:len];
    }
    return plainData;
}
@end
