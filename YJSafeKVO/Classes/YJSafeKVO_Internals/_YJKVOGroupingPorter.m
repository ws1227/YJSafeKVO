//
//  _YJKVOGroupingPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/5.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOGroupingPorter.h"
#import "_YJKVOPair.h"

@interface _YJKVOGroupingPorter ()

@property (nonatomic, strong) NSMutableArray <_YJKVOPair *> *targetsAndKeyPaths;
@property (nonatomic, readwrite) BOOL employed;

@property (nonatomic, assign) id first;
@property (nonatomic, assign) id second;
@property (nonatomic, assign) id third;
@property (nonatomic, assign) id fourth;
@property (nonatomic, assign) id fifth;
@property (nonatomic, assign) id sixth;
@property (nonatomic, assign) id seventh;
@property (nonatomic, assign) id eighth;
@property (nonatomic, assign) id ninth;
@property (nonatomic, assign) id tenth;

@end


@implementation _YJKVOGroupingPorter {
    int _counter;
}

@synthesize employed = _employed;

- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber {
    self = [super initWithTarget:nil subscriber:subscriber targetKeyPath:nil];
    if (self) {
        _targetsAndKeyPaths = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (instancetype)initWithTarget:(__kindof NSObject *)target subscriber:(__kindof NSObject *)subscriber targetKeyPath:(NSString *)targetKeyPath {
    [NSException raise:NSGenericException format:@"Do not call %@ directly for %@.", NSStringFromSelector(_cmd), self.class];
    return [self initWithSubscriber:(id)[NSNull null]];
}

- (void)addTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    [self.targetsAndKeyPaths addObject:_YJKVOPair(target, keyPath)];
}

- (void)signUp {
    if (self.employed)
        return;
    
    for (_YJKVOPair *targetAndKeyPath in self.targetsAndKeyPaths) {
        [targetAndKeyPath.object addObserver:self forKeyPath:targetAndKeyPath.keyPath options:self.observingOptions context:NULL];
    }
    self.employed = YES;
}

- (void)resign {
    if (!self.employed)
        return;
    
    for (_YJKVOPair *targetAndKeyPath in self.targetsAndKeyPaths) {
        [targetAndKeyPath.object removeObserver:self forKeyPath:targetAndKeyPath.keyPath context:NULL];
    }
    self.employed = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    if (self.multipleValueHandler && [self applyNewValue:newValue fromKeyPath:keyPath ofObject:object]) {
        self.multipleValueHandler(self.first, self.second, self.third, self.fourth, self.fifth, self.sixth, self.seventh, self.eighth, self.ninth, self.tenth);
    }
    
    if (self.reduceValueReturnHandler && self.subscriberKeyPath && [self applyNewValue:newValue fromKeyPath:keyPath ofObject:object]) {
        id reducedValue = self.reduceValueReturnHandler(self.first, self.second, self.third, self.fourth, self.fifth, self.sixth, self.seventh, self.eighth, self.ninth, self.tenth);
        [self.subscriber setValue:reducedValue forKeyPath:self.subscriberKeyPath];
    }
}

- (BOOL)applyNewValue:(nullable id)newValue fromKeyPath:(NSString *)keyPath ofObject:(id)object {
    NSInteger index = NSNotFound;
    for (int i = 0; i < (int)self.targetsAndKeyPaths.count; i++) {
        _YJKVOPair *targetAndKeyPath = self.targetsAndKeyPaths[i];
        if (targetAndKeyPath.object == object && [targetAndKeyPath.keyPath isEqualToString:keyPath]) {
            index = i;
            break;
        }
    }
    
    if (index != NSNotFound) {
        switch (index) {
            case 0: self.first = newValue; break;
            case 1: self.second = newValue; break;
            case 2: self.third = newValue; break;
            case 3: self.fourth = newValue; break;
            case 4: self.fifth = newValue; break;
            case 5: self.sixth = newValue; break;
            case 6: self.seventh = newValue; break;
            case 7: self.eighth = newValue; break;
            case 8: self.ninth = newValue; break;
            case 9: self.tenth = newValue; break;
            default: break;
        }
        _counter++;
    }
    
    return _counter >= self.targetsAndKeyPaths.count;
}

@end
