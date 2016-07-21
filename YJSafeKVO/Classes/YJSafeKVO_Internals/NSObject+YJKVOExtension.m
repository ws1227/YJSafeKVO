//
//  NSObject+YJKVOExtension.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJKVOExtension.h"

@implementation NSObject (YJKVOExtension)

- (void)setYj_KVOSubscriberManager:(_YJKVOSubscriberManager *)yj_KVOSubscriberManager {
    objc_setAssociatedObject(self, @selector(yj_KVOSubscriberManager), yj_KVOSubscriberManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOSubscriberManager *)yj_KVOSubscriberManager {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOPorterManager:(_YJKVOPorterManager *)yj_KVOPorterManager {
    objc_setAssociatedObject(self, @selector(yj_KVOPorterManager), yj_KVOPorterManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOPorterManager *)yj_KVOPorterManager {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOPipeIDKeeper:(_YJKVOPipeIDKeeper *)yj_KVOPipeIDKeeper {
    objc_setAssociatedObject(self, @selector(yj_KVOPipeIDKeeper), yj_KVOPipeIDKeeper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOPipeIDKeeper *)yj_KVOPipeIDKeeper {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOVariableName:(NSString *)yj_KVOVariableName {
    objc_setAssociatedObject(self, @selector(yj_KVOVariableName), yj_KVOVariableName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)yj_KVOVariableName {
    return objc_getAssociatedObject(self, _cmd);
}

@end
