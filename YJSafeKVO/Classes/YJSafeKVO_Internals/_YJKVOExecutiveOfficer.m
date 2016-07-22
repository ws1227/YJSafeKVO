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
#import "_YJKVOBindingPorter.h"

/*
    Remember: 
 
    1. Always explicitly resign porter object here, even though porter can be auto resigning before deallocated for protection.
    2. Target and subscriber might be the same object sometimes!
 
 */

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
    
    // sign up porter
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
        porterManager = [[_YJKVOPorterManager alloc] initWithOwner:subscriber];
        subscriber.yj_KVOPorterManager = porterManager;
    }
    [porterManager addPorter:porter];
    
    // resign porter before target or subscriber is deallocated
    [target performBlockBeforeDeallocating:^(__kindof NSObject *target) {
        [self dismissTarget:target];
    }];
    
    [subscriber performBlockBeforeDeallocating:^(__kindof NSObject *subscriber) {
        [self dismissSubscriber:subscriber];
    }];
}

- (void)organizeSender:(__kindof NSObject *)sender
                porter:(__kindof _YJKVOPorter *)porter {
    
    [porter signUp];
    
    _YJKVOPorterManager *porterManager = sender.yj_KVOPorterManager;
    if (!porterManager) {
        porterManager = [[_YJKVOPorterManager alloc] initWithOwner:sender];
        sender.yj_KVOPorterManager = porterManager;
    }
    [porterManager addPorter:porter];
    
    [sender performBlockBeforeDeallocating:^(__kindof NSObject *sender) {
        [self dismissSender:sender];
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
    
    [self dismissPortersFromTarget:target
                     andSubscriber:subscriber
                  forTargetKeyPath:targetKeyPath
              andSubscriberKeyPath:nil];
}

- (void)dismissPortersFromTarget:(__kindof NSObject *)target
                   andSubscriber:(__kindof NSObject *)subscriber
                forTargetKeyPath:(NSString *)targetKeyPath
            andSubscriberKeyPath:(nullable NSString *)subscriberKeyPath {
    
    @autoreleasepool {
        BOOL shouldMatchSubscriberKeyPath = (subscriberKeyPath.length > 0);
        // the target might be in the middle of deallocating, so don't use __weak here.
        __unsafe_unretained id targetPtr = target;
        
        _YJKVOSubscriberManager *subscriberManager = target.yj_KVOSubscriberManager;
        NSMutableArray *subscribers = [NSMutableArray arrayWithCapacity:subscriberManager.numberOfSubscribers];
        
        [subscriberManager enumerateSubscribersUsingBlock:^(__kindof NSObject * _Nonnull subscriber, BOOL * _Nonnull stop) {
            
            _YJKVOPorterManager *porterManager = subscriber.yj_KVOPorterManager;
            NSMutableArray *porters = [NSMutableArray arrayWithCapacity:porterManager.numberOfPorters];
            
            [porterManager enumeratePortersUsingBlock:^(__kindof _YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
                
                if (shouldMatchSubscriberKeyPath && porter.target == targetPtr &&
                    [porter respondsToSelector:@selector(subscriberKeyPath)]) {
                    
                    NSString *storedSubscriberKeyPath = [porter subscriberKeyPath];
                    
                    if ([porter.targetKeyPath isEqualToString:targetKeyPath] &&
                        [storedSubscriberKeyPath isEqualToString:subscriberKeyPath]) {
                        
                        [porter resign];
                        [porters addObject:porter];
                    }
                } else if (porter.target == targetPtr && [porter.targetKeyPath isEqualToString:targetKeyPath]) {
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
        [porterManager enumeratePortersUsingBlock:^(__kindof _YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
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

- (void)dismissSender:(__kindof NSObject *)sender {
    @autoreleasepool {
        [sender.yj_KVOPorterManager enumeratePortersUsingBlock:^(__kindof _YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
            [porter resign];
        }];
        [sender.yj_KVOPorterManager removeAllPorters];
    }
}

- (void)dismissSender:(__kindof NSObject *)sender forKeyPath:(NSString *)keyPath {
    @autoreleasepool {
        _YJKVOPorterManager *porterManager = sender.yj_KVOPorterManager;
        NSMutableArray *porters = [NSMutableArray arrayWithCapacity:porterManager.numberOfPorters];
        
        [porterManager enumeratePortersUsingBlock:^(__kindof _YJKVOPorter * _Nonnull porter, BOOL * _Nonnull stop) {
            if ([keyPath isEqualToString:porter.targetKeyPath]) {
                [porter resign];
                [porters addObject:porter];
            }
        }];
        
        if (porters.count) {
            [porterManager removePorters:porters];
        }
    }
}

@end
