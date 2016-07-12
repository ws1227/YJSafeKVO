//
//  _YJKVOBindingPorter.h
//  YJKit
//
//  Created by huang-kun on 16/7/7.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPorter.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^YJKVOValueTakenHandler)(id observer, id target, id _Nullable newValue);

/// The class for deliver the value changes.

__attribute__((visibility("hidden")))
@interface _YJKVOBindingPorter : _YJKVOPorter

/// The designated initializer
- (instancetype)initWithObserver:(__kindof NSObject *)observer
                 observerKeyPath:(NSString *)observerKeyPath;

@property (nonatomic, copy) YJKVOValueReturnHandler convertHandler;
@property (nonatomic, copy) YJKVOValueTakenHandler takenHandler;
@property (nonatomic, copy) YJKVOObjectsHandler afterHandler;

@end

NS_ASSUME_NONNULL_END