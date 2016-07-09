//
//  _YJKVOBindingManager.m
//  YJKit
//
//  Created by huang-kun on 16/7/8.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOBindingManager.h"

@implementation _YJKVOBindingManager {
    __unsafe_unretained id _observer;
    dispatch_semaphore_t _semaphore;
    NSMutableArray <NSString *> *_bindingIdentifiers;
}

- (instancetype)initWithObserver:(id)observer {
    self = [super init];
    if (self) {
        _observer = observer;
        _semaphore = dispatch_semaphore_create(1);
        _bindingIdentifiers = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (void)addBindingIdentifer:(NSString *)bindingIdentifier {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_bindingIdentifiers addObject:bindingIdentifier];
    dispatch_semaphore_signal(_semaphore);
}

- (NSArray *)bindingIdentifiers {
    return [_bindingIdentifiers copy];
}

@end
