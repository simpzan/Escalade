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

@interface Hmac : NSObject
- (instancetype)initWithAlgorithm:(CCHmacAlgorithm)algorithm key:(NSData *)key;
- (instancetype)update:(NSData *)data;
- (instancetype)updateWithBytes:(const uint8_t *)bytes length:(size_t)len;
- (NSData *)final;
+ (NSData *)generateWithAgorithm:(CCHmacAlgorithm)algorithm key:(NSData *)key data:(NSData *)data;
@end

@implementation Hmac {
    CCHmacContext _ctx;
    CCHmacAlgorithm _algorithm;
}
- (instancetype)initWithAlgorithm:(CCHmacAlgorithm)algorithm key:(NSData *)key {
    self = [super init];
    CCHmacInit(&_ctx, algorithm, key.bytes, key.length);
    _algorithm = algorithm;
    return self;
}
- (instancetype)update:(NSData *)data {
    CCHmacUpdate(&_ctx, data.bytes, data.length);
    return self;
}
- (instancetype)updateWithBytes:(const uint8_t *)bytes length:(size_t)len {
    CCHmacUpdate(&_ctx, bytes, len);
    return self;
}
- (NSData *)final {
    NSDictionary *lengths = @{
        @(kCCHmacAlgSHA1):   @(CC_SHA1_DIGEST_LENGTH),
        @(kCCHmacAlgMD5):    @(CC_MD5_DIGEST_LENGTH),
        @(kCCHmacAlgSHA256): @(CC_SHA256_DIGEST_LENGTH),
        @(kCCHmacAlgSHA384): @(CC_SHA384_DIGEST_LENGTH),
        @(kCCHmacAlgSHA512): @(CC_SHA512_DIGEST_LENGTH),
        @(kCCHmacAlgSHA224): @(CC_SHA224_DIGEST_LENGTH)
    };
    NSUInteger len = [lengths[@(_algorithm)] unsignedIntegerValue];
    NSMutableData *result = [NSMutableData dataWithLength:len];
    CCHmacFinal(&_ctx, result.mutableBytes);
    return result;
}
+ (NSData *)generateWithAgorithm:(CCHmacAlgorithm)algorithm key:(NSData *)key data:(NSData *)data {
    Hmac *mac = [[Hmac alloc]initWithAlgorithm:algorithm key:key];
    return [[mac update:data] final];
}
@end

static NSData *generateSubkey(NSData *masterKey, NSData *salt, NSData *info) {
    NSData *prk = [Hmac generateWithAgorithm:kCCHmacAlgSHA1 key:salt data:masterKey];
    
    NSMutableData *subkey = [NSMutableData data];
    NSUInteger length = 32;
    int count = (int)ceil(length / (float)CC_SHA1_DIGEST_LENGTH);

    NSData *mixin = [NSData data];
    for (uint8_t i=1; i<=count; ++i) {
        Hmac *mac = [[Hmac alloc]initWithAlgorithm:kCCHmacAlgSHA1 key:prk];
        [mac update:mixin];
        [mac update:info];
        [mac updateWithBytes:&i length:1];
        mixin = [mac final];
        [subkey appendData:mixin];
    }
    return [subkey subdataWithRange:NSMakeRange(0, length)];
}

int tag_len = 16;
int chunk_size_len = 2;

NSData *aead_encrypt(const uint8_t *plain, int length, NSData *nonce, NSData *key) {
    int expectedLength = length + tag_len;
    NSMutableData *cipher = [NSMutableData dataWithLength:expectedLength];
    unsigned long long actualLength = 0;
    int err = crypto_aead_chacha20poly1305_ietf_encrypt(cipher.mutableBytes, &actualLength,
        plain, length, NULL, 0, NULL, nonce.bytes, key.bytes);
    assert(err == 0);
    assert(actualLength == expectedLength);
    return cipher;
}

NSData *aead_decrypt(const uint8_t *cipher, int length, NSData *nonce, NSData *key) {
    int expectedLength = length - tag_len;
    NSMutableData *plain = [NSMutableData dataWithLength:expectedLength];
    unsigned long long actualLength = 0;
    int err = crypto_aead_chacha20poly1305_ietf_decrypt(plain.mutableBytes, &actualLength,
        NULL, cipher, length, NULL, 0, nonce.bytes, key.bytes);
    assert(err == 0);
    assert(actualLength == expectedLength);
    return plain;
}

@implementation AEAD {
    NSData *subkey;
    NSMutableData *nonce;
    NSMutableData *buffer;
}
- (instancetype)initWithMasterKey:(NSData *)key :(NSData *)salt {
    self = [super init];
    NSData *info = [@"ss-subkey" dataUsingEncoding:NSUTF8StringEncoding];
    subkey = generateSubkey(key, salt, info);
    nonce = [NSMutableData dataWithLength:12];
    buffer = [NSMutableData data];
    return self;
}
- (NSData *)encrypted:(NSData *)plainData {
    int cipherLength = tag_len * 2 + plainData.length + chunk_size_len;
    NSMutableData *cipherData = [NSMutableData dataWithCapacity:cipherLength];
    
    uint16_t len = htons(plainData.length);
    NSData *lengthData = aead_encrypt(&len, sizeof(len), nonce, subkey);
    [cipherData appendData:lengthData];
    sodium_increment(nonce.mutableBytes, nonce.length);

    NSData *payload = aead_encrypt(plainData.bytes, plainData.length, nonce, subkey);
    [cipherData appendData:payload];
    sodium_increment(nonce.mutableBytes, nonce.length);
    
    return cipherData;
}
- (NSData *)_decrypted:(const uint8_t *)cipherData :(NSUInteger)length {
    if (length <= tag_len * 2 + chunk_size_len) return NULL;

    int cipherLengthLen = chunk_size_len + tag_len;
    NSData *lengthData = aead_decrypt(cipherData, cipherLengthLen, nonce, subkey);
    uint16_t len = *(uint16_t *)lengthData.bytes;
    len = ntohs(len);
    int chunkLength = 2 * tag_len + chunk_size_len + len;
    if (length < chunkLength) return NULL;

    sodium_increment(nonce.mutableBytes, nonce.length);

    int cipherPayloadLen = len + tag_len;
    const uint8_t *cipherPayload = cipherData + cipherLengthLen;
    NSData *payload = aead_decrypt(cipherPayload, cipherPayloadLen, nonce, subkey);
    sodium_increment(nonce.mutableBytes, nonce.length);

    return payload;
}
- (NSData *)decrypted:(NSData *)cipherData {
    [buffer appendData:cipherData];
    const uint8_t *buf = buffer.bytes;
    NSUInteger bufLen = buffer.length;
    NSMutableData *plainData = [NSMutableData dataWithCapacity:buffer.length];
    while (true) {
        NSData *plain = [self _decrypted:buf :bufLen];
        if (!plain) break;
        
        NSUInteger chunkLen = plain.length + chunk_size_len + 2 * tag_len;
        assert(bufLen >= chunkLen);
        bufLen -= chunkLen;
        buf += chunkLen;
        [plainData appendData:plain];
    }
    buffer = [NSMutableData dataWithBytes:buf length:bufLen];
    return plainData;
}
@end
