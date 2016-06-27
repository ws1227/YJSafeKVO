//
//  NSObject+YJRuntimeEncapsulation.h
//  YJKit
//
//  Created by huang-kun on 16/5/13.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* ------------------------------------ */
//        YJTaggedPointerChecking
/* ------------------------------------ */

@interface NSObject (YJTaggedPointerChecking)
@property (nonatomic, readonly) BOOL isTaggedPointer;
@end


/* ----------------------------------- */
//              Debugging
/* ----------------------------------- */

@interface NSObject (YJRuntimeDebugging)

/// Print out all instance methods into console.
/// @note The result will not include any method that inherits from it's superclass,
/// but includes non-official methods provided by YJKit and other developers.
+ (void)debugDumpingInstanceMethodList;

/// Print out all class methods into console.
/// @note The result will not include any method that inherits from it's superclass,
/// but includes non-official methods provided by YJKit and other developers.
+ (void)debugDumpingClassMethodList;

@end


/* ----------------------------------- */
//          Runtime Extension
/* ----------------------------------- */

/// Returns whether an object is a class object.
/// YES means if the object is a class or metaclass, NO means otherwise.
/// @note The reason for using yj_object_isClass() instead of object_isClass()
///       is object_isClass() is only support iOS 8 and above.
/// @see object_isClass() in <objc/runtime.h>
OBJC_EXPORT BOOL yj_object_isClass(id obj);


@interface NSObject (YJRuntimeExtension)

/// @brief Check if receiver's class dispatch table contains the selector, which means the selector
///        is not inherited from its superclass.
/// @discussion e.g. NSArray object implements method -containsObject:, NSMutableArray inherits
///             from NSArray, which doesn't override the -containsObject:, so -containsObject:
///             is not part of NSMutableArray's own selector.
/// @code
/// NSMutableArray *mutableArray = @[].mutableCopy;
/// BOOL b1 = [mutableArray respondsToSelector:@selector(containsObject:)]; // YES
/// BOOL b2 = [mutableArray containsSelector:@selector(containsObject:)]; // NO
/// @endcode
- (BOOL)containsSelector:(SEL)selector;

/// @brief Check if receiver's meta class dispatch table contains the selector, which means the selector
///        is not inherited from its superclass.
/// @discussion e.g. NSArray class implements method +arrayWithArray:, NSMutableArray inherits
///             from NSArray, which doesn't override the +arrayWithArray:, so +arrayWithArray:
///             is not part of NSMutableArray's own selector.
/// @code
/// BOOL b1 = [NSMutableArray respondsToSelector:@selector(arrayWithArray:)]; // YES
/// BOOL b2 = [NSMutableArray containsSelector:@selector(arrayWithArray:)]; // NO
/// @endcode
+ (BOOL)containsSelector:(SEL)selector;

/// @brief Check if receiver's dispatch table contains the selector for its instance to responds,
///        which means the selector is not inherited from its superclass.
/// @discussion e.g. NSArray object implements method -containsObject:, NSMutableArray inherits
///             from NSArray, which doesn't override the -containsObject:, so -containsObject:
///             is not part of NSMutableArray's own selector.
/// @code
/// BOOL b1 = [NSMutableArray instancesRespondToSelector:@selector(containsObject:)]; // YES
/// BOOL b2 = [NSMutableArray containsInstanceMethodBySelector:@selector(containsObject:)]; // NO
/// @endcode
+ (BOOL)containsInstanceMethodBySelector:(SEL)selector;

@end


/* ----------------------------------- */
//     Associated Identifier / Tag
/* ----------------------------------- */

FOUNDATION_EXTERN const NSInteger YJAssociatedTagInvalid;
FOUNDATION_EXTERN const NSInteger YJAssociatedTagNone;

@interface NSObject (YJAssociatedIdentifier)

/// Add a associated unique identifier string related to object itself.
/// @warning It will not effective if object is a tagged pointer. If you
///          set value to a tagged pointer, you will get nil result.
@property (nullable, nonatomic, copy) NSString *associatedIdentifier;

/// Add a associated unique number as a tag related to object itself.
/// @warning It will not effective if object is a tagged pointer. If you
///          set value to a tagged pointer, you will get YJAssociatedTagInvalid
///          as result. 0 is considered as YJAssociatedTagNone.
@property (nonatomic, assign) NSInteger associatedTag;

@end


@interface NSArray <ObjectType> (YJAssociatedIdentifier)

/// Check if NSArray contains object with specified identifier.
- (BOOL)containsObjectWithAssociatedIdentifier:(NSString *)associatedIdentifier;

/// Check if NSArray contains object with specified tag.
- (BOOL)containsObjectWithAssociatedTag:(NSInteger)associatedTag;

/// Only enumerate objects in the array which either has an associated identifier or a valid associated tag.
- (void)enumerateAssociatedObjectsUsingBlock:(void (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

@end


/* ----------------------------------- */
//           Method Swizzling
/* ----------------------------------- */

@interface NSObject (YJSwizzling)

/// Exchange the implementations between two given selectors.
/// @note If the class does not originally implements the method by given selector,
///       it will add the method to the class first, then switch the implementations.
+ (void)swizzleInstanceMethodsBySelector:(SEL)selector andSelector:(SEL)providedSelector;

/// Exchange the implementations between two given selectors.
/// @note If the class does not originally implements the method by given selector,
///       it will add the method to the class first, then switch the implementations.
+ (void)swizzleClassMethodsBySelector:(SEL)selector andSelector:(SEL)providedSelector;

@end


/* ----------------------------------- */
//       Method IMP Modification
/* ----------------------------------- */

@interface NSObject (YJMethodImpModifying)

/*
 
 @interface Foo : NSObject
 
 - (void)hello;
 + (void)hello;
 
 @end

 
 Foo *foo = [Foo new];
 [foo insertBlocksIntoMethodBySelector:@selector(hello) ... // it will change the default IMP of instance method -hello
 [Foo insertBlocksIntoMethodBySelector:@selector(hello) ... // it will change the default IMP of class method +hello
 
 
 // To summerize:
 
 // .If the receiver is an instance, it will change the default IMP of method by the given selector which represents an intance method.
 // .If the receiver is a class, it will change the default IMP of method by the given selector which represents an class method.
 
 */

/// @brief Insert blocks of code which will be executed before and after the default implementation of
///        receiver's instance method by given selector.
///
/// @discussion If the class does not own the method by given selector originally, it will go up the
///             chain and check its super's. If this case is not what you expected, you could:
///
///    . Use -[obj containsSelector:] to determine if selector is from super before you call this.
///    . Use +[classObj swizzleInstanceMethodsBySelector:andSelector:] to add method to current class.
///      It will prevent you modifying the method implementation from receiver's superclass.
///
/// @param selector   The selector for receiver (which responds to) for locating target method. If the
///                   selector is not responded by receiver, it will not crash but returns NO.
/// @param identifier Specify an identifier will prevent insertion with same identifier in same class.
/// @param before     The block of code which will be executed before the method implementation.
/// @param after      The block of code which will be executed after the method implementation.
///
/// @return Whether insertion is success or not.
///
- (BOOL)insertBlocksIntoMethodBySelector:(SEL)selector
                              identifier:(nullable NSString *)identifier
                                  before:(nullable void(^)(id receiver))before
                                   after:(nullable void(^)(id receiver))after;


/// @brief Insert blocks of code which will be executed before and after the default implementation of
///        receiver's class method by given selector.
///
/// @discussion If the class does not own the method by given selector originally, it will go up the
///             chain and check its super's. If this case is not what you expected, you could:
///
///    . Use +[classObj containsSelector:] to determine if selector is from super before you call this.
///    . Use +[classObj swizzleClassMethodsBySelector:andSelector:] to add method to current class.
///      It will prevent you modifying the method implementation from receiver's superclass.
///
/// @param selector   The selector for receiver (which responds to) for locating target method. If the
///                   selector is not responded by receiver, it will not crash but returns NO.
/// @param identifier Specify an identifier will prevent insertion with same identifier in same class.
/// @param before     The block of code which will be executed before the method implementation.
/// @param after      The block of code which will be executed after the method implementation.
///
/// @return Whether insertion is success or not.
///
+ (BOOL)insertBlocksIntoMethodBySelector:(SEL)selector
                              identifier:(nullable NSString *)identifier
                                  before:(nullable void(^)(id receiver))before
                                   after:(nullable void(^)(id receiver))after;

@end

NS_ASSUME_NONNULL_END