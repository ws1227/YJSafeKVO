//
//  _YJKVOPorter.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_YJKVODefines.h"

NS_ASSUME_NONNULL_BEGIN

/// The class for delivering the value changes.

__attribute__((visibility("hidden")))
@interface _YJKVOPorter : NSObject

/// The designated initializer
- (instancetype)initWithTarget:(nullable __kindof NSObject *)target
                    subscriber:(nullable __kindof NSObject *)subscriber
                 targetKeyPath:(nullable NSString *)targetKeyPath NS_DESIGNATED_INITIALIZER;

/// Register KVO
- (void)signUp;

/// Unregister KVO
- (void)resign;

/// Check if porter is being registered.
@property (nonatomic, readonly) BOOL employed;

/// The KVO target.
@property (nullable, nonatomic, readonly, assign) __kindof NSObject *target;

/// The KVO subscriber.
@property (nullable, nonatomic, readonly, assign) __kindof NSObject *subscriber;

/// The key path of target for observing.
@property (nullable, nonatomic, readonly, copy) NSString *targetKeyPath;

/// The key value observing options, default is (.initial | .new)
@property (nonatomic) NSKeyValueObservingOptions observingOptions;

/// The operation queue for adding change handler.
@property (nullable, nonatomic, strong) NSOperationQueue *queue;

/// The default handler for handling the value changes.
@property (nullable, nonatomic, copy) YJKVODefaultChangeHandler changeHandler;

/// The value handler for handling value changes.
@property (nullable, nonatomic, copy) YJKVOSubscriberValueHandler valueHandler;

@end

NS_ASSUME_NONNULL_END