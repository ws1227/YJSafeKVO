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
        
        __kindof NSObject *target = targetAndKeyPath.object;
        __kindof NSObject *subscriber = self.object;
        NSString *targetKeyPath = targetAndKeyPath.keyPath;
        NSString *subscriberKeyPath = self.keyPath;

        // generate pipe id
        NSString *identifier = [[_YJKVOIdentifierGenerator sharedGenerator] pipeIdentifierForTarget:target
                                                                                         subscriber:subscriber
                                                                                      targetKeyPath:targetKeyPath
                                                                                  subscriberKeyPath:subscriberKeyPath];
        // keep pipe id
        _YJKVOPipeIDKeeper *pipeIDKeeper = subscriber.yj_KVOPipeIDKeeper;
        if (!pipeIDKeeper) {
            pipeIDKeeper = [[_YJKVOPipeIDKeeper alloc] initWithSubscriber:subscriber];
            subscriber.yj_KVOPipeIDKeeper = pipeIDKeeper;
        }
        [pipeIDKeeper addPipeIdentifier:identifier];
        
        // generate pipe porter
        _YJKVOBindingPorter *porter = [[_YJKVOBindingPorter alloc] initWithTarget:target
                                                                       subscriber:subscriber
                                                                    targetKeyPath:targetKeyPath
                                                                subscriberKeyPath:subscriberKeyPath];
        porter.observingOptions = options;
        [targetAndKeyPath setBindingPorter:porter];
        
        // register pipe porter
        [[_YJKVOExecutiveOfficer officer] organizeTarget:target subscriber:subscriber porter:porter];
    }
}

- (id)taken:(BOOL(^)(id subscriber, id target, id newValue))taken {
    self.bindingPorter.takenHandler = taken;
    return self;
}

- (id)convert:(id(^)(id subscriber, id target, id newValue))convert {
    self.bindingPorter.convertHandler = convert;
    return self;
}

- (id)after:(void(^)(id subscriber, id target))after {
    self.bindingPorter.afterHandler = after;
    return self;
}

- (void)flooded:(NSArray <PACK> *)targetsAndKeyPaths converge:(id(^)(id subscriber, NSArray *targets))converge {
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            [targets addObject:targetAndKeyPath.object];
        }
    }
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            
            __kindof NSObject *target = targetAndKeyPath.object;
            __kindof NSObject *subscriber = self.object;
            NSString *targetKeyPath = targetAndKeyPath.keyPath;
            NSString *subscriberKeyPath = self.keyPath;
            
            _YJKVOGroupingPorter *porter = [[_YJKVOGroupingPorter alloc] initWithTarget:target
                                                                             subscriber:subscriber
                                                                          targetKeyPath:targetKeyPath];
            porter.subscriberKeyPath = subscriberKeyPath;
            porter.targetsReturnHandler = converge;
            [porter associateWithGroupTarget:targets];
            
            [[_YJKVOExecutiveOfficer officer] organizeTarget:target subscriber:subscriber porter:porter];
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
