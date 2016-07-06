//
//  _YJKVOPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPorter.h"

@implementation _YJKVOPorter

- (instancetype)initWithObserver:(__kindof NSObject *)observer
                           queue:(nullable NSOperationQueue *)queue
                         handler:(nullable YJKVOHandler)handler {
    self = [super init];
    if (self) {
        _observer = observer;
        _queue = queue;
        _handler = handler ? [handler copy] : nil;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [[NSString stringWithFormat:@"%p", self] isEqualToString:[NSString stringWithFormat:@"%p", object]];
}

- (__kindof NSObject *)observer {
    return _observer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id observer = self->_observer;
    YJKVOHandler handler = self->_handler;
    
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (handler) handler(observer, object, newValue, change);
    };
    
    if (self->_queue) {
        [self->_queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

- (void)dealloc {
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end
