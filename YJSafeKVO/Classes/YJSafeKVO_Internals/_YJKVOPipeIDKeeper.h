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
/// This class will be attached to observer.

__attribute__((visibility("hidden")))
@interface _YJKVOPipeIDKeeper : NSObject

/// designated initializer
- (instancetype)initWithObserver:(id)observer;

/// add pipe identifier
- (void)addPipeIdentifier:(NSString *)pipeIdentifier;

/// returns all related pipe identifiers
- (NSArray *)pipeIdentifiers;

@end

NS_ASSUME_NONNULL_END