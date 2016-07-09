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
- (instancetype)initWithObserver:(__kindof NSObject *)observer
                         targets:(NSArray <__kindof NSObject *> *)targets
                           queue:(nullable NSOperationQueue *)queue
                    targetsHandler:(YJKVOTargetsHandler)targetsHandler;

@end

NS_ASSUME_NONNULL_END