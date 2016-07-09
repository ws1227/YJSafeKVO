//
//  _YJKVOExecutiveOfficer.m
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOExecutiveOfficer.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOPorterManager.h"
#import "_YJKVOPorterTracker.h"
#import "NSObject+YJIMPInsertion.h"

@implementation _YJKVOExecutiveOfficer

+ (instancetype)officer {
    static _YJKVOExecutiveOfficer *officer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        officer = [_YJKVOExecutiveOfficer new];
    });
    return officer;
}

- (void)registerPorter:(__kindof _YJKVOPorter *)porter
           forObserver:(__kindof NSObject *)observer
                target:(__kindof NSObject *)target
         targetKeyPath:(NSString *)targetKeyPath
               options:(NSKeyValueObservingOptions)options {
    
    // manage porter
    _YJKVOPorterManager *porterManager = target.yj_KVOPorterManager;
    if (!porterManager) {
        porterManager = [[_YJKVOPorterManager alloc] initWithObservedTarget:target];
        target.yj_KVOPorterManager = porterManager;
    }
    [porterManager employPorter:porter forKeyPath:targetKeyPath options:options];
    
    // track porter
    _YJKVOPorterTracker *tracker = observer.yj_KVOPorterTracker;
    if (!tracker) {
        tracker = [[_YJKVOPorterTracker alloc] initWithObserver:observer];
        observer.yj_KVOPorterTracker = tracker;
    }
    [tracker trackPorter:porter forKeyPath:targetKeyPath target:target];
    
    // release porters before dealloc
    [target performBlockBeforeDeallocating:^(__kindof NSObject *target) {
        [target.yj_KVOPorterManager unemployAllPorters];
    }];
    [observer performBlockBeforeDeallocating:^(__kindof NSObject *observer) {
        [observer.yj_KVOPorterTracker untrackAllRelatedPorters];
    }];
}

- (void)unregisterPortersForObserver:(__kindof NSObject *)observer
                          fromTarget:(__kindof NSObject *)target
                       targetKeyPath:(NSString *)targetKeyPath {
    if (target) {
        [observer.yj_KVOPorterTracker untrackRelatedPortersForKeyPath:targetKeyPath target:target];
    } else {
        [observer.yj_KVOPorterTracker untrackAllRelatedPorters];
    }
}

- (void)unregisterPortersForObserver:(__kindof NSObject *)observer {
    [self unregisterPortersForObserver:observer fromTarget:nil targetKeyPath:nil];
}

@end
