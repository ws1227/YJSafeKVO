//
//  _YJKVOBindingManager.h
//  YJKit
//
//  Created by huang-kun on 16/7/8.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Class for keeping identifiers associated with the KVO binding feature.
/// This class will be attached to observer.

__attribute__((visibility("hidden")))
@interface _YJKVOBindingManager : NSObject

/// designated initializer
- (instancetype)initWithObserver:(id)observer;

/// add binding identifier
- (void)addBindingIdentifer:(NSString *)bindingIdentifier;

/// returns all related binding identifiers
- (NSArray *)bindingIdentifiers;

@end

NS_ASSUME_NONNULL_END