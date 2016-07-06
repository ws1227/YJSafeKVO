//
//  _YJKVOSeniorPorter.m
//  YJKit
//
//  Created by Jack Huang on 16/7/5.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOSeniorPorter.h"

@implementation _YJKVOSeniorPorter {
    NSHashTable *_targets;
    YJKVOGroupHandler _groupHandler;
}

- (instancetype)initWithObserver:(__kindof NSObject *)observer
                         targets:(NSArray <__kindof NSObject *> *)targets
                           queue:(nullable NSOperationQueue *)queue
                    groupHandler:(YJKVOGroupHandler)groupHandler {
    self = [super initWithObserver:observer queue:queue handler:nil];
    if (self) {
        _groupHandler = groupHandler ? [groupHandler copy] : nil;
        _targets = [NSHashTable weakObjectsHashTable];
        for (id target in targets) {
            [_targets addObject:target];
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id observer = self->_observer;
    NSArray *targets = [self->_targets allObjects];
    YJKVOGroupHandler groupHandler = self->_groupHandler;
    
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (groupHandler) groupHandler(observer, targets);
    };
    
    if (self->_queue) {
        [self->_queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

@end
