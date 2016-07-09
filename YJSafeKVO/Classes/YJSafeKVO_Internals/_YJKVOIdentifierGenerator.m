//
//  _YJKVOIdentifierGenerator.m
//  YJKit
//
//  Created by huang-kun on 16/7/9.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOIdentifierGenerator.h"

@implementation _YJKVOIdentifierGenerator

+ (instancetype)sharedGenerator {
    static _YJKVOIdentifierGenerator *sharedGenerator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedGenerator = [_YJKVOIdentifierGenerator new];
    });
    return sharedGenerator;
}

- (NSString *)bindingIdentifierForObserver:(__kindof NSObject *)observer
                           observerKeyPath:(NSString *)observerKeyPath
                                    target:(__kindof NSObject *)target
                             targetKeyPath:(NSString *)targetKeyPath {
    
    return [NSString stringWithFormat:@"%@<%p>.%@|%@<%p>.%@",
            NSStringFromClass([observer class]), observer, observerKeyPath,
            NSStringFromClass([target class]), target, targetKeyPath];
}

@end
