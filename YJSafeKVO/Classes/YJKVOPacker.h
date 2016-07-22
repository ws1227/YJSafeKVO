//
//  YJKVOPacker.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YJKVOPacker;

#define _OBJECTIFY_KEYPATH(OBJECT, KEYPATH) \
    @(((void)(NO && ((void)OBJECT.KEYPATH, NO)), #KEYPATH))

#define _STRINGIFY_VARIABLE(VARIABLE) \
    @#VARIABLE

// For UNPACK(CLASS, TARGET) macro, not for direct use.
id _YJKVO_retrieveTarget(NSArray *targets, NSString *variableName);

#ifndef keyPath
#define keyPath(KEYPATH) \
    (((void)(NO && ((void)KEYPATH, NO)), strchr(#KEYPATH, '.') + 1))
#endif

#define PACK(OBJECT, KEYPATH) \
    [YJKVOPacker packerWithObject:OBJECT keyPath:_OBJECTIFY_KEYPATH(OBJECT, KEYPATH) variableName:_STRINGIFY_VARIABLE(OBJECT)]

#define UNPACK(CLASS, TARGET) \
    CLASS *TARGET = _YJKVO_retrieveTarget(targets, _STRINGIFY_VARIABLE(TARGET));

/// PACK(OBJECT, KEYPATH) is a macro to wrap object and its key path to a YJKVOPacker.
/// e.g. PACK(foo, name) or PACK(foo, friend.name)
typedef YJKVOPacker * PACK;


/// The class for wrapping observed target and it's key path.
/// DO NOT USE "YJKVOPacker" directly, use PACK(OBJECT, KEYPATH) macro for objective c and use PACK( object, keyPath ) for swift.
@interface YJKVOPacker : NSObject

/// The designated initializer, and do not call it directly, use PACK.
- (instancetype)initWithObject:(__kindof NSObject *)object
                       keyPath:(NSString *)keyPath
                        NS_DESIGNATED_INITIALIZER
                        NS_SWIFT_NAME(init(_:_:));

/// The factory method initializer, and do not call it directly, use PACK.
+ (instancetype)packerWithObject:(__kindof NSObject *)object
                         keyPath:(NSString *)keyPath
                    variableName:(nullable NSString *)variableName
                        NS_SWIFT_UNAVAILABLE("Use init(_:_:) instead.");

@property (nonatomic, readonly, strong) __kindof NSObject *object;
@property (nonatomic, readonly, strong) NSString *keyPath;
@property (nonatomic, readonly) BOOL isValid;

@end


/* --------------------------------------------------------------------------------------------- */
//                                            binding
/* --------------------------------------------------------------------------------------------- */

@interface YJKVOPacker (YJKVOBinding)


/**
 @brief Bind subscriber with target for receiving value changes. This will receive value immediately.
 @discussion After calling [A bound:B], the data flow will come from B to A.
 @warning Make sure the binding keyPaths on both sides are same type.
 @warning Using this for single direction. If [A bound:B] then [B bound:A], you will get infinite loop.
 @param targetAndKeyPath    The target and its key path to observe. Using PACK(target, keyPath) to wrap them.
 */
- (void)bound:(PACK)targetAndKeyPath;


/**
 @brief Making a pipe between subscriber and target for receiving value changes.
 @discussion After calling [A piped:B], later the data flow will come from B to A.
 @discussion Calling [[A piped:B] ready] will get same results as [A bound:B]
 @warning Using this for single direction. If [A piped:B] then [B piped:A], you will get infinite loop.
 @param targetAndKeyPath    The target and its key path to observe. Using PACK(target, keyPath) to wrap them.
 @return It returns PACK object that can be nested with additional calls.
 */
- (PACK)piped:(PACK)targetAndKeyPath;


/**
 @brief Set value from target's keyPath immediately.
 @discussion e.g. You can call [[[[A piped:B] convert:..] after:..] ready]
 */
- (void)ready;


/**
 @brief If the new changes should be taken (meaning accepted by subscriber).
 @param The taken block for deciding if new changes should be applied to subscriber.
 */
- (PACK)taken:(BOOL(^)(id subscriber, id target, id _Nullable newValue))taken;


/**
 @brief Convert the newValue to other kind of object as new returned value.
 @param The convert block for value convertion.
 */
- (PACK)convert:(nullable id(^)(id subscriber, id target, id _Nullable newValue))convert;


/**
 @brief Get called after each pipe finished.
 @param The after block for additional callback.
 */
- (PACK)after:(void(^)(id subscriber, id target))after;


/**
 @brief Receiving changes from multiple targets with keyPaths.
 @param converge The block for reducing the result, then returns a result for setting subscriber's keyPath.
 */
- (void)flooded:(NSArray <PACK> *)targetsAndKeyPaths converge:(nullable id(^)(id subscriber, NSArray *targets))converge;


/**
 @brief Cutting off the binding relationship between subscriber's keyPath and target's keyPath.
 @discussion This is for cutting off -bounds: or -piped:
 @discussion After calling this, the subscriber with its key path will not receive the value changes
             from specified target with its key path.
 */
- (void)cutOff:(PACK)targetAndKeyPath;

@end


/* --------------------------------------------------------------------------------------------- */
//                                            posting
/* --------------------------------------------------------------------------------------------- */

@interface YJKVOPacker (YJKVOPosting)

/**
 @brief Post the value changes from sender's key path.
 @param The post block will be called immediately and for each time when new value is being set.
 */
- (void)post:(void(^)(id _Nullable newValue))post;

/**
 @brief Stop posting the value changes.
 @discussion After calling this, the post block will be released.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
