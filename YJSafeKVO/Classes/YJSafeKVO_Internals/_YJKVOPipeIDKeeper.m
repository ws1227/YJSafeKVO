//
//  _YJKVOPipeIDKeeper.m
//  YJKit
//
//  Created by huang-kun on 16/7/8.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOPipeIDKeeper.h"
#import "_YJKVODefines.h"

@implementation _YJKVOPipeIDKeeper {
    __unsafe_unretained __kindof NSObject *_subscriber;
    NSMutableArray <NSString *> *_pipeIdentifiers;
    dispatch_semaphore_t _semaphore;
}

- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber {
    self = [super init];
    if (self) {
        _subscriber = subscriber;
        _semaphore = dispatch_semaphore_create(1);
        _pipeIdentifiers = [[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (instancetype)init {
    [NSException raise:NSGenericException format:@"Do not call init directly for %@.", self.class];
    return [self initWithSubscriber:(id)[NSNull null]];
}

- (void)addPipeIdentifier:(NSString *)pipeIdentifier {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [_pipeIdentifiers addObject:pipeIdentifier];
    dispatch_semaphore_signal(_semaphore);
}

- (BOOL)containsPipeIdentifier:(NSString *)pipeIdentifier {
    return [_pipeIdentifiers containsObject:pipeIdentifier];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (subscriber <%@: %p>)", self.class, self, _subscriber.class, _subscriber];
}

#if YJ_KVO_DEBUG
- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}
#endif

@end
