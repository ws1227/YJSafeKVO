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

Despite the usability and safefy from default APIs, KVO is still important. As a developer, you probably just want to use some simple APIs to achieve the goal. Here comes `YJSafeKVO`. There are 3 patterns:

* Observing
* Subscribing
* Broadcasting

<br>

#### Observing

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

A is considered as "Observer", or "Subscriber". B is considered as observed "Target".

<br>

#### Subscribing

It is availalbe for binding target to subscriber. When value changes, it will set changes from target's key path to subscriber's key path automatically. It looks like this:

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

It also supports `-cutOff:` for cutting off the relationship between subscriber's key path and target's key path after using `-bound:` or `-piped:`.

<br>

#### Broadcasting

Posting value changes directly.

```
[PACK(foo, name) post:^(NSString *name) {
    NSLog(@"foo has changed a new name: %@.", name);
}];
```

The foo is consider as a sender, when foo's name sets new value, it sends changes to the block.

<br>

#### There is one more thing 

Should I worry about removing observer before object is deallocated, so I can prevent crashes ? 

No! No extra work is required. Choose the pattern you like, and `YJSafeKVO` takes care the rest. It just work.

<br>

### Philosophy

#### Graph

Here is a graph showing `Observing` or `Subscribing`.

```
                               Target
                                  |
                          Subscriber Manager
                                  |
              |--------------------------------------|
          Subscriber1 (weak)                    Subscriber2 (weak)   ...
              |                                      |
        Porter Manager                         Porter Manager
   |----------|-----------|                    |-----|-----
Porter1    Porter2     Porter3  ...         Porter4      ...
   |          |           |                    |
(block)    (block)     (block)              (block)

```

Here is a graph showing `Broadcasting`.

```
                                Sender
                                  |
                            Porter Manager
                                  |
              |-------------------|------------------|
           Porter1             Porter2            Porter3   ...
              |                   |                  |
           (block)             (block)            (block)

```

<br>

#### Roles

**Target or Sender**

Target or Sender is the source that value changes from. It always stay at the top of KVO chain. 

**Subscriber**

The object which calls "-observeTarget:" or "-observe:" should be treated as the observer, because it is the one who really wants to observe and handles the value change. To try not to confuse the concept, I use "subscriber" instead.

**Porter**

Porter will be generated during KVO process and its job is to deliver the value changes to the object who wants to handle. Porter carries changes via a block.

**Porter Manager**

The object managing the porters. It usually owned by subscriber or sender.

**Subscriber Manager**

The object managing the subscribers. It usually owned by target. Unlike porter manager, the subscriber manager holds subscribers weakly.

<br>

#### Consequence

If target or sender is deallocated, the graph tree is gone. If one of subscribers is deallocated before target, only that branch of the graph tree is gone.

If you want to stop observation when you finish observing before any of them is deallocated, you can manually call `-unobserve..`, `-cutOff:` or `-stop` to stop observing. 

<br>

### Tips

#### Avoid retain cycle

It easily to cause retain cycle by using block.

```
[self observe:PACK(self.foo, name) updates:^(id receiver, id target, id _Nullable newName) {
    NSLog(@"%@", self); // Retain cycle
}];
```

To solve the issue: change `receiver` variable to `self`. No need extra `__weak`.

```
[self observe:PACK(self.foo, name) updates:^(id self, id foo, id _Nullable newName) {
    NSLog(@"%@", self); // No retain cycle because using self as an local variable.
}];
```

By the way, `-post:` method doesn't contains much parameters in its block. Be careful.

<br>

#### Deal with threads

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

#### Allodoxaphobia: "Observing", "Subscribing" or "Broadcasting" ???

There is not much differences between "Observing" and "Subscribing" because they share the same graph tree. The "Observing" is treated as "Omnipotent Pattern" in `YJSafeKVO` because whatever any other patterns can do, "Observing" can do as well. Here is an example for a view controller observing network conntection status and make a batch of changes when status is changed.

```
[self observe:PACK(reachability, networkReachabilityStatus) updates:^(MyViewController *self, AFNetworkReachabilityManager *reachability, NSValue *newValue) {
    AFNetworkReachabilityStatus status = [newValue integerValue];
    BOOL connected = (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi);
    self.label.text = connected ? @"Conntected" : @"Disconnected";
    self.button.enable = connected;
    self.view.backgroundColor = connected ? UIColor.whiteColor : UIColor.grayColor;
    ...
}];
```

The reason for using "Subscribing" is for the idea that you want one state is completely binded and decided by other states, so it will change value automatically rather than manually set by developer.

The difference between "Observing" and "Broadcasting" is:

* `[subscriber observe:PACK(target, keyPath) updates:block]` will release block when: 
	- subscriber is deallocated.
	- target is deallocated.
	- manually call `[subscriber unobserve:PACK(target, keyPath)]`
* `[PACK(sender, keyPath) post:block]` will release block when:
	- sender is deallocated.
	- manually call `[PACK(sender, keyPath) stop]`

Here is a concrete example: If you want to observe the property value changes from a global singleton object, it is better using "Observing" pattern rather than "Broadcasting". 

* Use "Observing" - Subscriber can be release anytime because it's not being strongly holded by it's target. When the subscriber is deallocated, it automatically handle the releasing work. It will only release the subscriber's branch.
* Use "Broadcasting" - If you want to release the post block, you need to manually stop posting by calling `[PACK(singleton, property) stop]`. This action will release the whole keyPath's observation and it might affecting other places in code where objects still want to observe its value changes.

<br>

#### Code snippets

Tired of typing? There are pre-defined code snippets for you to integrate them into Xcode. One benefit by using `YJSafeKVO` code snippets is you just need to fill the placeholder token in the method template, which including the block parameters, so you can explicit define the type and variable name as the block parameter to avoid the retain cycle issue (e.g. write self inside of block).

See "YJSafeKVO_Code_Snippets.md" file or click [here](https://github.com/huang-kun/YJSafeKVO/blob/master/YJSafeKVO_Code_Snippets.md) to check out code snippets, and define your own favourite ones.

<br>

### Swift Compatibility

The key value observing is the pattern from Cocoa programming. Any object as subclass of NSObject will get it for free. It also means this feature is not applied for Swift's struct, and for it's class object which root class is not NSObject.

Observing:

```
foo.observe(PACK(bar, "name")) { (_, _, newValue) in
    print("\(newValue)")
}
```

Subscribing:

```
PACK(foo, "name").bound(PACK(bar, "name"))
```

Build a complex pipe:

```
PACK(foo, "name").piped(PACK(bar, "name"))
    .taken { (_, _, newValue) -> Bool in
        if let name = newValue as? String {
            return name.characters.count > 3
        }
        return false
    }
    .convert { (_, _, newValue) -> AnyObject in
        let name = newValue as! String
        return name.uppercaseString
    }
    .after { (_, _) in
        print("value updated.")
    }
    .ready()
    
bar.name = "Bar" // foo.name is not receiving "Bar"
bar.name = "Barrrr" // foo.name is "BARRRR" 
```

Broadcasting:

```
PACK(foo, "name").post { (newValue) in
    if let name = newValue as? String {
        print("new name: \(name)")
    }
}
```

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


