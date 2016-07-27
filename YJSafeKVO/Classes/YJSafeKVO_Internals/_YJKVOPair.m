//
//  _YJKVOPair.m
//  YJKit
//
//  Created by huang-kun on 16/7/27.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPair.h"

@implementation _YJKVOPair

- (instancetype)initWithObject:(__kindof NSObject *)object keyPath:(NSString *)keyPath {
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = [keyPath copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return self == object;
}

@end
