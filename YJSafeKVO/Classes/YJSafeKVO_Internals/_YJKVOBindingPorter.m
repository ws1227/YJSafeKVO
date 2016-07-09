//
//  _YJKVOBindingPorter.m
//  YJKit
//
//  Created by huang-kun on 16/7/7.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import "_YJKVOBindingPorter.h"
#import "NSObject+YJKVOExtension.h"
#import "NSArray+YJSequence.h"
#import "_YJKVOBindingManager.h"
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
    
    YJKVOReturnValueHandler convertHandler = self.convertHandler;
    YJKVOObjectsHandler afterHandler = self.afterHandler;
    YJKVOValueTakenHandler takenHandler = self.takenHandler;
    
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue == [NSNull null]) newValue = nil;
    
    NSArray *bindingIDs = [observer.yj_KVOBindingManager bindingIdentifiers];
    NSString *bindingID = [[_YJKVOIdentifierGenerator sharedGenerator] bindingIdentifierForObserver:observer
                                                                                    observerKeyPath:observerKeyPath
                                                                                             target:object
                                                                                      targetKeyPath:keyPath];
    if ([bindingIDs containsObject:bindingID]) {
        
        BOOL taken = YES;
        if (takenHandler) {
            taken = takenHandler(observer, object, newValue);
        }
        if (!taken) return;
        
        id convertedValue = newValue;
        if (convertHandler) {
            convertedValue = convertHandler(observer, object, newValue);
        }
        
        // get observer's setter
        NSArray *components = [observerKeyPath componentsSeparatedByString:@"."];
        NSString *last = components.lastObject;
        NSString *prefixedKeyPath = [[components droppingLast] componentsJoinedByString:@"."];
        id obj = prefixedKeyPath.length ? [observer valueForKeyPath:prefixedKeyPath] : observer;
        
        NSString *setterStr = [NSString stringWithFormat:@"set%@:", last.capitalizedString];
        SEL sel = NSSelectorFromString(setterStr);
        if ([obj respondsToSelector:sel]) {
            // call setter to trigger the KVO if needed (e.g. observer may be observed by other objects)
            ((void (*)(id obj, SEL, id value)) objc_msgSend)(obj, sel, convertedValue);
        }
        // set value through keyPath to make result correctly for primitive value (e.g. BOOL, ...)
        [observer setValue:convertedValue forKeyPath:observerKeyPath];
        
        if (afterHandler) afterHandler(observer, object);
    }
}

#if DEBUG_YJ_SAFE_KVO
- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}
#endif


@end
