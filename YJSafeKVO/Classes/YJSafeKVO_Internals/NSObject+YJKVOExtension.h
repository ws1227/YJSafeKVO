//
//  NSObject+YJKVOExtension.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorterManager, _YJKVOPorterTracker, _YJKVOBindingManager;


@interface NSObject (YJKVOExtension)

/// Associated with a porter manager for managing porters
@property (nonatomic, strong) _YJKVOPorterManager *yj_KVOPorterManager;

/// Associated with a tracker for tracking porters
@property (nonatomic, strong) _YJKVOPorterTracker *yj_KVOPorterTracker;

/// Associated with a key path manager for organizing key paths
@property (nonatomic, strong) _YJKVOBindingManager *yj_KVOBindingManager;

@end
