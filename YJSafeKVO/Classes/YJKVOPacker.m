//
//  YJKVOPacker.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "YJKVOPacker.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOExecutiveOfficer.h"
#import "_YJKVOBindingPorter.h"
#import "_YJKVOGroupingPorter.h"
#import "_YJKVOPipeIDKeeper.h"
#import "_YJKVOIdentifierGenerator.h"

@interface YJKVOPacker ()
@property (nonatomic, strong) __kindof NSObject *object;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, weak) _YJKVOBindingPorter *bindingPorter;
@end

@implementation YJKVOPacker

+ (instancetype)packerWithObject:(__kindof NSObject *)object
                         keyPath:(NSString *)keyPath
                    variableName:(nullable NSString *)variableName {
    
    object.yj_KVOVariableName = variableName;
    
    YJKVOPacker *packer = [YJKVOPacker new];
    packer.object = object;
    packer.keyPath = keyPath;
    return packer;
}

- (BOOL)isValid {
    if (![self isKindOfClass:[YJKVOPacker class]]) return NO;
    NSAssert(self.object != nil, @"YJSafeKVO - Target can not be nil for Key value observing.");
    NSAssert(self.keyPath.length > 0, @"YJSafeKVO - KeyPath can not be empty for Key value observing.");
    return self.object && self.keyPath.length;
}

@end


@implementation YJKVOPacker (YJKVOBinding)

- (void)bound:(PACK)targetAndKeyPath {
    [self _pipedFrom:targetAndKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (id)piped:(PACK)targetAndKeyPath {
    [self _pipedFrom:targetAndKeyPath options:NSKeyValueObservingOptionNew];
    return targetAndKeyPath;
}

- (void)ready {
    [self.object setValue:[self.object valueForKeyPath:self.keyPath] forKeyPath:self.keyPath];
}

- (void)_pipedFrom:(PACK)targetAndKeyPath options:(NSKeyValueObservingOptions)options {
    if (targetAndKeyPath.isValid) {
        __kindof NSObject *observer = self.object;
        NSString *observerKeyPath = self.keyPath;
        
        // generate pipe id
        NSString *identifier = [[_YJKVOIdentifierGenerator sharedGenerator] pipeIdentifierForObserver:observer
                                                                                      observerKeyPath:observerKeyPath
                                                                                               target:targetAndKeyPath.object
                                                                                        targetKeyPath:targetAndKeyPath.keyPath];
        // keep pipe id
        _YJKVOPipeIDKeeper *pipeIDKeeper = observer.yj_KVOPipeIDKeeper;
        if (!pipeIDKeeper) {
            pipeIDKeeper = [[_YJKVOPipeIDKeeper alloc] initWithObserver:observer];
            observer.yj_KVOPipeIDKeeper = pipeIDKeeper;
        }
        [pipeIDKeeper addPipeIdentifier:identifier];
        
        // generate pipe porter
        _YJKVOBindingPorter *porter = [[_YJKVOBindingPorter alloc] initWithObserver:observer
                                                                    observerKeyPath:observerKeyPath];
        [targetAndKeyPath setBindingPorter:porter];
        
        // register pipe porter
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

- (void)flooded:(NSArray <PACK> *)targetsAndKeyPaths converge:(id(^)(id observer, NSArray *targets))converge {
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            [targets addObject:targetAndKeyPath.object];
        }
    }
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            
            _YJKVOGroupingPorter *porter = [_YJKVOGroupingPorter porterForObserver:self.object
                                                                   observerKeyPath:self.keyPath
                                                                           targets:[targets copy]
                                                                           handler:converge];
            [[_YJKVOExecutiveOfficer officer] registerPorter:porter
                                                 forObserver:self.object
                                                      target:targetAndKeyPath.object
                                               targetKeyPath:targetAndKeyPath.keyPath
                                                     options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)];
        }
    }
}

@end

// Retrieve target out of array.
id _YJKVO_retrieveTarget(NSArray *targets, NSString *variableName) {
    for (__kindof NSObject *target in targets) {
        if ([target.yj_KVOVariableName isEqualToString:variableName]) {
            return target;
        }
    }
    return nil;
}
