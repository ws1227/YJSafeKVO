//
//  _YJKVOGroupingPorter.h
//  YJKit
//
//  Created by huang-kun on 16/7/5.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPorter.h"

NS_ASSUME_NONNULL_BEGIN

/// The class for deliver the value changes.

__attribute__((visibility("hidden")))
@interface _YJKVOGroupingPorter : _YJKVOPorter

/// The designated initializer
- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber NS_DESIGNATED_INITIALIZER;

/// Add target and target key path
- (void)addTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath;

/// Associate with subscribers's key path for applying changes directly.
@property (nullable, nonatomic, copy) NSString *subscriberKeyPath;

/// The value change callback block which only for reducing changes.
@property (nullable, nonatomic, copy) YJKVOMultipleValueHandler multipleValueHandler;

/// The value change callback block which only for reducing changes.
@property (nullable, nonatomic, copy) YJKVOReduceValueReturnHandler reduceValueReturnHandler;


@end

NS_ASSUME_NONNULL_END