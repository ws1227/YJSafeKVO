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
@interface _YJKVOPorter : NSObject {
    @package
    __weak id _observer; // the object for handling the value changes
    YJKVOHandler _handler; // block for receiving value changes
    NSOperationQueue *_queue; // the operation queue to add the block
}

/// The designated initializer
- (instancetype)initWithObserver:(__kindof NSObject *)observer
                           queue:(nullable NSOperationQueue *)queue
                         handler:(nullable YJKVOHandler)handler;

/// The observer for each porter.
@property (nonatomic, weak, readonly) __kindof NSObject *observer;

@end

NS_ASSUME_NONNULL_END