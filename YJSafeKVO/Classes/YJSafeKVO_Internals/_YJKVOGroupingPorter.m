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
    NSString *_observerKeyPath;
    YJKVOTargetsHandler _targetsHandler;
    YJKVOTargetsReturnHandler _targetsReturnHandler;
}

+ (instancetype)porterForObserver:(__kindof NSObject *)observer
                          targets:(NSArray <__kindof NSObject *> *)targets
                          handler:(YJKVOTargetsHandler)targetsHandler {
    
    _YJKVOGroupingPorter *porter = [[_YJKVOGroupingPorter alloc] initWithObserver:observer queue:nil handler:nil];
    porter->_targetsHandler = [targetsHandler copy];
    [porter setupTargets:targets];
    return porter;
}

+ (instancetype)porterForObserver:(__kindof NSObject *)observer
                  observerKeyPath:(NSString *)observerKeyPath
                          targets:(NSArray <__kindof NSObject *> *)targets
                          handler:(YJKVOTargetsReturnHandler)targetsReturnHandler {
    
    _YJKVOGroupingPorter *porter = [[_YJKVOGroupingPorter alloc] initWithObserver:observer queue:nil handler:nil];
    porter->_observerKeyPath = [observerKeyPath copy];
    porter->_targetsReturnHandler = [targetsReturnHandler copy];
    [porter setupTargets:targets];
    return porter;
}

- (void)setupTargets:(NSArray <__kindof NSObject *> *)targets {
    _targets = [NSHashTable weakObjectsHashTable];
    for (id target in targets) {
        [_targets addObject:target];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    __kindof NSObject *observer = self.observer;
    NSString *observerKeyPath = self->_observerKeyPath;
    
    NSArray *targets = [self->_targets allObjects];
    YJKVOTargetsHandler targetsHandler = self->_targetsHandler;
    YJKVOTargetsReturnHandler targetsReturnHandler = self->_targetsReturnHandler;
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    if (targetsHandler) {
        targetsHandler(observer, targets);
    }
    
    if (targetsReturnHandler) {
        id mergedValue = targetsReturnHandler(observer, targets);
        [observer setValue:mergedValue forKeyPath:observerKeyPath];
    }
}

@end
