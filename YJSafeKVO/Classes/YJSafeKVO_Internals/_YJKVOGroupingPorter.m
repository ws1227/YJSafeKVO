//
//  _YJKVOGroupingPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/5.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOGroupingPorter.h"

@implementation _YJKVOGroupingPorter {
    NSHashTable *_targets;
    YJKVOTargetsHandler _targetsHandler;
}

- (instancetype)initWithObserver:(__kindof NSObject *)observer
                         targets:(NSArray <__kindof NSObject *> *)targets
                           queue:(nullable NSOperationQueue *)queue
                    targetsHandler:(YJKVOTargetsHandler)targetsHandler {
    self = [super initWithObserver:observer queue:queue handler:nil];
    if (self) {
        _targetsHandler = targetsHandler ? [targetsHandler copy] : nil;
        _targets = [NSHashTable weakObjectsHashTable];
        for (id target in targets) {
            [_targets addObject:target];
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id observer = self.observer;
    NSArray *targets = [self->_targets allObjects];
    YJKVOTargetsHandler targetsHandler = self->_targetsHandler;
    
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (targetsHandler) targetsHandler(observer, targets);
    };
    
    if (self.queue) {
        [self.queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

@end
