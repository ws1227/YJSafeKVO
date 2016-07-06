//
//  NSObject+YJSafeKVO.m
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJSafeKVO.h"
#import "NSObject+YJIMPInsertion.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOPorter.h"
#import "_YJKVOSeniorPorter.h"
#import "_YJKVOManager.h"
#import "_YJKVOTracker.h"
#import "_YJKVODefines.h"

#pragma mark - internal functions

/* -------------------------- */
//  YJKVO Internal Functions
/* -------------------------- */

static void _yj_registerKVO(__kindof NSObject *observer, __kindof NSObject *target, NSString *keyPath,
                            NSKeyValueObservingOptions options, NSOperationQueue *queue, YJKVOHandler handler) {
    
    // generate a porter
    _YJKVOPorter *porter = [[_YJKVOPorter alloc] initWithObserver:observer queue:queue handler:handler];
    
    // manage porter
    _YJKVOManager *kvoManager = target.yj_KVOManager;
    if (!kvoManager) {
        kvoManager = [[_YJKVOManager alloc] initWithObservedTarget:target];
        target.yj_KVOManager = kvoManager;
    }
    [kvoManager employPorter:porter forKeyPath:keyPath options:options];
    
    // track porter
    _YJKVOTracker *tracker = observer.yj_KVOTracker;
    if (!tracker) {
        tracker = [[_YJKVOTracker alloc] initWithObserver:observer];
        observer.yj_KVOTracker = tracker;
    }
    [tracker trackPorter:porter forKeyPath:keyPath target:target];
    
    // release porters before dealloc
    [observer performBlockBeforeDeallocating:^(__kindof NSObject *observer) {
        [observer.yj_KVOTracker untrackAllRelatedPorters];
    }];
    [target performBlockBeforeDeallocating:^(__kindof NSObject *target) {
        [target.yj_KVOManager unemployAllPorters];
    }];
}

static void _yj_registerKVOGroup(__kindof NSObject *observer,
                                 NSArray <__kindof NSObject *> *targets,
                                 NSArray <NSString *> *keyPaths,
                                 NSKeyValueObservingOptions options,
                                 NSOperationQueue *queue,
                                 YJKVOGroupHandler groupHandler) {
    
    NSCAssert(targets.count == keyPaths.count, @"YJSafeKVO - targets and keyPaths are not paired.");
    
    // generate a porter
    _YJKVOSeniorPorter *porter = [[_YJKVOSeniorPorter alloc] initWithObserver:observer
                                                                      targets:targets
                                                                        queue:queue
                                                                 groupHandler:groupHandler];
    
    for (int i = 0; i < targets.count; i++) {
        
        __kindof NSObject *target = targets[i];
        NSString *keyPath = keyPaths[i];
        
        // manage porter
        _YJKVOManager *kvoManager = target.yj_KVOManager;
        if (!kvoManager) {
            kvoManager = [[_YJKVOManager alloc] initWithObservedTarget:target];
            target.yj_KVOManager = kvoManager;
        }
        [kvoManager employPorter:porter forKeyPath:keyPath options:options];
        
        // track porter
        _YJKVOTracker *tracker = observer.yj_KVOTracker;
        if (!tracker) {
            tracker = [[_YJKVOTracker alloc] initWithObserver:observer];
            observer.yj_KVOTracker = tracker;
        }
        [tracker trackPorter:porter forKeyPath:keyPath target:target];
        
        // release porters before dealloc
        [target performBlockBeforeDeallocating:^(__kindof NSObject *target) {
            [target.yj_KVOManager unemployAllPorters];
        }];
    }
    [observer performBlockBeforeDeallocating:^(__kindof NSObject *observer) {
        [observer.yj_KVOTracker untrackAllRelatedPorters];
    }];
}

static BOOL _yj_validateOBSVTuple(id targetAndKeyPath, id *target, NSString **keyPath) {
    if (![targetAndKeyPath isKindOfClass:[YJOBSVTuple class]])
        return NO;
    
    YJOBSVTuple *tuple = (YJOBSVTuple *)targetAndKeyPath;
    
    if (target) {
        *target = tuple.target;
        NSCAssert(*target != nil, @"YJSafeKVO - Target can not be nil for Key value observing.");
    } else {
        return NO;
    }
    
    if (keyPath) {
        *keyPath = tuple.keyPath;
        NSCAssert((*keyPath).length > 0, @"YJSafeKVO - KeyPath can not be empty for Key value observing.");
    } else {
        return NO;
    }
    
    return YES;
}


#pragma mark - YJSafeKVO implementations

/* ------------------------- */
//          YJSafeKVO
/* ------------------------- */

@implementation NSObject (YJSafeKVO)

- (void)observe:(OBSV)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_validateOBSVTuple(targetAndKeyPath, &target, &keyPath)) {
        
        void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
            if (updates) updates(receiver, target, newValue);
        };
        
        _yj_registerKVO(self, target, keyPath, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, handler);
    }
}

- (void)observes:(NSArray <OBSV> *)targetsAndKeyPaths updates:(void(^)(id receiver, NSArray *targets))updates {
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    NSMutableArray *keyPaths = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    
    for (YJOBSVTuple *tuple in targetsAndKeyPaths) {
        __kindof NSObject *target; NSString *keyPath;
        if (_yj_validateOBSVTuple(tuple, &target, &keyPath)) {
            [targets addObject:target];
            [keyPaths addObject:keyPath];
        }
    }
    
    _yj_registerKVOGroup(self, targets, keyPaths, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, updates);
}

- (void)observe:(OBSV)targetAndKeyPath
        options:(NSKeyValueObservingOptions)options
          queue:(nullable NSOperationQueue *)queue
        changes:(void(^)(id receiver, id target, NSDictionary *change))changes {
    
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_validateOBSVTuple(targetAndKeyPath, &target, &keyPath)) {
        
        void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
            if (changes) changes(receiver, target, change);
        };
        
        _yj_registerKVO(self, target, keyPath, options, queue, handler);
    }
}

- (void)unobserve:(OBSV)targetAndKeyPath {
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_validateOBSVTuple(targetAndKeyPath, &target, &keyPath)) {
        [self.yj_KVOTracker untrackRelatedPortersForKeyPath:keyPath target:target];
    }
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    
    void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
        if (updates) updates(receiver, target, newValue);
    };
    
    _yj_registerKVO(self, target, keyPath, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, handler);
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
                queue:(nullable NSOperationQueue *)queue
              changes:(void(^)(id receiver, id target, NSDictionary *change))changes {
    
    void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
        if (changes) changes(receiver, target, change);
    };
    
    _yj_registerKVO(self, target, keyPath, options, queue, handler);
}

- (void)unobserveTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    [self.yj_KVOTracker untrackRelatedPortersForKeyPath:keyPath target:target];
}

- (void)unobserveAll {
    [self.yj_KVOTracker untrackAllRelatedPorters];
}

@end
