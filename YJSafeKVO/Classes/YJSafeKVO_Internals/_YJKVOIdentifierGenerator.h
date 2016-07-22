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

/// Generating a data flow identifier for each pipe.
/// e.g. "Target<0x123>.keyPath|Subscriber<0x456>.keyPath"
///
- (NSString *)pipeIdentifierForTarget:(__kindof NSObject *)target
                           subscriber:(__kindof NSObject *)subscriber
                        targetKeyPath:(NSString *)targetKeyPath
                    subscriberKeyPath:(NSString *)subscriberKeyPath;

@end
