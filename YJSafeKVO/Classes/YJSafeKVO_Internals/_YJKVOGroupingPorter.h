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

+ (instancetype)porterForObserver:(__kindof NSObject *)observer
                          targets:(NSArray <__kindof NSObject *> *)targets
                          handler:(YJKVOTargetsHandler)targetsHandler;

+ (instancetype)porterForObserver:(__kindof NSObject *)observer
                  observerKeyPath:(NSString *)observerKeyPath
                          targets:(NSArray <__kindof NSObject *> *)targets
                          handler:(YJKVOTargetsReturnHandler)targetsReturnHandler;

@end

NS_ASSUME_NONNULL_END