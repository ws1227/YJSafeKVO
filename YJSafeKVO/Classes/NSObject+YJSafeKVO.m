//
//  NSObject+YJSafeKVO.m
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+YJSafeKVO.h"
#import "NSObject+YJRuntimeEncapsulation.h"

#define DEBUG_YJ_SAFE_KVO 0

typedef void(^YJKVOHandler)(id receiver, id target, id newValue, NSDictionary *change);


#pragma mark - public classes
#pragma mark * YJKVOCombiner

/* ------------------------- */
//       YJKVOCombiner
/* ------------------------- */

@interface YJKVOCombiner ()
@property (nonatomic, strong) __kindof NSObject * target;
@property (nonatomic, strong) NSString *keyPath;
@end

@implementation YJKVOCombiner

+ (instancetype)target:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    YJKVOCombiner *combiner = [YJKVOCombiner new];
    combiner.target = target;
    combiner.keyPath = keyPath;
    return combiner;
}

@end

#pragma mark - forward declarations

@interface NSObject ()

- (void)setYj_KVOTarget:(__kindof NSObject *)yj_KVOTarget;

@end


#pragma mark - internal classes
#pragma mark * _YJKeyValueObserver

/* ------------------------- */
//    _YJKeyValueObserver
/* ------------------------- */

__attribute__((visibility("hidden")))
@interface _YJKeyValueObserver : NSObject

// the designated initializer
- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber
                             queue:(nullable NSOperationQueue *)queue
                           handler:(YJKVOHandler)handler;
@end


@implementation _YJKeyValueObserver {
    __weak id _subscriber; // the object for handling the value changes
    YJKVOHandler _handler; // block for receiving value changes
    NSOperationQueue *_queue; // the operation queue to add the block
}

- (instancetype)initWithSubscriber:(__kindof NSObject *)subscriber
                             queue:(nullable NSOperationQueue *)queue
                           handler:(YJKVOHandler)handler {
    self = [super init];
    if (self) {
        _subscriber = subscriber;
        _queue = queue;
        _handler = [handler copy];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id subscriber = self->_subscriber;
    YJKVOHandler handler = self->_handler;
    
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (handler) handler(subscriber, object, newValue, change);
    };
    
    if (self->_queue) {
        [self->_queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

- (void)dealloc {
    [_subscriber setYj_KVOTarget:nil];
    _subscriber = nil;
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end


#pragma mark * _YJKeyValueObserverManager

/* ------------------------------ */
//   _YJKeyValueObserverManager
/* ------------------------------ */

__attribute__((visibility("hidden")))
@interface _YJKeyValueObserverManager : NSObject

// initialize a manager instance by knowing it's caller.
- (instancetype)initWithObservedTarget:(id)owner;

// add observer to the internal collection.
- (void)registerObserver:(_YJKeyValueObserver *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;

// remove observers from internal collection for specific key path.
- (void)unregisterObserversForKeyPath:(NSString *)keyPath;

// remove observers from internal collection only for both matched key path and identifier.
- (void)unregisterObserversForKeyPath:(NSString *)keyPath withIdentifier:(NSString *)identifier;

// remove observers from internal collection only for both matched identifier.
- (void)unregisterObserversWithRelatedIdentifier:(NSString *)identifier;

// remove all observers from internal collection.
- (void)unregisterAllObservers;

@end


@implementation _YJKeyValueObserverManager {
    __unsafe_unretained id _target;
    dispatch_semaphore_t _semaphore;
    NSMutableDictionary <NSString *, NSMutableArray <_YJKeyValueObserver *> *> *_observers;
}

- (instancetype)initWithObservedTarget:(id)target {
    self = [super init];
    if (self) {
        _target = target;
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
    [_target addObserver:observer forKeyPath:keyPath options:options context:NULL];
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unregisterObserversForKeyPath:(NSString *)keyPath {
    NSMutableArray <_YJKeyValueObserver *> *observersForKeyPath = _observers[keyPath];
    if (!observersForKeyPath.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [observersForKeyPath enumerateObjectsUsingBlock:^(_YJKeyValueObserver * _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        [_target removeObserver:observer forKeyPath:keyPath];
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
            [_target removeObserver:observer forKeyPath:keyPath];
            [collector addObject:observer];
        }
    }];
    
    [observersForKeyPath removeObjectsInArray:collector];
    if (!observersForKeyPath.count) {
        [_observers removeObjectForKey:keyPath];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unregisterObserversWithRelatedIdentifier:(NSString *)identifier {
    NSArray *keys = [_observers allKeys];
    for (NSString *key in keys) {
        [self unregisterObserversForKeyPath:key withIdentifier:identifier];
    }
}

- (void)unregisterAllObservers {
    if (!_observers.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [_observers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull keyPath, NSMutableArray *  _Nonnull observersForKeyPath, BOOL * _Nonnull stop) {
        [observersForKeyPath enumerateObjectsUsingBlock:^(_YJKeyValueObserver * _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
            [_target removeObserver:observer forKeyPath:keyPath];
        }];
    }];
    [_observers removeAllObjects];
    
    dispatch_semaphore_signal(_semaphore);
}


- (void)dealloc {
    _target = nil;
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end

#pragma mark - internal class extensions
#pragma mark * YJKVOTarget

/* ------------------------- */
//         YJKVOTarget
/* ------------------------- */

@interface NSObject ()

// Associated with a manager for managing observers
@property (nonatomic, strong) _YJKeyValueObserverManager *yj_KVOManager;

@end


@implementation NSObject (YJKVOTarget)

- (void)setYj_KVOManager:(_YJKeyValueObserverManager *)yj_KVOManager {
    objc_setAssociatedObject(self, @selector(yj_KVOManager), yj_KVOManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKeyValueObserverManager *)yj_KVOManager {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)_makeKVOManagerUnobservingAllKeyPaths {
    [self.yj_KVOManager unregisterAllObservers];
}

@end


#pragma mark * YJKVOSubscriber

/* ------------------------- */
//       YJKVOSubscriber
/* ------------------------- */

@interface NSObject ()

// The target object for observing it's key path
@property (nonatomic, assign) __kindof NSObject *yj_KVOTarget;

// The default identifier for observing
@property (nonatomic, copy) NSString *yj_KVOIdentifier;

@end


@implementation NSObject (YJKVOSubscriber)

- (void)setYj_KVOTarget:(__kindof NSObject *)yj_KVOTarget {
    objc_setAssociatedObject(self, @selector(yj_KVOTarget), yj_KVOTarget, OBJC_ASSOCIATION_ASSIGN);
}

- (__kindof NSObject *)yj_KVOTarget {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYj_KVOIdentifier:(NSString *)yj_KVOIdentifier {
    objc_setAssociatedObject(self, @selector(yj_KVOIdentifier), yj_KVOIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)yj_KVOIdentifier {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)_makeTargetUnobservingRelatedKeyPaths {
    [self.yj_KVOTarget.yj_KVOManager unregisterObserversWithRelatedIdentifier:self.yj_KVOIdentifier];
}

@end


#pragma mark - internal functions

/* -------------------------- */
//  YJKVO Internal Functions
/* -------------------------- */

static void _yj_modifyDealloc(__unsafe_unretained id obj, SEL sel) {
    // Restriction for modifying -dealloc
    if (![obj isKindOfClass:[NSObject class]] || [obj isMemberOfClass:[NSObject class]])
        return;
    
    // Add dealloc method to the current class if it doesn't implement one.
    SEL deallocSel = sel_registerName("dealloc");
    IMP deallocIMP = imp_implementationWithBlock(^(__unsafe_unretained id obj){
        struct objc_super superInfo = (struct objc_super){ obj, class_getSuperclass([obj class]) };
        ((void (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superInfo, deallocSel);
    });
    __unused BOOL result = class_addMethod([obj class], deallocSel, deallocIMP, "v@:");
    
    // Removing all observers before executing original dealloc implementation.
    [obj insertBlocksIntoMethodBySelector:deallocSel
                               identifier:@"YJSafeKVO"
                                   before:^(id  _Nonnull receiver) {
                                       ((void (*)(__unsafe_unretained id, SEL)) objc_msgSend)(receiver, sel);
                                   } after:nil];
}

static void _yj_registerKVO(__kindof NSObject *subscriber, __kindof NSObject *target, NSString *keyPath,
                            NSKeyValueObservingOptions options, NSOperationQueue *queue, YJKVOHandler handler) {
    
    NSString *identifier = [NSString stringWithFormat:@"%@<%p>:%@<%p>.%@",
                            NSStringFromClass([subscriber class]), subscriber,
                            NSStringFromClass([target class]), target, keyPath];
    
    _YJKeyValueObserver *observer = [[_YJKeyValueObserver alloc] initWithSubscriber:subscriber queue:queue handler:handler];
    observer.associatedIdentifier = identifier;
    
    subscriber.yj_KVOIdentifier = identifier;
    subscriber.yj_KVOTarget = target;
    
    _YJKeyValueObserverManager *kvoManager = target.yj_KVOManager;
    if (!kvoManager) {
        kvoManager = [[_YJKeyValueObserverManager alloc] initWithObservedTarget:target];
        target.yj_KVOManager = kvoManager;
    }
    
    [kvoManager registerObserver:observer forKeyPath:keyPath options:options];
    
    // modify dealloc
    _yj_modifyDealloc(target, @selector(_makeKVOManagerUnobservingAllKeyPaths));
    _yj_modifyDealloc(subscriber, @selector(_makeTargetUnobservingRelatedKeyPaths));
}

static BOOL _yj_KVOMacroParse(id targetAndKeyPath, id *target, NSString **keyPath) {
    if (![targetAndKeyPath isKindOfClass:[YJKVOCombiner class]])
        return NO;
    
    YJKVOCombiner *combiner = (YJKVOCombiner *)targetAndKeyPath;
    
    if (target) {
        *target = combiner.target;
        NSCAssert(*target != nil, @"YJSafeKVO - Target can not be nil for Key value observing.");
    } else {
        return NO;
    }
    
    if (keyPath) {
        *keyPath = combiner.keyPath;
        NSCAssert((*keyPath).length > 0, @"YJSafeKVO - KeyPath can not be empty for Key value observing.");
    } else {
        return NO;
    }
    
    return YES;
}


#pragma mark - YJSafeKVO implementations

/* ------------------------- */
//          YJSafeKVO
/* ------------------------- */

@implementation NSObject (YJSafeKVO)

- (void)observe:(YJKVO)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_KVOMacroParse(targetAndKeyPath, &target, &keyPath)) {
        
        void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
            if (updates) updates(receiver, target, newValue);
        };
        
        _yj_registerKVO(self, target, keyPath, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, handler);
    }
}

- (void)observe:(YJKVO)targetAndKeyPath
        options:(NSKeyValueObservingOptions)options
          queue:(nullable NSOperationQueue *)queue
        changes:(void(^)(id receiver, id target, NSDictionary *change))changes {
    
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_KVOMacroParse(targetAndKeyPath, &target, &keyPath)) {
        
        void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
            if (changes) changes(receiver, target, change);
        };
        
        _yj_registerKVO(self, target, keyPath, options, queue, handler);
    }
}

- (void)unobserve:(YJKVO)targetAndKeyPath {
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_KVOMacroParse(targetAndKeyPath, &target, &keyPath)) {
        [target.yj_KVOManager unregisterObserversForKeyPath:keyPath withIdentifier:self.yj_KVOIdentifier];
    }
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    
    void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
        if (updates) updates(receiver, target, newValue);
    };
    
    _yj_registerKVO(self, target, keyPath, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, handler);
}

- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
                queue:(nullable NSOperationQueue *)queue
              changes:(void(^)(id receiver, id target, NSDictionary *change))changes {
    
    void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
        if (changes) changes(receiver, target, change);
    };
    
    _yj_registerKVO(self, target, keyPath, options, queue, handler);
}

- (void)unobserveTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath {
    [target.yj_KVOManager unregisterObserversForKeyPath:keyPath withIdentifier:self.yj_KVOIdentifier];
}

@end
