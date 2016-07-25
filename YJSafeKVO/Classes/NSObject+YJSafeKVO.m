//
//  NSObject+YJSafeKVO.m
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJSafeKVO.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOPorter.h"
#import "_YJKVOGroupingPorter.h"
#import "_YJKVOExecutiveOfficer.h"

#pragma mark - YJSafeKVO implementations

YJKVOChangeHandler (^yj_convertedKVOChangeHandler)(YJKVOObjectsAndValueHandler) = ^YJKVOChangeHandler(YJKVOObjectsAndValueHandler objectsAndValueHander) {
    void(^changeHandler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
        if (objectsAndValueHander) objectsAndValueHander(receiver, target, newValue);
    };
    return changeHandler;
};

@implementation NSObject (YJSafeKVO)

- (void)observe:(PACK)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    if (targetAndKeyPath.isValid) {
        [self observeTarget:targetAndKeyPath.object
                    keyPath:targetAndKeyPath.keyPath
                    options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                      queue:nil
                    changes:yj_convertedKVOChangeHandler(updates)];
    }
}

- (void)observeGroup:(NSArray <PACK> *)targetsAndKeyPaths updates:(void(^)(id receiver, NSArray *targets))updates {
    
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsAndKeyPaths.count];
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        if (!targetAndKeyPath.isValid) return;
        [targets addObject:targetAndKeyPath.object];
    }
    
    for (PACK targetAndKeyPath in targetsAndKeyPaths) {
        
        __kindof NSObject *target = targetAndKeyPath.object;
        __kindof NSObject *subscriber = self;
        NSString *targetKeyPath = targetAndKeyPath.keyPath;
        
        _YJKVOGroupingPorter *porter = [[_YJKVOGroupingPorter alloc] initWithTarget:target
                                                                         subscriber:subscriber
                                                                      targetKeyPath:targetKeyPath];
        porter.targetsHandler = updates;
        [porter associateWithGroupTarget:targets];
        
        [[_YJKVOExecutiveOfficer officer] organizeTarget:target subscriber:subscriber porter:porter];
    }
}

- (void)observe:(PACK)targetAndKeyPath
        options:(NSKeyValueObservingOptions)options
          queue:(nullable NSOperationQueue *)queue
        changes:(void(^)(id receiver, id target, id _Nullable newValue, NSDictionary *change))changes {
    
    if (targetAndKeyPath.isValid) {
        [self observeTarget:targetAndKeyPath.object
                    keyPath:targetAndKeyPath.keyPath
                    options:options
                      queue:queue
                    changes:changes];
    }
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    
    [self observeTarget:target
                keyPath:keyPath
                options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                  queue:nil
                changes:yj_convertedKVOChangeHandler(updates)];
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
                queue:(nullable NSOperationQueue *)queue
              changes:(void(^)(id receiver, id target, id _Nullable newValue, NSDictionary *change))changes {
    
    _YJKVOPorter *porter = [[_YJKVOPorter alloc] initWithTarget:target subscriber:self targetKeyPath:keyPath];
    porter.observingOptions = options;
    porter.changeHandler = changes;
    
    [[_YJKVOExecutiveOfficer officer] organizeTarget:target subscriber:self porter:porter];
}

- (void)unobserve:(PACK)targetAndKeyPath {
    if (targetAndKeyPath.isValid) {
        [self unobserveTarget:targetAndKeyPath.object keyPath:targetAndKeyPath.keyPath];
    }
}

- (void)unobserveTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    [[_YJKVOExecutiveOfficer officer] dismissPortersFromTarget:target andSubscriber:self forTargetKeyPath:keyPath];
}

- (void)unobserveAll {
    [[_YJKVOExecutiveOfficer officer] dismissSubscriber:self];
}

@end
