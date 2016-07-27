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

@interface YJKVOPacker ()
@property (nonatomic, strong) __kindof NSObject *object;
@property (nonatomic, copy) NSString *keyPath;
@property (nullable, nonatomic, assign) _YJKVOBindingPorter *bindingPorter;
@property (nullable, nonatomic, assign) __kindof NSObject *implicitSubscriber;
@end

@implementation YJKVOPacker

- (instancetype)initWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath {
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = [keyPath copy];
    }
    return self;
}

- (instancetype)init {
    [NSException raise:NSGenericException format:@"Do not call init directly for %@.", self.class];
    return [self initWithObject:(id)[NSNull null] keyPath:(id)[NSNull null]];
}

+ (instancetype)packerWithObject:(__kindof NSObject *)object
                         keyPath:(NSString *)keyPath
                              on:(nullable __kindof NSObject *)on {
    
    YJKVOPacker *packer = [[self alloc] initWithObject:object keyPath:keyPath];
    packer.implicitSubscriber = on;
    return packer;
}

- (BOOL)isValid {
    if (![self isKindOfClass:[YJKVOPacker class]]) return NO;
    NSAssert(self.object != nil, @"YJSafeKVO - Target can not be nil for Key value observing.");
    NSAssert(self.keyPath.length > 0, @"YJSafeKVO - KeyPath can not be empty for Key value observing.");
    return self.object && self.keyPath.length;
}

@end


@implementation YJKVOPacker (YJKVOSubscribing)

- (void)bound:(PACK)targetAndKeyPath {
    [self _pipedFrom:targetAndKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (id)piped:(PACK)targetAndKeyPath {
    [self _pipedFrom:targetAndKeyPath options:NSKeyValueObservingOptionNew];
    return targetAndKeyPath;
}

- (void)ready {
    [self.object setValue:[self.object valueForKeyPath:self.keyPath] forKeyPath:self.keyPath];
    self.bindingPorter = nil;
}

- (void)_pipedFrom:(PACK)targetAndKeyPath options:(NSKeyValueObservingOptions)options {
    if (self.isValid && targetAndKeyPath.isValid) {
        
        __kindof NSObject *target = targetAndKeyPath.object;
        __kindof NSObject *subscriber = self.object;
        NSString *targetKeyPath = targetAndKeyPath.keyPath;
        NSString *subscriberKeyPath = self.keyPath;

        _YJKVOBindingPorter *porter = [[_YJKVOBindingPorter alloc] initWithTarget:target
                                                                       subscriber:subscriber
                                                                    targetKeyPath:targetKeyPath
                                                                subscriberKeyPath:subscriberKeyPath];
        porter.observingOptions = options;
        [targetAndKeyPath setBindingPorter:porter];
        
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

- (void)flooded:(NSArray <PACK> *)targetsAndKeyPaths reduce:(nullable id(^)())reduce {
    if (!self.isValid || !targetsAndKeyPaths.count)
        return;
    
    __kindof NSObject *subscriber = self.object;
    NSString *subscriberKeyPath = self.keyPath;
    
    _YJKVOGroupingPorter *porter = [[_YJKVOGroupingPorter alloc] initWithSubscriber:subscriber];
    porter.subscriberKeyPath = subscriberKeyPath;
    porter.reduceValueReturnHandler = reduce;
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            [porter addTarget:targetAndKeyPath.object keyPath:targetAndKeyPath.keyPath];
        }
    }
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (targetAndKeyPath.isValid) {
            [[_YJKVOExecutiveOfficer officer] organizeTarget:targetAndKeyPath.object subscriber:subscriber porter:porter];
        }
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


@implementation YJKVOPacker (YJKVOPosting)

- (void)post:(void (^)(id self, id _Nullable))post {
    if (self.isValid) {
        __kindof NSObject *target = self.object;
        __kindof NSObject *subscriber = self.implicitSubscriber;
        NSString *keyPath = self.keyPath;
        
        _YJKVOPorter *porter = [[_YJKVOPorter alloc] initWithTarget:target subscriber:subscriber targetKeyPath:keyPath];
        porter.valueHandler = post;
        
        [[_YJKVOExecutiveOfficer officer] organizeTarget:target subscriber:subscriber porter:porter];
    }
    self.implicitSubscriber = nil;
}

- (void)stopPosting {
    if (self.isValid) {
        __kindof NSObject *target = self.object;
        __kindof NSObject *subscriber = self.implicitSubscriber;
        NSString *keyPath = self.keyPath;
        
        [[_YJKVOExecutiveOfficer officer] dismissPortersFromTarget:target andSubscriber:subscriber forTargetKeyPath:keyPath];
    }
    self.implicitSubscriber = nil;
}

- (void)stop {
    [self stopPosting];
}

@end
