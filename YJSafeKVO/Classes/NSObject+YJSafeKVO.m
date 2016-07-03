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
#pragma mark * _YJKVOPorter

/* ------------------------- */
//        _YJKVOPorter
/* ------------------------- */

__attribute__((visibility("hidden")))
@interface _YJKVOPorter : NSObject

// the designated initializer
- (instancetype)initWithObserver:(__kindof NSObject *)observer
                           queue:(nullable NSOperationQueue *)queue
                         handler:(YJKVOHandler)handler;
@end


@implementation _YJKVOPorter {
    __weak id _observer; // the object for handling the value changes
    YJKVOHandler _handler; // block for receiving value changes
    NSOperationQueue *_queue; // the operation queue to add the block
}

- (instancetype)initWithObserver:(__kindof NSObject *)observer
                           queue:(nullable NSOperationQueue *)queue
                         handler:(YJKVOHandler)handler {
    self = [super init];
    if (self) {
        _observer = observer;
        _queue = queue;
        _handler = [handler copy];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    id observer = self->_observer;
    YJKVOHandler handler = self->_handler;
    
    void(^kvoCallbackBlock)(void) = ^{
        id newValue = change[NSKeyValueChangeNewKey];
        if (newValue == [NSNull null]) newValue = nil;
        if (handler) handler(observer, object, newValue, change);
    };
    
    if (self->_queue) {
        [self->_queue addOperationWithBlock:kvoCallbackBlock];
    } else {
        kvoCallbackBlock();
    }
}

- (void)dealloc {
    [_observer setYj_KVOTarget:nil];
    _observer = nil;
#if DEBUG_YJ_SAFE_KVO
    NSLog(@"%@ deallocated.", self);
#endif
}

@end


#pragma mark * _YJKVOManager

/* ------------------------------ */
//          _YJKVOManager
/* ------------------------------ */

__attribute__((visibility("hidden")))
@interface _YJKVOManager : NSObject

// initialize a manager instance by knowing it's caller.
- (instancetype)initWithObservedTarget:(id)owner;

// add porter to the internal collection, and also register KVO internally.
- (void)employPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;

// remove porters from internal collection for specific key path.
- (void)unemployPortersForKeyPath:(NSString *)keyPath;

// remove porters from internal collection only for both matched key path and identifier.
- (void)unemployPortersForKeyPath:(NSString *)keyPath withIdentifier:(NSString *)identifier;

// remove porters from internal collection only for both matched identifier.
- (void)unemployPortersWithRelatedIdentifier:(NSString *)identifier;

// remove all porters from internal collection.
- (void)unemployAllPorters;

@end


@implementation _YJKVOManager {
    __unsafe_unretained id _target;
    dispatch_semaphore_t _semaphore;
    NSMutableDictionary <NSString *, NSMutableArray <_YJKVOPorter *> *> *_porters;
}

- (instancetype)initWithObservedTarget:(id)target {
    self = [super init];
    if (self) {
        _target = target;
        _semaphore = dispatch_semaphore_create(1);
        _porters = [NSMutableDictionary new];
    }
    return self;
}

- (void)employPorter:(_YJKVOPorter *)porter forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath) {
        portersForKeyPath = [NSMutableArray new];
        _porters[keyPath] = portersForKeyPath;
    }
    [portersForKeyPath addObject:porter];
    [_target addObserver:porter forKeyPath:keyPath options:options context:NULL];
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unemployPortersForKeyPath:(NSString *)keyPath {
    NSMutableArray <_YJKVOPorter *> *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [portersForKeyPath enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
        [_target removeObserver:porter forKeyPath:keyPath];
    }];
    [_porters removeObjectForKey:keyPath];
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unemployPortersForKeyPath:(NSString *)keyPath withIdentifier:(NSString *)identifier {
    NSMutableArray <_YJKVOPorter *> *portersForKeyPath = _porters[keyPath];
    if (!portersForKeyPath.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *collector = [[NSMutableArray alloc] initWithCapacity:portersForKeyPath.count];
    [portersForKeyPath enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
        if (identifier && [porter.associatedIdentifier isEqualToString:identifier]) {
            [_target removeObserver:porter forKeyPath:keyPath];
            [collector addObject:porter];
        }
    }];
    
    [portersForKeyPath removeObjectsInArray:collector];
    if (!portersForKeyPath.count) {
        [_porters removeObjectForKey:keyPath];
    }
    
    dispatch_semaphore_signal(_semaphore);
}

- (void)unemployPortersWithRelatedIdentifier:(NSString *)identifier {
    NSArray *keys = [_porters allKeys];
    for (NSString *key in keys) {
        [self unemployPortersForKeyPath:key withIdentifier:identifier];
    }
}

- (void)unemployAllPorters {
    if (!_porters.count) return;
    
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    [_porters enumerateKeysAndObjectsUsingBlock:^(id _Nonnull keyPath, NSMutableArray *  _Nonnull portersForKeyPath, BOOL * _Nonnull stop) {
        [portersForKeyPath enumerateObjectsUsingBlock:^(_YJKVOPorter * _Nonnull porter, NSUInteger idx, BOOL * _Nonnull stop) {
            [_target removeObserver:porter forKeyPath:keyPath];
        }];
    }];
    [_porters removeAllObjects];
    
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

// Associated with a manager for managing porters
@property (nonatomic, strong) _YJKVOManager *yj_KVOManager;

@end


@implementation NSObject (YJKVOTarget)

- (void)setYj_KVOManager:(_YJKVOManager *)yj_KVOManager {
    objc_setAssociatedObject(self, @selector(yj_KVOManager), yj_KVOManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_YJKVOManager *)yj_KVOManager {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)_makeKVOManagerDismissAllPorters {
    [self.yj_KVOManager unemployAllPorters];
}

@end


#pragma mark * YJKVOObserver

/* ------------------------- */
//       YJKVOObserver
/* ------------------------- */

@interface NSObject ()

// The target object for observing it's key path
@property (nonatomic, assign) __kindof NSObject *yj_KVOTarget;

// The identifier for KVO registering, which will connect observer with related porters
@property (nonatomic, copy) NSString *yj_KVOIdentifier;

@end


@implementation NSObject (YJKVOObserver)

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

- (void)_makeTargetDismissRelatedPorters {
    [self.yj_KVOTarget.yj_KVOManager unemployPortersWithRelatedIdentifier:self.yj_KVOIdentifier];
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
    
    // Insert method implementation before executing original dealloc implementation.
    [obj insertBlocksIntoMethodBySelector:deallocSel
                               identifier:@"YJSafeKVO"
                                   before:^(id  _Nonnull receiver) {
                                       ((void (*)(__unsafe_unretained id, SEL)) objc_msgSend)(receiver, sel);
                                   } after:nil];
}

static void _yj_registerKVO(__kindof NSObject *observer, __kindof NSObject *target, NSString *keyPath,
                            NSKeyValueObservingOptions options, NSOperationQueue *queue, YJKVOHandler handler) {
    
    NSString *identifier = [NSString stringWithFormat:@"%@<%p>:%@<%p>.%@",
                            NSStringFromClass([observer class]), observer,
                            NSStringFromClass([target class]), target, keyPath];
    
    _YJKVOPorter *porter = [[_YJKVOPorter alloc] initWithObserver:observer queue:queue handler:handler];
    porter.associatedIdentifier = identifier;
    
    observer.yj_KVOIdentifier = identifier;
    observer.yj_KVOTarget = target;
    
    _YJKVOManager *kvoManager = target.yj_KVOManager;
    if (!kvoManager) {
        kvoManager = [[_YJKVOManager alloc] initWithObservedTarget:target];
        target.yj_KVOManager = kvoManager;
    }
    
    [kvoManager employPorter:porter forKeyPath:keyPath options:options];
    
    // modify dealloc
    _yj_modifyDealloc(target, @selector(_makeKVOManagerDismissAllPorters));
    _yj_modifyDealloc(observer, @selector(_makeTargetDismissRelatedPorters));
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

- (void)observe:(OBSV)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates {
    
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_KVOMacroParse(targetAndKeyPath, &target, &keyPath)) {
        
        void(^handler)(id,id,id,NSDictionary *) = ^(id receiver, id target, id newValue, NSDictionary *change){
            if (updates) updates(receiver, target, newValue);
        };
        
        _yj_registerKVO(self, target, keyPath, (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew), nil, handler);
    }
}

- (void)observe:(OBSV)targetAndKeyPath
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

- (void)unobserve:(OBSV)targetAndKeyPath {
    __kindof NSObject *target; NSString *keyPath;
    if (_yj_KVOMacroParse(targetAndKeyPath, &target, &keyPath)) {
        [target.yj_KVOManager unemployPortersForKeyPath:keyPath withIdentifier:self.yj_KVOIdentifier];
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
    [target.yj_KVOManager unemployPortersForKeyPath:keyPath withIdentifier:self.yj_KVOIdentifier];
}

@end
