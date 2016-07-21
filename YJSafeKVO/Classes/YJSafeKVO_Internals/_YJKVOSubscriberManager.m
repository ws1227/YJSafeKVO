//
//  _YJKVOSubscriberManager.m
//  YJKit
//
//  Created by huang-kun on 16/7/20.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOSubscriberManager.h"
#import "_YJKVODefines.h"

@implementation _YJKVOSubscriberManager {
    __unsafe_unretained __kindof NSObject *_target;
    NSHashTable <__kindof NSObject *> *_subscribers;
    dispatch_semaphore_t _semaphore;
}

- (instancetype)initWithTarget:(__kindof NSObject *)target {
    self = [super init];
    if (self) {
        _target = target;
        _subscribers = [NSHashTable weakObjectsHashTable];
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)init {
    [NSException raise:NSGenericException format:@"Do not call init directly for %@.", self.class];
    return [self initWithTarget:(id)[NSNull null]];
}

- (void)addSubscriber:(__kindof NSObject *)subscriber {    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_subscribers addObject:subscriber];
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeSubscriber:(__kindof NSObject *)subscriber {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_subscribers removeObject:subscriber];
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeSubscribers:(NSArray <__kindof NSObject *> *)subscribers {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    for (__kindof NSObject *subscriber in subscribers) {
        [_subscribers removeObject:subscriber];
    }
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeAllSubscribers {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_subscribers removeAllObjects];
    dispatch_semaphore_signal(_semaphore);
}

- (void)enumerateSubscribersUsingBlock:(void (^)(__kindof NSObject *subscriber, BOOL *stop))block {
    id obj = nil; BOOL stop = NO;
    NSEnumerator *enumerator = [_subscribers objectEnumerator];
    while (obj = [enumerator nextObject]) {
        if (block) block(obj, &stop);
        if (stop) break;
    }
}

- (NSUInteger)numberOfSubscribers {
    return _subscribers.count;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (target <%@: %p>)", self.class, self, _target.class, _target];
}

#if YJ_KVO_DEBUG
- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}
#endif

@end
