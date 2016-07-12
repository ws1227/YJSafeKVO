//
//  NSObject+YJKVOExtension.h
//  YJKit
//
//  Created by huang-kun on 16/7/3.
//  Copyright © 2016年 huang-kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _YJKVOPorterManager, _YJKVOPorterTracker, _YJKVOPipeIDKeeper;


@interface NSObject (YJKVOExtension)

/// Associated with a porter manager for managing porters
@property (nonatomic, strong) _YJKVOPorterManager *yj_KVOPorterManager;

/// Associated with a tracker for tracking porters
@property (nonatomic, strong) _YJKVOPorterTracker *yj_KVOPorterTracker;

/// Associated with a pipeID keeper for keeping pipe identifier
@property (nonatomic, strong) _YJKVOPipeIDKeeper *yj_KVOPipeIDKeeper;

/// Associated with a packer string for unpack it later
@property (nonatomic, copy) NSString *yj_KVOPackerString;


@end
