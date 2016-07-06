//
//  YJOBSVTuple.m
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "YJOBSVTuple.h"

@interface YJOBSVTuple ()
@property (nonatomic, strong) __kindof NSObject * target;
@property (nonatomic, strong) NSString *keyPath;
@end

@implementation YJOBSVTuple

+ (instancetype)tupleWithTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    YJOBSVTuple *tuple = [YJOBSVTuple new];
    tuple.target = target;
    tuple.keyPath = keyPath;
    return tuple;
}

@end