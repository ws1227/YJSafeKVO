//
//  _YJKVOPorterTracker.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPorterTracker.h"
#import "_YJKVOPorter.h"
#import "_YJKVOPorterManager.h"
#import "_YJKVODefines.h"
#import "_YJKVOGuardian.h"
#import "NSObject+YJKVOExtension.h"

static void _yj_kvo_enumerateKeysAndObjectsOfMapTable(NSMapTable *mapTable, void(^handler)(id key, id obj, BOOL *stop)) {
    id key = nil; BOOL stop = NO;
    NSEnumerator *keyEnumerator = [mapTable keyEnumerator];
    while (key = [keyEnumerator nextObject]) {
        id obj = nil;
        if (![key isKindOfClass:[NSString class]]) {
            IMP equalityIMP = [[_YJKVOGuardian guardian] applyIdentityComparisonForObject:key];
            obj = [mapTable objectForKey:key];
            [[_YJKVOGuardian guardian] applyEqualityComparisonForObject:key implementation:equalityIMP];
        } else {
            obj = [mapTable objectForKey:key];
        }
        if (handler && obj) handler(key, obj, &stop);
        if (stop) break;
    }
}

@implementation _YJKVOPorterTracker {
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
    
    // NSMapTable (similar to NSDictionary) calls -isEqual: for key comparison when calling -objectForKey: and -setObject:forKey:
    // This might trigger a crash for comparing keys which might be different type and have different -isEqual: implementation.
    // So the solution is to use pointer comparison for -isEqual: temporarily.
    IMP equalityIMP = [[_YJKVOGuardian guardian] applyIdentityComparisonForObject:target];
    
    // using NSMapTable
    NSMapTable *keyPathsAndPorters = [_relatedPorters objectForKey:target];
    if (!keyPathsAndPorters) {
        keyPathsAndPorters = [NSMapTable strongToStrongObjectsMapTable];
        [_relatedPorters setObject:keyPathsAndPorters forKey:target];
    }
    
    // if -isEqual: IMP is switched, then switch it back.
    [[_YJKVOGuardian guardian] applyEqualityComparisonForObject:target implementation:equalityIMP];
    
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

- (void)untrackRelatedPortersForKeyPath:(NSString *)keyPath target:(__kindof NSObject *)target {
    _yj_kvo_enumerateKeysAndObjectsOfMapTable(self->_relatedPorters, ^(__kindof NSObject *relatedTarget, NSMapTable *keyPathsAndPorters, BOOL *stop){
        if (relatedTarget == target) {
            [target.yj_KVOPorterManager unemployPortersForKeyPath:keyPath];
            *stop = YES;
        }
    });
}

- (void)untrackAllRelatedPorters {
    NSMapTable *relatedPorters = self->_relatedPorters;
    _yj_kvo_enumerateKeysAndObjectsOfMapTable(relatedPorters, ^(__kindof NSObject *target, NSMapTable *keyPathsAndPorters, BOOL *stop){
        _yj_kvo_enumerateKeysAndObjectsOfMapTable(keyPathsAndPorters, ^(NSString *keyPath, NSHashTable *porters, BOOL *stop){
            [target.yj_KVOPorterManager unemployPorters:[porters allObjects] forKeyPath:keyPath];
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
