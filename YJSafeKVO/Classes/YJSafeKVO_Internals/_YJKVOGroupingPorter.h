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

/// Associate with a group of targets for value change callback.
- (void)associateWithGroupTarget:(NSArray <__kindof NSObject *> *)groupTargets;

/// Associate with subscribers's key path for applying changes directly.
@property (nullable, nonatomic, copy) NSString *subscriberKeyPath;

/// The value change callback block.
@property (nullable, nonatomic, copy) YJKVOReceiverTargetsHandler targetsHandler;

/// The value change callback block which only for converting changes.
@property (nullable, nonatomic, copy) YJKVOReceiverTargetsReturnHandler targetsReturnHandler;

@end

NS_ASSUME_NONNULL_END