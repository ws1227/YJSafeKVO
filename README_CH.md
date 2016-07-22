# YJSafeKVO

[![CI Status](http://img.shields.io/travis/huang-kun/YJSafeKVO.svg?style=flat)](https://travis-ci.org/huang-kun/YJSafeKVO)
[![Version](https://img.shields.io/cocoapods/v/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/huang-kun/YJSafeKVO/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)

## 简介

If you prefer reading in English, tap [here](https://github.com/huang-kun/YJSafeKVO/blob/master/README.md).

<br>

### 先来吐槽

在`Cocoa`和`Cocoa Touch`编程中，`KVO`的范式一直扮演着重要的角色：你需要添加观察者、观察属性值的改变、移除观察者。

如果实现的稍有差错，那么结果基本就是崩溃。

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

### YJSafeKVO的范式

虽然不管这些API是有多么的难用跟危险，`KVO`本身还是相当的重要。但是作为一名开发者，我只不过想调用一些简单的方法来完成目的而已，于是这里有了`YJSafeKVO`。有3种方法来使用它：

* 观察模式
* 订阅模式
* 广播模式

<br>

#### 观察模式

如果A要观察B的属性name的变化，调用方法如下：

```
[A observeTarget:B keyPath:@"name" updates:^(id A, id B, id _Nullable newValue) {
    // 根据newValue来更新A
}];
```

这样阅读起来也更加自然，或者使用`PACK`宏（推荐）

```
[A observe:PACK(B, name) updates:^(id A, id B, id _Nullable newName) {
    // 根据newValue来更新A
}];
```

无需额外的工作，没有崩溃，仅此而已。

<br>

#### 订阅模式 

`YJSafeKVO`支持了绑定观察者与观察对象，当对象keyPath的值改变时，就直接设置到观察者的keyPath中，比如：

```
[PACK(foo, name) bound:PACK(bar, name)];
```

调用`bound:`方法后，foo的name会设置为bar的name的值，并且当bar的name变化的时候，持续接收新的值。

以下是另一个版本：

```
[[PACK(foo, name) piped:PACK(bar, name)] ready];
```

什么时候适合用`piped:`呢？`piped:`可以连续进行多个额外调用（`taken:`, `convert:`, `after:`），比如添加`convert:`将不一样类型的keyPath进行值的转换：

```
[[[PACK(foo, mood) piped:PACK(bar, money)] convert:id^(...){
    return money > 100 ? @(Happy) : @(Sad);
}] ready];
```

或者添加`after:`在设置keyPath结束后进行额外的操作：

```
[[[PACK(foo, name) piped:PACK(bar, name)] after:^(...){
    NSLog(@"foo just change a new name.");
}] ready];
```

又或者将以上的情况结合起来：

```
[[[[PACK(foo, mood) piped:PACK(bar, money)] convert:id^(...){
    return money > 100 ? @(Happy) : @(Sad);
}] after:^(...){
    NSLog(@"foo changed its mood!");
}] ready];
```

如果你希望得到的最终结果需要由多个因素共同决定，那么使用`flooded:`方法，可以传递多个变化，并且返回为一个结果。

```
[PACK(clown, name) flooded:@[ PACK(foo, name),
                              PACK(bar, name) ] 
                  converge:^id(id  _Nonnull observer, NSArray * _Nonnull targets) {
    UNPACK(Foo, foo)
    UNPACK(Bar, bar)
    return [foo.name stringByAppendingString:bar.name];
}];
```

它还支持通过调用`-cutOff:`来斩断已建立的绑定关系。

<br>

#### 广播模式

广播模式可以直接对外发布键值的更新。

```
[PACK(foo, name) post:^(NSString *name) {
    NSLog(@"foo has changed a new name: %@.", name);
}];
```

这里的foo被看作是发布者(sender)，当foo的name有改动时，就会调用block。

简单说明下调用`-observe:updates:`和`post:`的区别：

* `[subscriber observe:PACK(target, keyPath) updates:block]`会在以下情况中释放block: 
	- subscriber被释放的时候
	- target被释放的时候
	- 调用`[subscriber unobserve:PACK(target, keyPath)]`的时候
* `[PACK(sender, keyPath) post:block]`会在以下情况中释放block:
	- sender被释放的时候
	- 调用`[PACK(sender, keyPath) stop]`的时候

<br>

### 设计理念

#### 结构图

这张图大致描绘了`观察模式`和`订阅模式`的树型结构

```
                               Target
                                  |
                          Subscriber Manager
                                  |
              |--------------------------------------|
          Subscriber1 (weak)                    Subscriber2 (weak)   ...
              |                                      |
        Porter Manager			                   Porter Manager
   |----------|-----------|                    |-----|-----
Porter1    Porter2     Porter3  ...         Porter4      ...
   |          |           |                    |
(block)    (block)     (block)              (block)

```

这张图描绘了`广播模式`的树型结构。

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

#### 角色

**目标对象(Target) 以及 发布者(sender)**

被观察的目标对象、以及发布者即是观测值变化的源头，它们总是处于KVO链条顶端。

**订阅者(Subscriber)**

调用`-observeTarget:` or `-observe:`的对象（或消息接收者）在这里应该被看成是观察者。因为它们才是真正需要观察并及时响应变化的对象。为了避免语义混淆，这里称之为订阅者。

**搬运工(Porter)**

搬运工在注册观察行为的时候被创建出来，它们的工作就是将新的变化值传递给真正想要处理这些变化的对象。它们会把变化包装在一个block中。

**包工头(Porter Manager)**

包工头负责管理搬运工。通常自己被订阅者或者发布者所拥有。

**订阅组织者(Subscriber Manager)**

它负责管理订阅者，与包工头不一样的是，它不会跟每位订阅者建立强引用关系。

<br>

#### 避免引用循环

使用block的时候一定需要避免引用循环问题。

```
[self observe:PACK(self.foo, name) updates:^(id receiver, id target, id _Nullable newName) {
    NSLog(@"%@", self); // 产生引用循环
}];
```

解决方法：将block中的变量`receiver`替换成`self`即可。

```
[self observe:PACK(self.foo, name) updates:^(id self, id foo, id _Nullable newName) {
    NSLog(@"%@", self); // 由于使用的self作为局部变量，因此不会产生引用循环。
}];
```

顺便提一句，`-post:`方法的block中没有提供这样的参数，使用需注意。

<br>

#### 因果

当被目标对象或发布者被释放的时候，整个树型结构也随之被释放；如果订阅者先释放的话，在树型结构中只有相应的分支被释放而已。

如果以上对象都没有释放，这时候想要停止观察行为的话，可以人为调用`-unobserve..`, `-cutOff:`或者`-stop`方法来停止接收变化。

<br>


### 关于疑虑

#### 如果牵扯进了其他线程该怎么办 ？

比如你观察的属性在其他线程中被赋值，但是你期望block能在主线程中回调并且更新UI。你可以专门指定一个`NSOperationQueue`对象作为参数用于回调。

```
[self observe:PACK(self.foo, name)
      options:NSKeyValueObservingOptionNew
        queue:[NSOperationQueue mainQueue]
      changes:^(id receiver, id target, NSDictionary *change) {
    // 回调将在主线程中执行
}
```

如果你对`NSNotificationCenter`的`-addObserverForName:object:queue:usingBlock:`不陌生的话，那么使用上面的方法就不成问题了。

<br>

#### 对于使用`YJSafeKVO`提供的接口还需要注意哪些问题呢 ?

当你调用任何带有`unobserve..`前缀的方法时，它所做的只是清除由`YJSafeKVO`隐式生成的观察者，而不会好心地去帮你清理其他的观察者（比如你自己使用系统提供的方法或者其他第三方库的方法创建的观察者）。

<br>

### 兼容Swift的情况

由于`KVO`是源于`Cocoa`编程的范式，因此只要被观察的对象继承于`NSObject`的话，它自然会与生俱来这种特性，但是对于`Swift`来说，`struct`以及基类不属于`NSObject`的实例对象就无法使用`KVO`了。

观察模式:

```
foo.observe(PACK(bar, "name")) { (_, _, newValue) in
    print("\(newValue)")
}
```

订阅模式:

```
PACK(foo, "name").bound(PACK(bar, "name"))
```

建立一个复杂的管道:

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

广播模式:

```
PACK(foo, "name").post { (newValue) in
    if let name = newValue as? String {
        print("new name: \(name)")
    }
}
```

<br>

## 环境要求

YJSafeKVO 需要Xcode 7.3以上的支持，用于使用`NS_SWIFT_NAME`来创建swift的API

<br>

## 安装

YJSafeKVO 支持 [CocoaPods](http://cocoapods.org). 安装的话只需要创建Podfile，并写入如下内容:

```ruby
pod "YJSafeKVO"
```

在`terminal`中运行`pod install`安装后，在项目的`ProjectName-Prefix.pch`文件中引入`#import <YJSafeKVO/YJSafeKVO.h>`头文件即可使用。

<br>

## 作者

huang-kun, jack-huang-developer@foxmail.com

<br>

## 许可

YJSafeKVO基于MIT许可，更多内容请查看LICENSE文件。






