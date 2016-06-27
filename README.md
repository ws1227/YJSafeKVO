# YJSafeKVO

[![CI Status](http://img.shields.io/travis/huang-kun/YJSafeKVO.svg?style=flat)](https://travis-ci.org/huang-kun/YJSafeKVO)
[![Version](https://img.shields.io/cocoapods/v/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![License](https://img.shields.io/cocoapods/l/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![Platform](https://img.shields.io/cocoapods/p/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)

## Introduction

如果你更倾向于阅读中文，可以点击[这里](https://github.com/huang-kun/YJSafeKVO/blob/master/README_CH.md)。

#### Problems

The key value observing pattern is really important for the Cocoa and Cocoa Touch programming. You add an observer, observe the value changes, remove it when you finish. However, if you not use it correctly, the results are basically CRASHs.

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

如果需要添加多个观察者的话，那么还得保证删除的时候一一对应。如果删除少了，就是上面的崩溃；删除过了，就是下面的崩溃。

e.g. If you need to add multiple observers, you must make sure that you will remove them correctly. If you miss one, it crashes; if you remove the wrong one, it crashes.

```
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <Bar 0x100202de0> for the key path "count" from <Foo 0x100202ac0> because it is not registered as an observer.'
```

Another example:

e.g. If you call -addObserver:keyPath:.., and not observing, or call -[super observeValueForKeyPath:..] not properly, it crashes.

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '<Bar: 0x1002000b0>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
Key path: count
Observed object: <Foo: 0x100200080>
Change: { kind = 1; new = 1; old = 0; }
Context: 0x0'
```

<br>

#### Solutions

Despite the usability and safefy, KVO is still important. As a developer, I just want to use some simple APIs to achieve the goal. Here is the solution:

e.g. If I observe foo's property called name when it's name value changes. I call this:

```
[foo observeKeyPath:@keyPath(foo.name) forChanges:^(id receiver, id oldValue, id newValue) {
    // when foo.name's value changes in the future, the block gets called.
    // so do something with the old name and new name.
}
```

e.g. If I observe foo.name, and I want to get immediately callback, I call this:

```
[foo observeKeyPath:@keyPath(foo.name) forUpdates:^(id receiver, id newValue) {
    // the block gets immediately called when start observing.
    // the block will also gets called when new value is applied.
}
```

Calling these APIs will generate observers implicitly and they are managed internally. Because they are not exposed, the KVO code base will become mush simpler. But what happened if foo is deallocated in the future? All observers is guaranteed to be removed before receiver's deallocation. No crashes.

<br>

#### Questions

* What's the difference between `-observeKeyPath:forChanges:` and `-observeKeyPath:forUpdates:` ?

Here is an example: If you observe the value changes by calling `-observeKeyPath:forChanges:`, the change may happen in the future. What about if you want to update UI depending on the current value. Then you may updating before the observing and updating again for value changes. 

```
[self updateUserInterfaceWithName:foo.name];
[foo observeKeyPath:@keyPath(foo.name) forChanges:^(id receiver, id oldValue, id newValue) {
    [weakSelf updateUserInterfaceWithName:foo.name]; 
}
```

Calling `-observeKeyPath:forUpdates:` is helpful for replacing the code like this. Just change the method name and put all updating logics inside of block to organize code in one place.

<br>

* What's `@keyPath` ?

It's the feature for key path validation during compile time. Since `#keyPath` will be supported for Swift 3 by Apple officially, it is clear that key path compile checking is not only provide safe code, but also becoming the trend now. Use it as similar as using `@selector(..)` in Objective C.

<br>

* What about the case when multiple threads is involved ?

For example if your observed property is being set with new value on one thread, and you expect to update UI with new value in the callback block executed on main thread. You can use the extended API for specifing a `NSOperationQueue` parameter.

```
[foo observeKeyPath:@keyPath(foo.name) identifier:nil queue:[NSOperationQueue mainQueue] forChanges:^(id receiver, id oldValue, id newValue) {
    // perform on main thread
}];
```

If you are familiar with `-addObserverForName:object:queue:usingBlock:` for `NSNotificationCenter`, then there is no barrier for using this API.

<br>

* What happen if the receiver is never deallocated ? Are these implicit generated receivers is gonna keep alive forever ?

Theoretically YES, but you can call `-[foo unobserveKeyPath:@keyPath(foo.name)]` to manually do the clean-up when you finish the observing. 

<br>

* What other issues that might occur for using YJSafeKVO's APIs ?

Think about this case: There are multiple objects observing the property of the singleton object (which is never being released), and you call `[singleton unobserveKeyPath:]` after one of objects is done observing. The singleton object will remove all observers which related to that key path, which will cause other objects can not be able to keep observing the same key path continuously.

To solve the problem, calling `[singleton observeKeyPath:identifier:queue:forChanges/Updates:]` to pass a unique string as an identifier for each observing operation or a group of operations by the same object. Then you can call `[singleton unobserveKeyPath:forIdentifier:]` which will only stop observing operations and remove observers which match the identifier you specified. This is a fine-grain control for performing manually clean-up without side-effect.

After you call `-unobserve...` prefixed methods, it only help you clean up the observers which generated by YJSafeKVO, and not go the extra mile for removing other observers which created by other approaches (if you are using system APIs or other third party APIs).

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

To run the example project, clone the repo, and run `pod install` from the Example directory first.

<br>

## Author

huang-kun, jack-huang-developer@foxmail.com

<br>

## License

YJSafeKVO is available under the MIT license. See the LICENSE file for more info.


