//
//  _YJKVOGuardian.h
//  YJKit
//
//  Created by huang-kun on 16/7/14.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The protector class for spacial cases.
/// e.g. It will prevent NSMapTable crash when it triggers -isEqual: to key comparison,
///      and the keys can be different type of objects.

__attribute__((visibility("hidden")))
@interface _YJKVOGuardian : NSObject

/// singleton object
+ (instancetype)guardian;

/// make object using pointer equality for -isEqual: comparison, then returns the default -isEqual: IMP
/// @note the returned IMP is from object's own class, not from NSObject itself.
- (nullable IMP)applyIdentityComparisonForObject:(__kindof NSString *)object;

/// make object using provided equality IMP for -isEqual: comparison.
- (void)applyEqualityComparisonForObject:(__kindof NSString *)object
                          implementation:(nullable IMP)equalityIMP;

@end

NS_ASSUME_NONNULL_END