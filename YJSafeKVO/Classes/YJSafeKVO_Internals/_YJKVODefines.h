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

typedef void(^YJKVODefaultChangeHandler)(id receiver, id target, id newValue, NSDictionary *change);

typedef void(^YJKVOReceiverTargetsHandler)(id receiver, NSArray *targets);
typedef id(^YJKVOReceiverTargetsReturnHandler)(id receiver, NSArray *targets);

typedef void(^YJKVOSubscriberTargetValueHandler)(id subscriber, id target, id newValue);
typedef id(^YJKVOSubscriberTargetValueReturnHandler)(id subscriber, id target, id newValue);

typedef void(^YJKVOSubscriberTargetHandler)(id subscriber, id target);

typedef void(^YJKVOSubscriberValueHandler)(id subscriber, id newValue);

#endif /* _YJKVODefines_h */
