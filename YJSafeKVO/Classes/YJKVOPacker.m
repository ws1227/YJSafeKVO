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

- (instancetype)initWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath {
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = keyPath;
    }
    return self;
}

- (instancetype)init {
    [NSException raise:NSGenericException format:@"Do not call init directly for %@.", self.class];
    return [self initWithObject:(id)[NSNull null] keyPath:(id)[NSNull null]];
}

+ (instancetype)packerWithObject:(__kindof NSObject *)object
                         keyPath:(NSString *)keyPath
                    variableName:(nullable NSString *)variableName {
    
    object.yj_KVOVariableName = variableName;
    return [[self alloc] initWithObject:object keyPath:keyPath];
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
    if (self.isValid && targetAndKeyPath.isValid) {
        
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
    
    if (!self.isValid) return;
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (!targetAndKeyPath.isValid) return;
        [targets addObject:targetAndKeyPath.object];
    }
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        
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

- (void)cutOff:(PACK)targetAndKeyPath {
    if (self.isValid && targetAndKeyPath.isValid) {
        
        __kindof NSObject *target = targetAndKeyPath.object;
        __kindof NSObject *subscriber = self.object;
        
        NSString *targetKeyPath = targetAndKeyPath.keyPath;
        NSString *subscriberKeyPath = self.keyPath;
        
        [[_YJKVOExecutiveOfficer officer] dismissPortersFromTarget:target
                                                     andSubscriber:subscriber
                                                  forTargetKeyPath:targetKeyPath
                                              andSubscriberKeyPath:subscriberKeyPath];
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


@implementation YJKVOPacker (YJKVOPosting)

- (void)post:(void (^)(id _Nullable))post {
    if (self.isValid) {
        __kindof NSObject *sender = self.object;
        __kindof NSObject *keyPath = self.keyPath;
        
        _YJKVOPorter *porter = [[_YJKVOPorter alloc] initWithTarget:sender subscriber:nil targetKeyPath:keyPath];
        porter.valueHandler = post;
        
        [[_YJKVOExecutiveOfficer officer] organizeSender:sender porter:porter];
    }
}

- (void)stop {
    if (self.isValid) {
        __kindof NSObject *sender = self.object;
        __kindof NSObject *keyPath = self.keyPath;
        
        if (sender.yj_KVOPorterManager) {
            [[_YJKVOExecutiveOfficer officer] dismissSender:sender forKeyPath:keyPath];
        }
    }
}

@end
