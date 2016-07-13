# YJSafeKVO

[![CI Status](http://img.shields.io/travis/huang-kun/YJSafeKVO.svg?style=flat)](https://travis-ci.org/huang-kun/YJSafeKVO)
[![Version](https://img.shields.io/cocoapods/v/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/huang-kun/YJSafeKVO/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)

## Introduction

如果你更倾向于阅读中文，可以点击[这里](https://github.com/huang-kun/YJSafeKVO/blob/master/README_CH.md)。

<br>

### Problems

The key value observing pattern is really important for the Cocoa and Cocoa Touch programming. You add an observer, observe the value changes, remove it when you finish. 

However, if you not use it correctly, the results are basically crashes.

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'An instance 0x100102560 of class Foo was deallocated while key value observers were still registered with it. Current observation info: <NSKeyValueObservationInfo 0x100104990> (
<NSKeyValueObservance 0x100104770: Observer: 0x100102f30, Key path: name, Options: <New: YES, Old: YES, Prior: NO> Context: 0x0, Property: 0x100100340>
)'
```

```
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <Bar 0x100202de0> for the key path "name" from <Foo 0x100202ac0> because it is not registered as an observer.'
```

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '<Bar: 0x1002000b0>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
Key path: name
Observed object: <Foo: 0x100200080>
Change: { kind = 1; new = 1; old = 0; }
Context: 0x0'
```

<br>

### YJSafeKVO's Pattern

Despite the usability and safefy, KVO is still important. As a developer, you probably just want to use some simple APIs to achieve the goal. Here comes `YJSafeKVO`. 

If A observes the change of B's name, then call:

```
[A observeTarget:B keyPath:@"name" updates:^(id A, id B, id _Nullable newValue) {
    // Update A based on newValue...
}];
```

Reading this is much natural semantically, or you can simply using `PACK` macro. (Recommended)

```
[A observe:PACK(B, name) updates:^(id A, id B, id _Nullable newValue) {
    // Update A based on newValue...
}];
```

That's it. No extra work. No crashes. It just works.

<br>

### New features

#### Binding (from 2.1.2)

It is availalbe for binding target to observer. When value changes, it will set changes from target's key path to observer's key path automatically. It looks like this:

```
[PACK(foo, name) bound:PACK(bar, name)];
```

The foo's name will set value from bar's name immediately, and for every changes from bar's name.

There is another version:

```
[[PACK(foo, name) piped:PACK(bar, name)] ready];
```

So what cases for using `piped:`? `piped:` is available for flexible nesting calls (e.g. `taken:`, `convert:`, `after:`). For instance, adding `convert:` for different types of value convertion:

```
[[[PACK(foo, mood) piped:PACK(bar, money)] convert:id^(...){
    return money > 100 ? @(Happy) : @(Sad);
}] ready];
```

or adding `after:` for performing additional works after value updating.

```
[[[PACK(foo, name) piped:PACK(bar, name)] after:^(...){
    NSLog(@"foo just change a new name.");
}] ready];
```

or nesting them together.

```
[[[[PACK(foo, mood) piped:PACK(bar, money)] convert:id^(...){
    return money > 100 ? @(Happy) : @(Sad);
}] after:^(...){
    NSLog(@"foo changed its mood!");
}] ready];
```

However, if your final result is determined by more than one changing factor, you can use `flooded:`, which will take changes from multiple sources and reduce them into a single value.

```
[PACK(clown, name) flooded:@[ PACK(foo, name),
                              PACK(bar, name) ] 
                  converge:^id(id  _Nonnull observer, NSArray * _Nonnull targets) {
    UNPACK(Foo, foo)
    UNPACK(Bar, bar)
    return [foo.name stringByAppendingString:bar.name];
}];
```

<br>

### Philosophy

#### Graph

Here is a graph showing about the relationships from `YJSafeKVO`

```
                               Target
                                  |
                            PorterManager
                                  |
              |--------------------------------------|
           keyPath1                              keyPath2 ...
  |-----------|-----------|                    |-----|-----
porter      porter      porter  ...          porter      ...
  |           |           |                    |
(block)     (block)     (block)              (block)
  |-----|-----|           |                    |
    Observer1         Observer2  ...       Observer1

```

<br>

#### Roles

**Target**

The target acts as the top level owner that owns the whole KVO chain because it is the source of value changes and it has the responsibility to notify the observers. 

**Porter**

Calling APIs provided by `YJSafeKVO` will generate object called `porter` which will be added to observed target implicitly and it's porter's job to deliver the value changes to the object who wants to handle the changes. Porter carries changes by using a block.

**PorterManager**

Each target has an associated `PorterManager` to manage all porters generated by observing target's key path. Manager takes porters and groups them by keyPath. 

Since porters are managed internally, so they will be removed from target automatically before target is deallcated and this will prevent a large scale of general KVO crashes.

**Observer**

The object which calls "-observeTarget:" or "-observe:" should be treated as the observer, because it is the one who really wants to observe and handles the value change.

<br>

#### Ownership

This is the ownership inside of `YJSafeKVO`.

* Strong Reference chain: Target -> PorterManager -> Porters
* Weak Reference chain: Porter -> Observer -> Target

To make the ownership work as expected, you need to avoid retain cycle.

```
[self observe:PACK(self.foo, name) updates:^(id receiver, id target, id _Nullable newName) {
    NSLog(@"%@", self); // Retain cycle (self -> foo -> porter -> block -> self)
}];
```

To solve the issue: change `receiver` variable to `self`.

```
[self observe:PACK(self.foo, name) updates:^(id self, id foo, id _Nullable newName) {
    NSLog(@"%@", self); // No retain cycle because using self as an local variable.
}];
```

<br>

#### Consequence

If target is deallocated, it's manager with all porters are gone, which means the entire graph is disappeared. 

If the observer is going to be deallocated before target, that case only related porters will automatically leave the graph as well.  

So basically there is no required manually `-addObserver:..` or `-removeObserver:..` kind of traditional operation because it happens when either target or observer gets released. However if there is the case that neither of them is released and you'd like to stop observation when you finish observing, you can manually call `-[observer unobserve..]` to stop observing target for it's key path.

<br>

### Questions

#### What about the case when multiple threads are involved ?

For example if your observed property is being set with new value on one thread, and you expect to update UI with new value in the callback block executed on main thread. You can use the extended API for specifing a `NSOperationQueue` parameter.

```
[self observe:PACK(self.foo, name)
      options:NSKeyValueObservingOptionNew
        queue:[NSOperationQueue mainQueue]
      changes:^(id receiver, id target, NSDictionary *change) {
    // Callback on main thread
}
```

If you are familiar with `-addObserverForName:object:queue:usingBlock:` for `NSNotificationCenter`, then there is no barrier for using this API.

<br>

#### What other things that you might want to know for using YJSafeKVO's APIs ?

After you call `-unobserve...` prefixed methods, it only help you clean up the observers which generated by `YJSafeKVO`, and not go the extra mile for removing other observers which created by other approaches (if you are using system APIs or other third party APIs).
			            
<br>

### Compatibility

The key value observing is the pattern from Cocoa programming. Any object as subclass of NSObject will get it for free. It also means this feature is not applied for Swift's struct, and for it's class object which root class is not NSObject.

<br>

## Requirement

YJSafeKVO needs at least Xcode 7.3 for `NS_SWIFT_NAME` avaliable, so it can expose APIs for swift and feels more swifty.

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


