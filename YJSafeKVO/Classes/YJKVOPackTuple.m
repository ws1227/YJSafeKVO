//
//  YJKVOPackTuple.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "YJKVOPackTuple.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOExecutiveOfficer.h"
#import "_YJKVOBindingPorter.h"
#import "_YJKVOBindingManager.h"
#import "_YJKVOIdentifierGenerator.h"

@interface YJKVOPackTuple ()
@property (nonatomic, strong) __kindof NSObject *object;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, weak) _YJKVOBindingPorter *bindingPorter;
@end

@implementation YJKVOPackTuple

+ (instancetype)tupleWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath {
    YJKVOPackTuple *tuple = [YJKVOPackTuple new];
    tuple.object = object;
    tuple.keyPath = keyPath;
    return tuple;
}

- (BOOL)isValid {
    if (![self isKindOfClass:[YJKVOPackTuple class]]) return NO;
    NSAssert(self.object != nil, @"YJSafeKVO - Target can not be nil for Key value observing.");
    NSAssert(self.keyPath.length > 0, @"YJSafeKVO - KeyPath can not be empty for Key value observing.");
    return self.object && self.keyPath.length;
}

@end


@implementation YJKVOPackTuple (YJKVOBinding)

- (void)pipe:(PACK)targetAndKeyPath {
    [self _bind:targetAndKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (id)bind:(PACK)targetAndKeyPath {
    [self _bind:targetAndKeyPath options:NSKeyValueObservingOptionNew];
    return targetAndKeyPath;
}

- (void)_bind:(PACK)targetAndKeyPath options:(NSKeyValueObservingOptions)options {
    if (targetAndKeyPath.isValid) {
        __kindof NSObject *observer = self.object;
        NSString *observerKeyPath = self.keyPath;
        
        // generate binding id
        NSString *identifier = [[_YJKVOIdentifierGenerator sharedGenerator] bindingIdentifierForObserver:observer
                                                                                         observerKeyPath:observerKeyPath
                                                                                                  target:targetAndKeyPath.object
                                                                                           targetKeyPath:targetAndKeyPath.keyPath];
        // keep binding id
        _YJKVOBindingManager *bindingManager = observer.yj_KVOBindingManager;
        if (!bindingManager) {
            bindingManager = [[_YJKVOBindingManager alloc] initWithObserver:observer];
            observer.yj_KVOBindingManager = bindingManager;
        }
        [bindingManager addBindingIdentifer:identifier];
        
        // generate binding porter
        _YJKVOBindingPorter *porter = [[_YJKVOBindingPorter alloc] initWithObserver:observer
                                                                    observerKeyPath:observerKeyPath];
        [targetAndKeyPath setBindingPorter:porter];
        
        // register binding porter
        [[_YJKVOExecutiveOfficer officer] registerPorter:porter
                                             forObserver:observer
                                                  target:targetAndKeyPath.object
                                           targetKeyPath:targetAndKeyPath.keyPath
                                                 options:options];
    }
}

- (id)taken:(BOOL(^)(id observer, id target, id newValue))taken {
    self.bindingPorter.takenHandler = taken;
    return self;
}

- (id)convert:(id(^)(id observer, id target, id newValue))convert {
    self.bindingPorter.convertHandler = convert;
    return self;
}

- (id)after:(void(^)(id observer, id target))after {
    self.bindingPorter.afterHandler = after;
    return self;
}

@end