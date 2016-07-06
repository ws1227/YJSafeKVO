//
//  NSObject+YJKVOExtension.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOManager.h"
#import "_YJKVOTracker.h"

/* ------------------------- */
//         YJKVOTarget
/* ------------------------- */

@implementation NSObject (YJKVOTarget)

- (void)setYj_KVOManager:(_YJKVOManager *)yj_KVOManager {
    objc_setAssociatedObject(self, @selector(yj_KVOManager), yj_KVOManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOManager *)yj_KVOManager {
    return objc_getAssociatedObject(self, _cmd);
}

@end


/* ------------------------- */
//       YJKVOObserver
/* ------------------------- */

@implementation NSObject (YJKVOObserver)

- (void)setYj_KVOTracker:(_YJKVOTracker *)yj_KVOTracker {
    objc_setAssociatedObject(self, @selector(yj_KVOTracker), yj_KVOTracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOTracker *)yj_KVOTracker {
    return objc_getAssociatedObject(self, _cmd);
}

@end