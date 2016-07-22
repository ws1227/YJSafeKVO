//
//  NSObject+YJSafeKVO.h
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YJKVOPacker.h"

NS_ASSUME_NONNULL_BEGIN

/**
 By using YJSafeKVO, the observers will be generated implicitly and it's safe for not removing observers explicitly because eventually observers
 will be removed before observed target gets deallocated. It's vaild to use it multiple times for applying different changes block with same key path.
 
 If you don't call -unobserve... method when finish key value observing, all implicit generated observers will be removed from observed target before receiver is deallocated. This will automatically happend to avoid the general KVO crash. When the receiver is deallocated before observerd target, the internal observers which related to the receiver will be removed safely as well.
 */
@interface NSObject (YJSafeKVO)


/* ------------------------------------------------------------------------------------------------------------ */
//                                      APIs for using PACK(target, keyPath)
/* ------------------------------------------------------------------------------------------------------------ */

/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param targetAndKeyPath    The YJKVOPacker object for wrapping object and its key path, using PACK(target, keyPath).
 @param updates             The block of code will be performed both immediately and when observed value changes.
 */
- (void)observe:(PACK)targetAndKeyPath updates:(void(^)(id receiver, id target, id _Nullable newValue))updates;


/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param targetsAndKeyPaths  The array of YJKVOPacker object for wrapping object and its key path, using PACK(target, keyPath).
 @param updates             The block of code will be performed both immediately and when observed value changes.
 */
- (void)observeGroup:(NSArray <PACK> *)targetsAndKeyPaths updates:(void(^)(id receiver, NSArray *targets))updates;


/**
 @brief The receiver observe the target with key path by using Key-Value Observing mechanism with block based callback.
 
 @param targetAndKeyPath    The YJKVOPacker object for wrapping object and its key path, using PACK(target, keyPath).
 @param options             A combination of the NSKeyValueObservingOptions values that specifies what is included in observation notifications. 
 @param queue               The operation queue to which block should be added.
 @param changes             The block of code will be performed when observed value changes.
 */
- (void)observe:(PACK)targetAndKeyPath
        options:(NSKeyValueObservingOptions)options
          queue:(nullable NSOperationQueue *)queue
        changes:(void(^)(id receiver, id target, id _Nullable newValue, NSDictionary *change))changes;


/**
 @brief Manually stop observing the key path when you finish the job.
 
 @param targetAndKeyPath    The YJKVOPacker object for wrapping object and its key path, using PACK(target, keyPath).
 */
- (void)unobserve:(PACK)targetAndKeyPath;


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
              changes:(void(^)(id receiver, id target, id _Nullable newValue, NSDictionary *change))changes
                NS_SWIFT_NAME(observe(target:keyPath:options:queue:changes:));


/**
 @brief Manually stop observing the key path when you finish the job.
 
 @param target      The object which receiver wants to observe.
 @param keyPath     The key path, relative to the target, of the property to observe. This value must not be nil.
 */
- (void)unobserveTarget:(__kindof NSObject *)target keyPath:(NSString *)keyPath NS_SWIFT_NAME(unobserve(target:keyPath:));


/* ------------------------------------------------------------------------------------------------------------ */
//                                                General APIs
/* ------------------------------------------------------------------------------------------------------------ */

/**
 @brief Manually stop observing all keyPaths when you finish the job.
 
 @param target      The object which receiver observed.
 */
- (void)unobserveAll;

@end

NS_ASSUME_NONNULL_END
