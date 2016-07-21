//
//  _YJKVOPipeIDKeeper.h
//  YJKit
//
//  Created by huang-kun on 16/7/8.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Class for keeping identifiers associated with the KVO pipe feature.
/// This class will be attached to subscriber.

__attribute__((visibility("hidden")))
@interface _YJKVOPipeIDKeeper : NSObject

/// designated initializer
- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber NS_DESIGNATED_INITIALIZER;

/// add pipe identifier
- (void)addPipeIdentifier:(NSString *)pipeIdentifier;

/// check if contains this pipe identifiers
- (BOOL)containsPipeIdentifier:(NSString *)pipeIdentifier;

@end

NS_ASSUME_NONNULL_END