//
//  NSObject+YJClassObjectChecking.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (YJClassObjectChecking)

/// Returns whether an object is a class object.
/// YES means if the object is a class or metaclass, NO means otherwise.
/// @note The reason for using yj_object_isClass() instead of object_isClass()
///       is object_isClass() is only support iOS 8 and above.
/// @see object_isClass() in <objc/runtime.h>
OBJC_EXPORT BOOL yj_object_isClass(id obj);

@end
