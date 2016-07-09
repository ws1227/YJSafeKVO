//
//  NSObject+YJKVOExtension.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOPorterManager.h"
#import "_YJKVOPorterTracker.h"
#import "_YJKVOBindingManager.h"

@implementation NSObject (YJKVOExtension)

- (void)setYj_KVOPorterManager:(_YJKVOPorterManager *)yj_KVOPorterManager {
    objc_setAssociatedObject(self, @selector(yj_KVOPorterManager), yj_KVOPorterManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOPorterManager *)yj_KVOPorterManager {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOPorterTracker:(_YJKVOPorterTracker *)yj_KVOPorterTracker {
    objc_setAssociatedObject(self, @selector(yj_KVOPorterTracker), yj_KVOPorterTracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOPorterTracker *)yj_KVOPorterTracker {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOBindingManager:(_YJKVOBindingManager *)yj_KVOBindingManager {
    objc_setAssociatedObject(self, @selector(yj_KVOBindingManager), yj_KVOBindingManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOBindingManager *)yj_KVOBindingManager {
    return objc_getAssociatedObject(self, _cmd);
}

@end
