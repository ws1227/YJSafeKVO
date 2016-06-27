//
//  NSObject+YJSafeKVO.h
//  YJKit
//
//  Created by huang-kun on 16/4/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YJSafeKVO)

/*
 
    The difference for using -observeKeyPath:forChanges: and -observeKeyPath:forUpdates:
    
     1. Only -observeKeyPath:forChanges: contains an old value.
     2. Only -observeKeyPath:forUpdates: block gets called immediately.
 
 
    Simple usage:
 
     [foo observeKeyPath:@keyPath(foo.friend) forChanges:^(id  _Nonnull object, id  _Nullable oldValue, id  _Nullable newValue) {
         NSLog(@"foo <%@> meets its new friend <%@>.", object, newValue);
     }];
 
 */

/**
 *  @brief      Key-Value observing the key path and execute the handler block when observed value changes.
 *
 *  @discussion This method performs as same as add observer with options (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew). 
                The observer will be generated implicitly and it's safe for not removing observer explicitly because eventually observer 
                will be removed before receiver gets deallocated. It's vaild to use it multiple times for applying different changeHandler
                block with same key path.
 
 *  @remark     The handler block captures inner objects while the receiver is alive.
 *  @see        \@keyPath in YJKVCMacros.h
 *
 *  @param keyPath       The key path, relative to the array, of the property to observe. This value must not be nil.
 *  @param changeHandler The block of code will be performed when observed value changes from old to new.
 */
- (void)observeKeyPath:(NSString *)keyPath forChanges:(void(^)(id receiver, id _Nullable oldValue, id _Nullable newValue))changeHandler;


/**
 *  @brief      Key-Value observing the key path and execute the handler block when observed value changes.
 *
 *  @discussion This method performs as same as add observer with options (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew).
                 The observer will be generated implicitly and it's safe for not removing observer explicitly because eventually observer
                 will be removed before receiver gets deallocated. It's vaild to use it multiple times for applying different changeHandler
                 block with same key path.
 
 *  @remark     The handler block captures inner objects while the receiver is alive.
 *  @see        \@keyPath in YJKVCMacros.h
 *
 *  @param keyPath       The key path, relative to the array, of the property to observe. This value must not be nil.
 *  @param identifier    The string for identifying the current observing operation.
 *  @param queue         The operation queue to which block should be added.
 *  @param changeHandler The block of code will be performed when observed value changes from old to new.
 */
- (void)observeKeyPath:(NSString *)keyPath identifier:(nullable NSString *)identifier queue:(nullable NSOperationQueue *)queue forChanges:(void(^)(id receiver, id _Nullable oldValue, id _Nullable newValue))changeHandler;


/**
 *  @brief      Key-Value observing the key path and execute the handler block when observed value gets updated. After observing the key
                path, the block gets immediately called.
 *
 *  @discussion This method performs as same as add observer with options (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew). 
                The observer will be generated implicitly and it's safe for not removing observer explicitly because eventually observer 
                will be removed when receiver gets deallocated. It's vaild to use it multiple times for applying different updateHandler 
                block with same key path.
 *
 *  @remark     The handler block captures inner objects while the receiver is alive.
 *  @see        \@keyPath in YJKVCMacros.h

 *  @param keyPath        The key path, relative to the array, of the property to observe. This value must not be nil.
 *  @param updateHandler  The block of code will be performed when observed value updates.
 */
- (void)observeKeyPath:(NSString *)keyPath forUpdates:(void(^)(id receiver, id _Nullable newValue))updateHandler;


/**
 *  @brief      Key-Value observing the key path and execute the handler block when observed value gets updated. After observing the key
                path, the block gets immediately called.
 *
 *  @discussion This method performs as same as add observer with options (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew).
                 The observer will be generated implicitly and it's safe for not removing observer explicitly because eventually observer
                 will be removed when receiver gets deallocated. It's vaild to use it multiple times for applying different updateHandler
                 block with same key path.
 *
 *  @remark     The handler block captures inner objects while the receiver is alive.
 *  @see        \@keyPath in YJKVCMacros.h
 
 *  @param keyPath        The key path, relative to the array, of the property to observe. This value must not be nil.
 *  @param identifier     The string for identifying the current observing operation.
 *  @param queue          The operation queue to which block should be added.
 *  @param updateHandler  The block of code will be performed when observed value updates.
 */
- (void)observeKeyPath:(NSString *)keyPath identifier:(nullable NSString *)identifier queue:(nullable NSOperationQueue *)queue forUpdates:(void(^)(id receiver, id _Nullable newValue))updateHandler;


/**
 *  @brief Stops observing property specified by a given key-path relative to the receiver.
 *
 *  @note  If you don't call this method when finish key value observing. All implicit generated observers will be removed from receiver 
           before receiver is deallocated. The internal observers will keep alive as long as receiver is alive. This method is for the 
           case when receiver is alive and you've done the obverving job. You can call this to manually remove all observers, then the
           block you've used for key value observing method will be released as well.
 
    @note  If you observe the same key path multiple times for different reason, you call -unobserveKeyPath: only once is good.
 
    @note  Calling this method only remove observers which generated by method -observeKeyPath:... provided by YJKit, and not remove
           observers which generated by other APIs if you are using (Whether they are system provided or from other 3rd-party libraries).
 
 *  @see   \@keyPath in YJKVCMacros.h
 
 *  @param keyPath       The key path, relative to the array, of the property to observe. This value must not be nil.
 */
- (void)unobserveKeyPath:(NSString *)keyPath;


/**
 *  @brief Stops observing property specified by an identifier for given key-path relative to the receiver.
 *
 *  @note  If you don't call this method when finish key value observing. All implicit generated observers will be removed from receiver
           before receiver is deallocated. The internal observers will keep alive as long as receiver is alive. This method is for the
           case when receiver is alive and you've done the obverving job. You can call this to manually remove all observers, then the
           block you've used for key value observing method will be released as well.
 
    @note  If you observe the same key path multiple times for different reason, you call -unobserveKeyPath: only once is good.
     
    @note  Calling this method only remove observers which generated by method -observeKeyPath:... provided by YJKit, and not remove
           observers which generated by other APIs if you are using (Whether they are system provided or from other 3rd-party libraries).
 
 *  @see   \@keyPath in YJKVCMacros.h
 
 *  @param keyPath       The key path, relative to the array, of the property to observe. This value must not be nil.
 *  @param identifier    The string represents the observing operation.
 */
- (void)unobserveKeyPath:(NSString *)keyPath forIdentifier:(NSString *)identifier;


/**
 *  @brief Stops observing all properties relative to the receiver.
 
 *  @note  If you don't call this method when finish key value observing. All implicit generated observers will be removed from receiver
           before receiver is deallocated. The internal observers will keep alive as long as receiver is alive. This method is for the
           case when receiver is alive and you've done the obverving job. You can call this to manually remove all observers, then the
           block you've used for key value observing method will be released as well.
 
    @note  Calling this method only remove observers which generated by method -observeKeyPath:... provided by YJKit, and not remove
           observers which generated by other APIs if you are using (Whether they are system provided or from other 3rd-party libraries).
 */
- (void)unobserveAllKeyPaths;

@end

NS_ASSUME_NONNULL_END
        