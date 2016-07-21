//
//  _YJKVOExecutiveOfficer.m
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOExecutiveOfficer.h"
#import "NSObject+YJKVOExtension.h"
#import "NSObject+YJIMPInsertion.h"
#import "_YJKVOSubscriberManager.h"
#import "_YJKVOPorterManager.h"
#import "_YJKVOPorter.h"

@implementation _YJKVOExecutiveOfficer

+ (instancetype)officer {
    static _YJKVOExecutiveOfficer *officer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        officer = [_YJKVOExecutiveOfficer new];
    });
    return officer;
}

- (void)organizeTarget:(__kindof NSObject *)target
            subscriber:(__kindof NSObject *)subscriber
                porter:(__kindof _YJKVOPorter *)porter {
    
    // register kvo
    [porter signUp];
    
    // implement safe -isEqual:
    [target performSafeEqualityComparison];
    [subscriber performSafeEqualityComparison];
    
    // manage subscriber
    _YJKVOSubscriberManager *subscriberManager = target.yj_KVOSubscriberManager;
    if (!subscriberManager) {
        subscriberManager = [[_YJKVOSubscriberManager alloc] initWithTarget:target];
        target.yj_KVOSubscriberManager = subscriberManager;
    }
    [subscriberManager addSubscriber:subscriber];
    
    // manage porter
    _YJKVOPorterManager *porterManager = subscriber.yj_KVOPorterManager;
    if (!porterManager) {
        porterManager = [[_YJKVOPorterManager alloc] initWithSubscriber:subscriber];
        subscriber.yj_KVOPorterManager = porterManager;
    }
    [porterManager addPorter:porter];
    
    // unregister kvo before dealloc
    [target performBlockBeforeDeallocating:^(__kindof NSObject *target) {
        [self dismissTarget:target];
    }];
    
    [subscriber performBlockBeforeDeallocating:^(__kindof NSObject *subscriber) {
        [self dismissSubscriber:subscriber];
    }];
}

- (void)dismissTarget:(__kindof NSObject *)target {
    @autoreleasepool {
        [target.yj_KVOSubscriberManager enumerateSubscribersUsingBlock:^(__kindof NSObject * _Nonnull subscriber, BOOL * _Nonnull stop) {
            [subscriber.yj_KVOPorterManager enumeratePortersUsingBlock:^(_YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
                [porter resign];
            }];
            [subscriber.yj_KVOPorterManager removeAllPorters];
        }];
        [target.yj_KVOSubscriberManager removeAllSubscribers];
    }
}

- (void)dismissPortersFromTarget:(__kindof NSObject *)target
                   andSubscriber:(__kindof NSObject *)subscriber
                forTargetKeyPath:(NSString *)targetKeyPath {
    
    @autoreleasepool {
        // the target might be in the middle of deallocating, so don't using __weak here.
        __unsafe_unretained id targetPtr = target;
        
        _YJKVOSubscriberManager *subscriberManager = target.yj_KVOSubscriberManager;
        NSMutableArray *subscribers = [[NSMutableArray alloc] initWithCapacity:subscriberManager.numberOfSubscribers];
        [subscriberManager enumerateSubscribersUsingBlock:^(__kindof NSObject * _Nonnull subscriber, BOOL * _Nonnull stop) {
            
            _YJKVOPorterManager *porterManager = subscriber.yj_KVOPorterManager;
            NSMutableArray *porters = [[NSMutableArray alloc] initWithCapacity:porterManager.numberOfPorters];
            [porterManager enumeratePortersUsingBlock:^(_YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
                if (porter.target == targetPtr && [porter.targetKeyPath isEqualToString:targetKeyPath]) {
                    [porter resign];
                    [porters addObject:porter];
                }
            }];
            
            if (porters.count) {
                [porterManager removePorters:porters];
            }
            if (!porterManager.numberOfPorters) {
                [subscribers addObject:subscriber];
            }
        }];
        
        if (subscribers.count) {
            [subscriberManager removeSubscribers:subscribers];
        }
    }
}

- (void)dismissSubscriber:(__kindof NSObject *)subscriber {
    @autoreleasepool {
        NSMutableSet *targets = [NSMutableSet new];
        
        _YJKVOPorterManager *porterManager = subscriber.yj_KVOPorterManager;
        [porterManager enumeratePortersUsingBlock:^(_YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
            [porter resign];
            if (porter.target) {
                [targets addObject:porter.target];
            }
        }];
        [porterManager removeAllPorters];
        
        for (__kindof NSObject *target in targets) {
            _YJKVOSubscriberManager *subscriberManager = target.yj_KVOSubscriberManager;
            [subscriberManager removeSubscriber:subscriber];
        }
    }
}

@end
