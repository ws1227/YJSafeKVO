//
//  _YJKVOGuardian.m
//  YJKit
//
//  Created by huang-kun on 16/7/14.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOGuardian.h"
#import <objc/runtime.h>


@implementation _YJKVOGuardian

+ (instancetype)guardian {
    static _YJKVOGuardian *guardian;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        guardian = [_YJKVOGuardian new];
    });
    return guardian;
}

- (nullable IMP)applyIdentityComparisonForObject:(__kindof NSString *)object {
    
    SEL equalitySEL = @selector(isEqual:);
    Method equalityMtd = class_getInstanceMethod([object class], equalitySEL);
    const char *equalityType = method_getTypeEncoding(equalityMtd);
    
    IMP objectEqualityIMP = nil;
    IMP tempEqualityIMP = imp_implementationWithBlock(^BOOL(__unsafe_unretained id obj1, __unsafe_unretained id obj2){
        return obj1 == obj2;
    });
    
    // add pointer comparison version of -isEqual:
    __unused BOOL added = class_addMethod([object class], equalitySEL, tempEqualityIMP, equalityType);
    
    if (!added) {
        // if -isEqual: is implemented, then switch its IMP to pointer comparison IMP
        equalityMtd = class_getInstanceMethod([object class], equalitySEL);
        objectEqualityIMP = method_getImplementation(equalityMtd);
        method_setImplementation(equalityMtd, tempEqualityIMP);
    }
    
    return objectEqualityIMP;
}

- (void)applyEqualityComparisonForObject:(__kindof NSString *)object implementation:(nullable IMP)equalityIMP {
    if (equalityIMP) {
        Method equalityMtd = class_getInstanceMethod([object class], @selector(isEqual:));
        method_setImplementation(equalityMtd, equalityIMP);
    }
}

@end
