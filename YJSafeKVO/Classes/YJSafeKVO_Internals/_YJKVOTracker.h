//
//  _YJKVOTracker.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorter;

NS_ASSUME_NONNULL_BEGIN

/// The class for tracking porters for observer

__attribute__((visibility("hidden")))
@interface _YJKVOTracker : NSObject

/// Designated Initializer
- (instancetype)initWithObserver:(__kindof NSObject *)observer;

/// Keep the information about the porter with key path and target
- (void)trackPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath target:(__kindof NSObject *)target;

/// Stop tracking the porters and make them dismissing.
- (void)untrackRelatedPortersForKeyPath:(NSString *)keyPath target:(__kindof NSObject *)target;

/// Stop tracking all related porters and make them dismissing.
- (void)untrackAllRelatedPorters;

@end

NS_ASSUME_NONNULL_END