//
//  YJOBSVTuple.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The class for wrapping observed target and it's key path

@interface YJOBSVTuple : NSObject

+ (instancetype)tupleWithTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath;

@property (nonatomic, readonly, strong) __kindof NSObject *target;
@property (nonatomic, readonly, strong) NSString *keyPath;

@end

NS_ASSUME_NONNULL_END