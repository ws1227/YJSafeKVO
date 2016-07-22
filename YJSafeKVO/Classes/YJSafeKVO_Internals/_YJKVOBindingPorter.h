//
//  _YJKVOBindingPorter.h
//  YJKit
//
//  Created by huang-kun on 16/7/7.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPorter.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^YJKVOValueTakenHandler)(id subscriber, id target, id _Nullable newValue);

/// The class for deliver the value changes.

__attribute__((visibility("hidden")))
@interface _YJKVOBindingPorter : _YJKVOPorter

/// The designated initializer
- (instancetype)initWithTarget:(__kindof NSObject *)target
                    subscriber:(__kindof NSObject *)subscriber
                 targetKeyPath:(NSString *)targetKeyPath
             subscriberKeyPath:(NSString *)subscriberKeyPath NS_DESIGNATED_INITIALIZER;

/// Associate with subscribers's key path for applying changes directly.
@property (nonatomic, readonly, copy) NSString *subscriberKeyPath;

/// The value change callback block which only for converting changes.
@property (nonatomic, copy) YJKVOObjectsAndValueReturnHandler convertHandler;

/// The value change callback block which only for filtering changes.
@property (nonatomic, copy) YJKVOValueTakenHandler takenHandler;

/// The value change callback block which only called after applying changes.
@property (nonatomic, copy) YJKVOObjectsHandler afterHandler;

@end

NS_ASSUME_NONNULL_END