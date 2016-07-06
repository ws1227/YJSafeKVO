//
//  NSObject+YJClassObjectChecking.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+YJClassObjectChecking.h"

@implementation NSObject (YJClassObjectChecking)

BOOL yj_object_isClass(id obj) {
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_10
        return object_isClass(obj);
    #else
        return obj == [obj class];
    #endif
}

@end
