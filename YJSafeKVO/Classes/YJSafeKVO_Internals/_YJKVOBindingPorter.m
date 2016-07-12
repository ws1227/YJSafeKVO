//
//  _YJKVOBindingPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/7.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOBindingPorter.h"
#import "NSObject+YJKVOExtension.h"
#import "_YJKVOPipeIDKeeper.h"
#import "_YJKVOIdentifierGenerator.h"
#import <objc/message.h>

@implementation _YJKVOBindingPorter {
    NSString *_observerKeyPath;
}

- (instancetype)initWithObserver:(__kindof NSObject *)observer
                 observerKeyPath:(NSString *)observerKeyPath {
    self = [super initWithObserver:observer queue:nil handler:nil];
    if (self) {
        _observerKeyPath = [observerKeyPath copy];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    __kindof NSObject *observer = self.observer;
    NSString *observerKeyPath = self->_observerKeyPath;
    
    YJKVOValueReturnHandler convertHandler = self.convertHandler;
    YJKVOObjectsHandler afterHandler = self.afterHandler;
    YJKVOValueTakenHandler takenHandler = self.takenHandler;
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    NSArray *pipeIDs = [observer.yj_KVOPipeIDKeeper pipeIdentifiers];
    NSString *pipeID = [[_YJKVOIdentifierGenerator sharedGenerator] pipeIdentifierForObserver:observer
                                                                              observerKeyPath:observerKeyPath
                                                                                       target:object
                                                                                targetKeyPath:keyPath];
    if ([pipeIDs containsObject:pipeID]) {
        
        BOOL taken = YES;
        if (takenHandler) {
            taken = takenHandler(observer, object, newValue);
        }
        if (!taken) return;
        
        id convertedValue = newValue;
        if (convertHandler) {
            convertedValue = convertHandler(observer, object, newValue);
        }
        
        [observer setValue:convertedValue forKeyPath:observerKeyPath];
        
        if (afterHandler) {
            afterHandler(observer, object);
        }
    }
}

#if DEBUG_YJ_SAFE_KVO
- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}
#endif


@end
