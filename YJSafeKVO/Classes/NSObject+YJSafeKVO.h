//
//  NSObject+YJSafeKVO.h
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This is safer than using @{ key1 : target, key2 : keyPath }
// when value of NSDictionary nils out in the future, it will crash.
@interface YJKVOCombiner : NSObject
+ (instancetype)target:(__kindof NSObject *)target keyPath:(NSString *)keyPath;
@end


#ifndef keyPath
#define keyPath(KEYPATH) \
    (((void)(NO && ((void)KEYPATH, NO)), strchr(#KEYPATH, '.') + 1))
#endif

#define OBSV(TARGET, KEYPATH) \
    [YJKVOCombiner target:TARGET keyPath:@(((void)(NO && ((void)TARGET.KEYPATH, NO)), #KEYPATH))]

/// Using OBSV macro.
/// e.g. If foo wants to observe bar's name property change when a new name applys to bar, then use:
/// @code
/// [foo observe:OBSV(bar, name) ...]
/// @endcode
typedef id OBSV;


/**
 By using YJSafeKVO, the observers will be generated implicitly and it's safe for not removing observers explicitly because eventually observers
 will be removed before observed target gets deallocated. It's vaild to use it multiple times for applying different changes block with same key path.
 
 If you don't call -unobserve... method when finish key value observing, all implicit generated observers will be removed from observed target before receiver is deallocated. This will automatically happend to avoid the general KVO crash. When the receiver is deallocated before observerd target, the internal observers which related to the receiver will be removed safely as well.
 */
@interface NSObject (YJSafeKVO)


/* ------------------------------------------------------------------------------------------------------------ */
//                                 APIs for using OBSV(target, keyPath)
/* ------------------------------------------------------------------------------------------------------------ */

/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param targetAndKeyPath    The YJKVOCombiner object for wrapping observed target and key path, using OBSV(target, keyPath).
 @param updates             The block of code will be performed both immediately and when observed value changes.
 */
- (void)observe:(OBSV)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates
            NS_SWIFT_UNAVAILABLE("Use observe(target:keyPath:updates:) instead.");


/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param targetAndKeyPath    The YJKVOCombiner object for wrapping observed target and key path, using OBSV(target, keyPath).
 @param options             A combination of the NSKeyValueObservingOptions values that specifies what is included in observation notifications. 
 @param queue               The operation queue to which block should be added.
 @param changes             The block of code will be performed when observed value changes.
 */
- (void)observe:(OBSV)targetAndKeyPath
        options:(NSKeyValueObservingOptions)options
          queue:(nullable NSOperationQueue *)queue
        changes:(void(^)(id receiver, id target, NSDictionary *change))changes
            NS_SWIFT_UNAVAILABLE("Use observe(target:keyPath:options:queue:changes:) instead.");


/**
 @brief Manually stop observing the key path when you finish the job.
 
 @param targetAndKeyPath    The YJKVOCombiner object for wrapping observed target and key path, using OBSV(target, keyPath).
 */
- (void)unobserve:(OBSV)targetAndKeyPath NS_SWIFT_UNAVAILABLE("Use unobserve(target:keyPath:) instead.");


/* ------------------------------------------------------------------------------------------------------------ */
//                             APIs for manually set target and key path parameters
/* ------------------------------------------------------------------------------------------------------------ */

/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param target      The object which receiver wants to observe.
 @param keyPath     The key path, relative to the target, of the property to observe. This value must not be nil.
 @param updates     The block of code will be performed both immediately and when observed value changes.
 */
- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              updates:(void(^)(id receiver, id target, id _Nullable newValue))updates
                NS_SWIFT_NAME(observe(target:keyPath:updates:));


/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param target      The object which receiver wants to observe.
 @param keyPath     The key path, relative to the target, of the property to observe. This value must not be nil.
 @param options     A combination of the NSKeyValueObservingOptions values that specifies what is included in observation notifications.
 @param queue       The operation queue to which block should be added.
 @param changes     The block of code will be performed when observed value changes.
 */
- (void)observeTarget:(__kindof NSObject *)target
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
                queue:(nullable NSOperationQueue *)queue
              changes:(void(^)(id receiver, id target, NSDictionary *change))changes
                NS_SWIFT_NAME(observe(target:keyPath:options:queue:changes:));


/**
 @brief Manually stop observing the key path when you finish the job.
 
 @param target      The object which receiver wants to observe.
 @param keyPath     The key path, relative to the target, of the property to observe. This value must not be nil.
 */
- (void)unobserveTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath NS_SWIFT_NAME(unobserve(target:keyPath:));


@end

NS_ASSUME_NONNULL_END
