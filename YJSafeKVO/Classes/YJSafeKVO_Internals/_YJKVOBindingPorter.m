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

@implementation _YJKVOBindingPorter

- (instancetype)initWithTarget:(__kindof NSObject *)target
                    subscriber:(__kindof NSObject *)subscriber
                 targetKeyPath:(NSString *)targetKeyPath
             subscriberKeyPath:(NSString *)subscriberKeyPath {
    
    self = [super initWithTarget:target subscriber:subscriber targetKeyPath:targetKeyPath];
    if (self) {
        _subscriberKeyPath = [subscriberKeyPath copy];
    }
    return self;
}

- (instancetype)initWithTarget:(__kindof NSObject *)target subscriber:(__kindof NSObject *)subscriber targetKeyPath:(NSString *)targetKeyPath {
    [NSException raise:NSGenericException format:@"Do not call %@ directly for %@.", NSStringFromSelector(_cmd), self.class];
    return [self initWithTarget:target subscriber:subscriber targetKeyPath:targetKeyPath subscriberKeyPath:(id)[NSNull null]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    NSString *pipeID = [[_YJKVOIdentifierGenerator sharedGenerator] pipeIdentifierForTarget:object
                                                                                 subscriber:self.subscriber
                                                                              targetKeyPath:keyPath
                                                                          subscriberKeyPath:self.subscriberKeyPath];
    
    if ([self.subscriber.yj_KVOPipeIDKeeper containsPipeIdentifier:pipeID]) {
        
        BOOL taken = YES;
        if (self.takenHandler) {
            taken = self.takenHandler(self.subscriber, object, newValue);
        }
        if (!taken) return;
        
        id convertedValue = newValue;
        if (self.convertHandler) {
            convertedValue = self.convertHandler(self.subscriber, object, newValue);
        }
        
        [self.subscriber setValue:convertedValue forKeyPath:self.subscriberKeyPath];
        
        if (self.afterHandler) {
            self.afterHandler(self.subscriber, object);
        }
    }
}

@end
