//
//  _YJKVOManager.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOManager.h"
#import "_YJKVOPorter.h"
#import "YJRuntimeEncapsulation.h"

@implementation _YJKVOManager {
    __unsafe_unretained id _target;
    dispatch_semaphore_t _semaphore;
    NSMutableDictionary <NSString *, NSMutableArray <_YJKVOPorter *> *> *_porters;
}

- (instancetype)initWithObservedTarget:(id)target {
    self = [super init];
    if (self) {
        _target = target;
        _semaphore = dispatch_semaphore_create(1);
        _porters = [NSMutableDictionary new];
    }
    return self;
}

- (void)employPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options {
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath) {
        portersForKeyPath = [NSMutableArray new];
        _porters[keyPath] = portersForKeyPath;
    }
    if (![portersForKeyPath containsObject:porter]) {
        [portersForKeyPath addObject:porter];
        [_target addObserver:porter forKeyPath:keyPath options:options context:NULL];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unemployPortersForKeyPath:(NSString *)keyPath {
    NSMutableArray <_YJKVOPorter *> *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath.count)
        return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [portersForKeyPath enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
        [_target removeObserver:porter forKeyPath:keyPath];
    }];
    [_porters removeObjectForKey:keyPath];
    
    dispatch_semaphore_signal(_semaphore);
}

BOOL (^yj_containsIdenticalObjects)(NSArray *, NSArray *) = ^BOOL(NSArray *arr1, NSArray *arr2) {
    if (arr1.count > arr2.count)
        return NO;
    
    for (id obj1 in arr1) {
        for (id obj2 in arr2) {
            if (obj1 != obj2) {
                return NO;
            }
        }
    }
    return YES;
};

- (void)unemployPorters:(NSArray <_YJKVOPorter *> *)porters forKeyPath:(NSString *)keyPath {
    NSMutableArray <_YJKVOPorter *> *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath.count)
        return;
    
    if (!yj_containsIdenticalObjects(portersForKeyPath, porters))
        return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [porters enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
        [_target removeObserver:porter forKeyPath:keyPath];
    }];
    
    [portersForKeyPath removeObjectsInArray:porters];
    if (!portersForKeyPath.count) {
        [_porters removeObjectForKey:keyPath];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unemployAllPorters {
    if (!_porters.count)
        return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [_porters enumerateKeysAndObjectsUsingBlock:^(id _Nonnull keyPath, NSMutableArray *  _Nonnull portersForKeyPath, BOOL * _Nonnull stop) {
        [portersForKeyPath enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
            [_target removeObserver:porter forKeyPath:keyPath];
        }];
    }];
    [_porters removeAllObjects];
    
    dispatch_semaphore_signal(_semaphore);
}


- (void)dealloc {
    _target = nil;
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end
