//
//  _YJKVOGroupingPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/5.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOGroupingPorter.h"

@interface _YJKVOGroupingPorter ()
@property (nonatomic, strong) NSHashTable *groupTargets;
@end

@implementation _YJKVOGroupingPorter

- (instancetype)initWithTarget:(__kindof NSObject *)target subscriber:(__kindof NSObject *)subscriber targetKeyPath:(NSString *)targetKeyPath {
    self = [super initWithTarget:target subscriber:subscriber targetKeyPath:targetKeyPath];
    if (self) {
        _groupTargets = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)associateWithGroupTarget:(NSArray <__kindof NSObject *> *)groupTargets {
    for (id target in groupTargets) {
        [self.groupTargets addObject:target];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    if (self.targetsHandler) {
        self.targetsHandler(self.subscriber, [self.groupTargets allObjects]);
    }
    
    if (self.targetsReturnHandler && self.subscriberKeyPath.length) {
        id mergedValue = self.targetsReturnHandler(self.subscriber, [self.groupTargets allObjects]);
        [self.subscriber setValue:mergedValue forKeyPath:self.subscriberKeyPath];
    }
}

@end
