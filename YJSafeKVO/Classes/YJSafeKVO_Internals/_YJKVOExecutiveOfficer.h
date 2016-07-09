//
//  _YJKVOExecutiveOfficer.h
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorter;

/// This class is responsible for organizing the internal objects,
/// including assigning duty to each class.

__attribute__((visibility("hidden")))
@interface _YJKVOExecutiveOfficer : NSObject

/// singleton object
+ (instancetype)officer;

/// add porter to Apple's KVO and manage it by other classes.
- (void)registerPorter:(__kindof _YJKVOPorter *)porter
           forObserver:(__kindof NSObject *)observer
                target:(__kindof NSObject *)target
         targetKeyPath:(NSString *)targetKeyPath
               options:(NSKeyValueObservingOptions)options;

/// remove porters out of KVO.
- (void)unregisterPortersForObserver:(__kindof NSObject *)observer
                          fromTarget:(__kindof NSObject *)target
                       targetKeyPath:(NSString *)targetKeyPath;

/// remove porters out of KVO.
- (void)unregisterPortersForObserver:(__kindof NSObject *)observer;

@end
