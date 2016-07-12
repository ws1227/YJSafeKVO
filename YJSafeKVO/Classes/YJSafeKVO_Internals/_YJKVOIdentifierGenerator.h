//
//  _YJKVOIdentifierGenerator.h
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

/// This class is for generating string identifiers.

__attribute__((visibility("hidden")))
@interface _YJKVOIdentifierGenerator : NSObject


/// singleton object
+ (instancetype)sharedGenerator;


/// e.g. "Target<0x123>.keyPath|Observer<0x456>.keyPath"
///
- (NSString *)pipeIdentifierForObserver:(__kindof NSObject *)observer
                        observerKeyPath:(NSString *)observerKeyPath
                                 target:(__kindof NSObject *)target
                          targetKeyPath:(NSString *)targetKeyPath;


/// e.g. "Object<0x123>.keyPath"
///
- (NSString *)keyValueCodingIdentifierForObject:(__kindof NSObject *)object
                                        keyPath:(NSString *)keyPath;

@end
