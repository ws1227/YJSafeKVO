//
//  _YJKVOPorterManager.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorter;

NS_ASSUME_NONNULL_BEGIN

/// The class for managing the KVO porters.
/// This class will be attached to subscriber or sender.

__attribute__((visibility("hidden")))
@interface _YJKVOPorterManager : NSObject

/// designated initializer
- (instancetype)initWithOwner:(__kindof NSObject *)owner NS_DESIGNATED_INITIALIZER;

/// Add porter
- (void)addPorter:(_YJKVOPorter *)porter;

/// Remove porter
- (void)removePorter:(_YJKVOPorter *)porter;

/// Remove porters
- (void)removePorters:(NSArray <_YJKVOPorter *> *)porters;

/// Remove all porters
- (void)removeAllPorters;

/// Enumerate each porter
- (void)enumeratePortersUsingBlock:(void (^)(__kindof _YJKVOPorter *porter, BOOL *stop))block;

/// Number of porters
- (NSUInteger)numberOfPorters;

@end

NS_ASSUME_NONNULL_END