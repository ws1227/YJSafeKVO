//
//  _YJKVOPair.h
//  YJKit
//
//  Created by huang-kun on 16/7/27.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _YJKVOPair(OBJECT, KEYPATH) \
    [[_YJKVOPair alloc] initWithObject:OBJECT keyPath:KEYPATH]

/// This class is for pairing object and keyPath

__attribute__((visibility("hidden")))
@interface _YJKVOPair : NSObject

/// initializer
- (instancetype)initWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath;

/// referenced object, not strongly holded
@property (nonatomic, readonly, assign) __kindof NSObject *object;

/// associated key path
@property (nonatomic, readonly, copy) NSString *keyPath;


@end
