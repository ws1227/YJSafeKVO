//
//  _YJKVOManager.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorter;

NS_ASSUME_NONNULL_BEGIN

/// The class for managing the KVO porters.

__attribute__((visibility("hidden")))
@interface _YJKVOManager : NSObject

/// initialize a manager instance by knowing it's caller.
- (instancetype)initWithObservedTarget:(id)owner;

/// add porter to the internal collection, and also register KVO internally.
- (void)employPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;

/// remove all porters from internal collection for specific key path.
- (void)unemployPortersForKeyPath:(NSString *)keyPath;

/// remove given porters from internal collection for specific key path.
- (void)unemployPorters:(NSArray <_YJKVOPorter *> *)porters forKeyPath:(NSString *)keyPath;

/// remove all porters from internal collection for every key path.
- (void)unemployAllPorters;

@end

NS_ASSUME_NONNULL_END