//
//  _YJKVOSubscriberManager.h
//  YJKit
//
//  Created by huang-kun on 16/7/20.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The class for managing the KVO subscribers.
/// This class will be attached to target.

__attribute__((visibility("hidden")))
@interface _YJKVOSubscriberManager : NSObject

/// designated initializer
- (instancetype)initWithTarget:(__kindof NSObject *)target NS_DESIGNATED_INITIALIZER;

/// Add subscriber
- (void)addSubscriber:(__kindof NSObject *)subscriber;

/// Remove subscriber
- (void)removeSubscriber:(__kindof NSObject *)subscriber;

/// Remove subscribers
- (void)removeSubscribers:(NSArray <__kindof NSObject *> *)subscribers;

/// Remove all subscribers
- (void)removeAllSubscribers;

/// Enumerate each subscriber
- (void)enumerateSubscribersUsingBlock:(void (^)(__kindof NSObject *subscriber, BOOL *stop))block;

/// Number of subscribers
- (NSUInteger)numberOfSubscribers;

@end

NS_ASSUME_NONNULL_END