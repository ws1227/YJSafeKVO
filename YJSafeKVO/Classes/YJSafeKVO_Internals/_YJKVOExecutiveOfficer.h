//
//  _YJKVOExecutiveOfficer.h
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class _YJKVOPorter;

/// This class is responsible for organizing the internal objects,
/// including assigning duty to each class.

__attribute__((visibility("hidden")))
@interface _YJKVOExecutiveOfficer : NSObject

/// singleton object
+ (instancetype)officer;

/// register KVO and organize all related objects into KVO chain.
- (void)organizeTarget:(__kindof NSObject *)target
            subscriber:(__kindof NSObject *)subscriber
                porter:(__kindof _YJKVOPorter *)porter;

/// dismiss specified target from KVO chain.
- (void)dismissTarget:(__kindof NSObject *)target;

/// dismiss related porters from KVO chain.
- (void)dismissPortersFromTarget:(__kindof NSObject *)target
                   andSubscriber:(__kindof NSObject *)subscriber
                forTargetKeyPath:(NSString *)targetKeyPath;

/// dismiss related porters from KVO chain, with specific subscriberKeyPath.
- (void)dismissPortersFromTarget:(__kindof NSObject *)target
                   andSubscriber:(__kindof NSObject *)subscriber
                forTargetKeyPath:(NSString *)targetKeyPath
            andSubscriberKeyPath:(nullable NSString *)subscriberKeyPath;

/// dismiss specified subscriber from KVO chain.
- (void)dismissSubscriber:(__kindof NSObject *)subscriber;


@end

NS_ASSUME_NONNULL_END
