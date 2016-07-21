//
//  NSObject+YJKVOExtension.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOSubscriberManager, _YJKVOPorterManager, _YJKVOPipeIDKeeper;


@interface NSObject (YJKVOExtension)

/// Associated with a subscriber manager for target managing subscribers.
@property (nonatomic, strong) _YJKVOSubscriberManager *yj_KVOSubscriberManager;

/// Associated with a porter manager for subcriber managing porters.
@property (nonatomic, strong) _YJKVOPorterManager *yj_KVOPorterManager;

/// Associated with a pipeID keeper for keeping pipe identifier
@property (nonatomic, strong) _YJKVOPipeIDKeeper *yj_KVOPipeIDKeeper;

/// Associated with a variable name string
@property (nonatomic, copy) NSString *yj_KVOVariableName;


@end
