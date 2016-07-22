//
//  _YJKVODefines.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#ifndef _YJKVODefines_h
#define _YJKVODefines_h

#define YJ_KVO_DEBUG 0

typedef void(^YJKVOChangeHandler)(id receiver, id target, id newValue, NSDictionary *change);

typedef void(^YJKVOTargetsHandler)(id receiver, NSArray *targets);
typedef id(^YJKVOTargetsReturnHandler)(id receiver, NSArray *targets);

typedef void(^YJKVOObjectsAndValueHandler)(id subscriber, id target, id newValue);
typedef id(^YJKVOObjectsAndValueReturnHandler)(id subscriber, id target, id newValue);

typedef void(^YJKVOObjectsHandler)(id subscriber, id target);

typedef void(^YJKVOValueHandler)(id newValue);

#endif /* _YJKVODefines_h */
