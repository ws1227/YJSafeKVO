//
//  _YJKVOTracker.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOTracker.h"
#import "_YJKVOPorter.h"
#import "_YJKVOManager.h"
#import "_YJKVODefines.h"
#import "NSObject+YJKVOExtension.h"

@implementation _YJKVOTracker {
    __unsafe_unretained id _observer;
    dispatch_semaphore_t _semaphore;
    NSMapTable <__kindof NSObject *, NSMapTable <NSString *, NSHashTable <_YJKVOPorter *> *> *> *_relatedPorters;
}

- (instancetype)initWithObserver:(__kindof NSObject *)observer {
    self = [super init];
    if (self) {
        _observer = observer;
        _semaphore = dispatch_semaphore_create(1);
        _relatedPorters = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)trackPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath target:(__kindof NSObject *)target {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMapTable *keyPathsAndPorters = [_relatedPorters objectForKey:target];
    if (!keyPathsAndPorters) {
        keyPathsAndPorters = [NSMapTable strongToStrongObjectsMapTable];
        [_relatedPorters setObject:keyPathsAndPorters forKey:target];
    }
    NSHashTable *porters = [keyPathsAndPorters objectForKey:keyPath];
    if (!porters) {
        porters = [NSHashTable weakObjectsHashTable];
        [keyPathsAndPorters setObject:porters forKey:keyPath];
    }
    if (![porters containsObject:porter]) {
        [porters addObject:porter];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

static void _yj_enumerateKeysAndObjectsOfMapTable(NSMapTable *mapTable, void(^handler)(id /*key*/, id /*obj*/, BOOL */*stop*/)) {
    id key = nil; BOOL stop = NO;
    NSEnumerator *keyEnumerator = [mapTable keyEnumerator];
    while (key = [keyEnumerator nextObject]) {
        id obj = [mapTable objectForKey:key];
        if (handler && obj) handler(key, obj, &stop);
        if (stop) break;
    }
}

- (void)untrackRelatedPortersForKeyPath:(NSString *)keyPath target:(__kindof NSObject *)target {
    _yj_enumerateKeysAndObjectsOfMapTable(self->_relatedPorters, ^(__kindof NSObject *relatedTarget, NSMapTable *keyPathsAndPorters, BOOL *stop){
        if (relatedTarget == target) {
            [target.yj_KVOManager unemployPortersForKeyPath:keyPath];
            *stop = YES;
        }
    });
}

- (void)untrackAllRelatedPorters {
    NSMapTable *relatedPorters = self->_relatedPorters;
    _yj_enumerateKeysAndObjectsOfMapTable(relatedPorters, ^(__kindof NSObject *target, NSMapTable *keyPathsAndPorters, BOOL *stop){
        _yj_enumerateKeysAndObjectsOfMapTable(keyPathsAndPorters, ^(NSString *keyPath, NSHashTable *porters, BOOL *stop){
            [target.yj_KVOManager unemployPorters:[porters allObjects] forKeyPath:keyPath];
        });
    });
}

- (void)dealloc {
    _observer = nil;
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end
