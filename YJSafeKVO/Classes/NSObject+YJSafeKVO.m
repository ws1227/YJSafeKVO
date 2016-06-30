//
//  NSObject+YJSafeKVO.m
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//
//  References:
//  Modify method IMP from BlocksKit
//  https://github.com/zwaldowski/BlocksKit/blob/master/BlocksKit/Core/NSObject%2BBKBlockObservation.m
//  Make thread safe mutable collection
//  https://github.com/ibireme/YYKit/blob/master/YYKit/Utility/YYThreadSafeDictionary.m

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+YJSafeKVO.h"
#import "NSObject+YJRuntimeEncapsulation.h"

#define DEBUG_YJ_SAFE_KVO 0

static const void *YJKVOAssociatedKVOMKey = &YJKVOAssociatedKVOMKey;

typedef void(^YJKVOHandler)(id object, id newValue, id change);

NSKeyValueObservingOptions const YJKeyValueObservingOldToNew = (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew);
NSKeyValueObservingOptions const YJKeyValueObservingUpToDate = (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew);


#pragma mark - internal observer

/* ------------------------- */
//    _YJKeyValueObserver
/* ------------------------- */

__attribute__((visibility("hidden")))
@interface _YJKeyValueObserver : NSObject

// block property for handling value changes
@property (nullable, nonatomic, copy) YJKVOHandler handler;

// the operation queue to run the block
@property (nullable, nonatomic, strong) NSOperationQueue *queue;

@end


@implementation _YJKeyValueObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    YJKVOHandler handler = self.handler;
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (handler) handler(object, newValue, change);
    };
    
    if (self.queue) {
        [self.queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

#if DEBUG_YJ_SAFE_KVO

- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}

#endif

@end


#pragma mark - internal observer manager

/* ------------------------------ */
//   _YJKeyValueObserverManager
/* ------------------------------ */

__attribute__((visibility("hidden")))
@interface _YJKeyValueObserverManager : NSObject

// initialize a manager instance by knowing it's caller.
- (instancetype)initWithOwner:(id)owner;

// add observer to the internal collection.
- (void)registerObserver:(_YJKeyValueObserver *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;

// remove observers from internal collection for specific key path.
- (void)unregisterObserversForKeyPath:(NSString *)keyPath;

// remove observers from internal collection only for both matched key path and identifier.
- (void)unregisterObserversForKeyPath:(NSString *)keyPath withIdentifier:(NSString *)identifier;

// remove all observers from internal collection.
- (void)unregisterAllObservers;

@end


@implementation _YJKeyValueObserverManager {
    __unsafe_unretained id _owner;
    dispatch_semaphore_t _semaphore;
    NSMutableDictionary <NSString *, NSMutableArray <_YJKeyValueObserver *> *> *_observers;
}

- (instancetype)initWithOwner:(id)owner {
    self = [super init];
    if (self) {
        _owner = owner;
        _semaphore = dispatch_semaphore_create(1);
        _observers = [NSMutableDictionary new];
    }
    return self;
}

- (void)registerObserver:(_YJKeyValueObserver *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *observersForKeyPath = _observers[keyPath];
    if (!observersForKeyPath) {
        observersForKeyPath = [NSMutableArray new];
        _observers[keyPath] = observersForKeyPath;
    }
    [observersForKeyPath addObject:observer];
    [_owner addObserver:observer forKeyPath:keyPath options:options context:NULL];
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unregisterObserversForKeyPath:(NSString *)keyPath {
    NSMutableArray <_YJKeyValueObserver *> *observersForKeyPath = _observers[keyPath];
    if (!observersForKeyPath.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [observersForKeyPath enumerateObjectsUsingBlock:^(_YJKeyValueObserver * _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        [_owner removeObserver:observer forKeyPath:keyPath];
    }];
    [_observers removeObjectForKey:keyPath];
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unregisterObserversForKeyPath:(NSString *)keyPath withIdentifier:(NSString *)identifier {
    NSMutableArray <_YJKeyValueObserver *> *observersForKeyPath = _observers[keyPath];
    if (!observersForKeyPath.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *collector = [[NSMutableArray alloc] initWithCapacity:observersForKeyPath.count];
    [observersForKeyPath enumerateObjectsUsingBlock:^(_YJKeyValueObserver * _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (identifier && [observer.associatedIdentifier isEqualToString:identifier]) {
            [_owner removeObserver:observer forKeyPath:keyPath];
            [collector addObject:observer];
        }
    }];
    
    [observersForKeyPath removeObjectsInArray:collector];
    if (!observersForKeyPath.count) {
        [_observers removeObjectForKey:keyPath];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unregisterAllObservers {
    if (!_observers.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [_observers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull keyPath, NSMutableArray *  _Nonnull observersForKeyPath, BOOL * _Nonnull stop) {
        [observersForKeyPath enumerateObjectsUsingBlock:^(id  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            [_owner removeObserver:observer forKeyPath:keyPath];
        }];
    }];
    [_observers removeAllObjects];
    
    dispatch_semaphore_signal(_semaphore);
}

#if DEBUG_YJ_SAFE_KVO

- (void)dealloc {
    NSLog(@"%@ deallocated.", self);
}

#endif

@end


#pragma mark - block based kvo implementation

/* ------------------------- */
//         YJSafeKVO
/* ------------------------- */

@interface NSObject ()

// Associated with a manager for managing observers
@property (nonatomic, strong) _YJKeyValueObserverManager *kvoManager;

@end


@implementation NSObject (YJSafeKVO)

- (void)setKvoManager:(_YJKeyValueObserverManager *)kvoManager {
    objc_setAssociatedObject(self, YJKVOAssociatedKVOMKey, kvoManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Avoid lazy instantiation in the getter method for unnecessary
// instantiation when removing observers before -[self dealloc]
- (_YJKeyValueObserverManager *)kvoManager {
    return objc_getAssociatedObject(self, YJKVOAssociatedKVOMKey);
}

static void _yj_registerKVO(__kindof NSObject *self, NSString *keyPath, NSKeyValueObservingOptions options,
                            NSString *identifier, NSOperationQueue *queue, YJKVOHandler handler) {
    
    _YJKeyValueObserver *observer = [_YJKeyValueObserver new];
    if (handler) observer.handler = handler;
    if (identifier) observer.associatedIdentifier = identifier;
    if (queue) observer.queue = queue;
    
    _YJKeyValueObserverManager *kvoManager = self.kvoManager;
    if (!kvoManager) {
        kvoManager = [[_YJKeyValueObserverManager alloc] initWithOwner:self];
        self.kvoManager = kvoManager;
    }
    [kvoManager registerObserver:observer forKeyPath:keyPath options:options];
}

static void _yj_modifyDealloc(__kindof NSObject *self) {
    
    // Restriction for modifying -dealloc
    if (![self isKindOfClass:[NSObject class]] || [self isMemberOfClass:[NSObject class]])
        return;
    
    // Add dealloc method to the current class if it doesn't implement one.
    SEL deallocSel = sel_registerName("dealloc");
    IMP deallocIMP = imp_implementationWithBlock(^(__unsafe_unretained id obj){
        struct objc_super superInfo = (struct objc_super){ obj, class_getSuperclass([obj class]) };
        ((void (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superInfo, deallocSel);
    });
    __unused BOOL result = class_addMethod(self.class, deallocSel, deallocIMP, "v@:");
    
    // Removing all observers before executing original dealloc implementation.
    [self insertBlocksIntoMethodBySelector:deallocSel
                                identifier:@"YJ_REMOVE_KVO"
                                    before:^(id  _Nonnull receiver) {
                                        [receiver unobserveAllKeyPaths];
                                    } after:nil];
}

/* -------------------- Public APIs ------------------- */

- (void)observeKeyPath:(NSString *)keyPath changes:(void(^)(id receiver, id _Nullable newValue))changes {
    void(^handler)(id, id, id) = ^(id obj, id newVal, id change){
        if (changes) changes(obj, newVal);
    };
    _yj_registerKVO(self, keyPath, NSKeyValueObservingOptionNew, nil, nil, handler);
    _yj_modifyDealloc(self);
}

- (void)observeKeyPath:(NSString *)keyPath
               options:(NSKeyValueObservingOptions)options
               changes:(void(^)(id receiver, id _Nullable newValue, NSDictionary<NSString *,id> * change))changes {
    _yj_registerKVO(self, keyPath, options, nil, nil, changes);
    _yj_modifyDealloc(self);
}

- (void)observeKeyPath:(NSString *)keyPath
               options:(NSKeyValueObservingOptions)options
            identifier:(nullable NSString *)identifier
                 queue:(nullable NSOperationQueue *)queue
               changes:(void(^)(id receiver, id _Nullable newValue, NSDictionary<NSString *,id> * change))changes {
    _yj_registerKVO(self, keyPath, options, identifier, queue, changes);
    _yj_modifyDealloc(self);
}

- (void)unobserveKeyPath:(NSString *)keyPath forIdentifier:(NSString *)identifier {
    [self.kvoManager unregisterObserversForKeyPath:keyPath withIdentifier:identifier];
}

- (void)unobserveKeyPath:(NSString *)keyPath {
    [self.kvoManager unregisterObserversForKeyPath:keyPath];
}

- (void)unobserveAllKeyPaths {
    [self.kvoManager unregisterAllObservers];
}

@end
