//
//  _YJKVODefines.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#ifndef _YJKVODefines_h
#define _YJKVODefines_h

#define DEBUG_YJ_SAFE_KVO 0

typedef void(^YJKVOChangeHandler)(id receiver, id target, id newValue, NSDictionary *change);
typedef void(^YJKVOTargetsHandler)(id receiver, NSArray *targets);
typedef void(^YJKVOValueHandler)(id observer, id target, id newValue);
typedef void(^YJKVOObjectsHandler)(id observer, id target);

typedef id(^YJKVOReturnValueHandler)(id observer, id target, id newValue);

#endif /* _YJKVODefines_h */
