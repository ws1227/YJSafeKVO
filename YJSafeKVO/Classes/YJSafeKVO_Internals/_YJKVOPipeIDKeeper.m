//
//  _YJKVOPipeIDKeeper.m
//  YJKit
//
//  Created by huang-kun on 16/7/8.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPipeIDKeeper.h"

@implementation _YJKVOPipeIDKeeper {
    __unsafe_unretained id _observer;
    dispatch_semaphore_t _semaphore;
    NSMutableArray <NSString *> *_pipeIdentifiers;
}

- (instancetype)initWithObserver:(id)observer {
    self = [super init];
    if (self) {
        _observer = observer;
        _semaphore = dispatch_semaphore_create(1);
        _pipeIdentifiers = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (void)addPipeIdentifier:(NSString *)pipeIdentifier {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_pipeIdentifiers addObject:pipeIdentifier];
    dispatch_semaphore_signal(_semaphore);
}

- (NSArray *)pipeIdentifiers {
    return [_pipeIdentifiers copy];
}

@end
