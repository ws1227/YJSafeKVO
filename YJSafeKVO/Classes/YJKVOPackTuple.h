//
//  YJKVOPackTuple.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YJKVOPackTuple;

#ifndef keyPath
#define keyPath(KEYPATH) \
    (((void)(NO && ((void)KEYPATH, NO)), strchr(#KEYPATH, '.') + 1))
#endif

#define KEYPATH_OBJECTIFY(OBJECT, KEYPATH) \
    @(((void)(NO && ((void)OBJECT.KEYPATH, NO)), #KEYPATH))

#define PACK(OBJECT, KEYPATH) \
    [YJKVOPackTuple tupleWithObject:OBJECT keyPath:KEYPATH_OBJECTIFY(OBJECT, KEYPATH)]


/// Using PACK macro.
/// e.g. If foo wants to observe bar's name property change when a new name applys to bar, then use:
/// @code
/// [foo observe:PACK(bar, name) ...]
/// @endcode
typedef YJKVOPackTuple * PACK;


NS_ASSUME_NONNULL_BEGIN

/// The class for wrapping observed target and it's key path

@interface YJKVOPackTuple : NSObject

+ (instancetype)tupleWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath;

@property (nonatomic, readonly, strong) __kindof NSObject *object;
@property (nonatomic, readonly, strong) NSString *keyPath;
@property (nonatomic, readonly) BOOL isValid;

@end



/// Once you get BIND by returning from -bind: , it is available for nesting / chaining.
/// e.g. [[[PACK(foo, mood) bind:PACK(bar, feedback)] convert:...] after:...]
typedef YJKVOPackTuple * BIND;


/// Binding Extension

@interface YJKVOPackTuple (YJKVOBinding)


/**
 @brief Pipe observer with target for receiving value changes. This will receive value immediately.
 @warning Using this for single direction. If [A pipe:B] then [B pipe:A], you will get infinite loop.
 @param targetAndKeyPath    The YJKVOPackTuple object for wrapping object and its key path, using PACK(target, keyPath).
 */
- (void)pipe:(PACK)targetAndKeyPath;


/**
 @brief Bind observer with target for receiving value changes.
 @warning Using this for single direction. If [A bind:B] then [B bind:A], you will get infinite loop.
 @param targetAndKeyPath    The YJKVOPackTuple object for wrapping object and its key path, using PACK(target, keyPath).
 @return It returns BIND that can be nested with additional calls.
 */
- (BIND)bind:(PACK)targetAndKeyPath;


/**
 @brief If the new changes should be taken (meaning accepted by observer).
 @param The taken block for deciding if new changes should be applied to observer.
 */
- (BIND)taken:(BOOL(^)(id observer, id target, id _Nullable newValue))taken;


/**
 @brief Convert the newValue to other kind of object as new returned value.
 @param The convert block for value convertion.
 */
- (BIND)convert:(nullable id(^)(id observer, id target, id _Nullable newValue))convert;


/**
 @brief Get called after each binding finished.
 @param The after block for additional callback.
 */
- (BIND)after:(void(^)(id observer, id target))after;

@end

NS_ASSUME_NONNULL_END