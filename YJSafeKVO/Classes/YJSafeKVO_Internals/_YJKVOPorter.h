//
//  _YJKVOPorter.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_YJKVODefines.h"

NS_ASSUME_NONNULL_BEGIN

/// The class for deliver the value changes.

__attribute__((visibility("hidden")))
@interface _YJKVOPorter : NSObject

/// The designated initializer
- (instancetype)initWithObserver:(__kindof NSObject *)observer
                           queue:(nullable NSOperationQueue *)queue
                         handler:(nullable YJKVOChangeHandler)handler;

/// The observer matched with porter.
@property (nonatomic, readonly, weak) __kindof NSObject *observer;

/// The operation queue for adding block.
@property (nonatomic, readonly, strong) NSOperationQueue *queue;

/// The default handler for handling the value changes.
@property (nonatomic, readonly, copy) YJKVOChangeHandler handler;

@end

NS_ASSUME_NONNULL_END