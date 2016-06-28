# YJSafeKVO

[![CI Status](http://img.shields.io/travis/huang-kun/YJSafeKVO.svg?style=flat)](https://travis-ci.org/huang-kun/YJSafeKVO)
[![Version](https://img.shields.io/cocoapods/v/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![License](https://img.shields.io/cocoapods/l/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![Platform](https://img.shields.io/cocoapods/p/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)

## Introduction

如果你更倾向于阅读中文，可以点击[这里](https://github.com/huang-kun/YJSafeKVO/blob/master/README_CH.md)。

<br>

#### Problems

The key value observing pattern is really important for the Cocoa and Cocoa Touch programming. You add an observer, observe the value changes, remove it when you finish. However, if you not use it correctly, the results are basically crashes.

First example: 

(Assuming foo and bar are both instance objects and their classes are subclasses of NSObject)

e.g. When you add an observer bar to observe foo's property, and forget to remove bar before foo gets deallocated. Then you get this crash log:

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'An instance 0x100102560 of class Foo was deallocated while key value observers were still registered with it. Current observation info: <NSKeyValueObservationInfo 0x100104990> (
<NSKeyValueObservance 0x100104770: Observer: 0x100102f30, Key path: count, Options: <New: YES, Old: YES, Prior: NO> Context: 0x0, Property: 0x100100340>
)'
```

For some reason, if you observe the property of object which provided by system, and because that class is not what you created, you can not try to remove the observer by overriding -dealloc in that class (At least no elegant way to do that). 

Another example:

e.g. If you need to add multiple observers, you must make sure that you will remove them correctly. If you miss one, it crashes; if you remove the wrong one, it crashes.

```
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <Bar 0x100202de0> for the key path "count" from <Foo 0x100202ac0> because it is not registered as an observer.'
```

Another example:

e.g. If you call -addObserver:keyPath:.., and not observing, it crashes.

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '<Bar: 0x1002000b0>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
Key path: count
Observed object: <Foo: 0x100200080>
Change: { kind = 1; new = 1; old = 0; }
Context: 0x0'
```

<br>

#### Solutions

Despite the usability and safefy, KVO is still important. As a developer, I just want to use some simple APIs to achieve the goal. Here comes `YJSafeKVO`:

The goal for `YJSafeKVO` is to provide a simple set of APIs that can prevent the general KVO crashes by developers, and also extremely easy to use.

* It's block based API.
* Observers are generated implicitly and removed automatically. No crashes above.
* Allow manually unobserving key path when you finish the task.
* Support multiple observing actions on same object with same key path.
* Support identifying each (or multiple) observing actions for manually unobserving specific action later.
* Support `NSOperationQueue` for adding callback block.
* Provide `@keyPath` for key path compile time validation.

e.g. If I observe foo's property called name when it's name value changes. I call this:

```
[foo observeKeyPath:@"name"
            options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
                // foo changes its name.
            }];
```

Which is quite simple, but there is a better way (recommended):

```
[foo observeKeyPath:@keyPath(foo.name)
            options:YJKeyValueObservingOldToNew
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
                // foo changes its name.
            }];
```

Calling APIs provided by `YJSafeKVO` will generate observers implicitly and they are managed internally. Because they are not exposed, the KVO code base will become mush simpler. But what happened if foo is deallocated in the future? All observers is guaranteed to be removed before receiver's deallocation. No crashes.

<br>

#### Questions

* What's the difference between `-observeKeyPath:forChanges:` and `-observeKeyPath:forUpdates:` ?

* Why defining `YJKeyValueObservingOldToNew` and `YJKeyValueObservingUpToDate` ?

Personally, I use them a lot. Instead of typing `NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew` everytime for option parameter, I'd like to make a nice symbol as `YJKeyValueObservingOldToNew` to represent observing value changes from old to new. It's just about making code shorter. Another symbol `YJKeyValueObservingUpToDate` represent `.Initial | .New`, which means the block will be called immediately.

<br>

* What's `@keyPath` ?

It's the feature for key path validation during compile time. Since `#keyPath` will be supported for Swift 3 by Apple officially, it is clear that key path compile checking is not only provide safe code, but also becoming the trend now. Use it as similar as using `@selector(..)` in Objective C.

<br>

* What about the case when multiple threads are involved ?

For example if your observed property is being set with new value on one thread, and you expect to update UI with new value in the callback block executed on main thread. You can use the extended API for specifing a `NSOperationQueue` parameter.

```
[foo observeKeyPath:@keyPath(foo.name)
            options:YJKeyValueObservingOldToNew
         identifier:nil
              queue:[NSOperationQueue mainQueue]
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
                // callback on main thread
            }];
```

If you are familiar with `-addObserverForName:object:queue:usingBlock:` for `NSNotificationCenter`, then there is no barrier for using this API.

<br>

* What happen if the receiver is never deallocated ? Are these implicit generated receivers is gonna keep alive forever ?

Theoretically YES, but you can call `-[foo unobserveKeyPath:@keyPath(foo.name)]` to manually do the clean-up when you finish the observing. 

<br>

* What other issues that might occur for using YJSafeKVO's APIs ?

Think about this case: There are multiple objects observing the property of the singleton object (which is never being released), and you call `[singleton unobserveKeyPath:]` after one of objects is done observing. The singleton object will remove all observers which related to that key path, which will cause other objects can not be able to keep observing the same key path continuously.

To solve the problem, calling `[singleton observeKeyPath:options:identifier:queue:changes:]` to pass a unique string as an identifier for each observing operation or a group of operations by the same object. Then you can call `[singleton unobserveKeyPath:forIdentifier:]` which will only stop observing operations and remove observers which match the identifier you specified. This is a fine-grain control for performing manually clean-up without side-effect.

After you call `-unobserve...` prefixed methods, it only help you clean up the observers which generated by `YJSafeKVO`, and not go the extra mile for removing other observers which created by other approaches (if you are using system APIs or other third party APIs).

Pay attention about the ownership for `YJSafeKVO`. The observered receiver object ownes the implicit observers object, the observer owns the block object. When receiver is deallocated, the top owner of ownership chain will let go and start releasing the rest of objects. One thing you need to care about is avoiding the retain cycle by using the block-based APIs.

<br>

#### Compatibility

The key value observing is the pattern from Cocoa programming. Any object as subclass of NSObject will get it for free. It also means this feature is not applied for Swift's struct, and for it's class object which root class is not NSObject.

<br>

## Installation

YJSafeKVO is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "YJSafeKVO"
```

Go to terminal and run `pod install`, then `#import <YJSafeKVO/YJSafeKVO.h>` into project's `ProjectName-Prefix.pch` file.

<br>

## Author

huang-kun, jack-huang-developer@foxmail.com

<br>

## License

YJSafeKVO is available under the MIT license. See the LICENSE file for more info.


