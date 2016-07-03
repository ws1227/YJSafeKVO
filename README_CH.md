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

（假设foo和bar都是实例变量，他们的类继承自NSObject）

```
[foo addObserver:bar forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
// 还要去其他地方实现处理观察值的变化
[foo removeObserver:bar forKeyPath:@"name"];
```

如果实现的稍有差错，那么结果基本就是崩溃。

举个例子：

当你需要观察foo的某个属性时，添加了bar作为观察者，但是忘了在foo被销毁前移除bar的话，于是你就收获了一份的崩溃日志：

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'An instance 0x100102560 of class Foo was deallocated while key value observers were still registered with it. Current observation info: <NSKeyValueObservationInfo 0x100104990> (
<NSKeyValueObservance 0x100104770: Observer: 0x100102f30, Key path: name, Options: <New: YES, Old: YES, Prior: NO> Context: 0x0, Property: 0x100100340>
)'
```

当然还有一些情况，比如当你需要观察的对象的类是有系统创建提供的话，那么你不可能通过重载`-dealloc`的方法来释放观察者，毕竟这不是自己写的类（也可以有其他解决方案，但实现起来并不优雅）。

再举个例子：

如果需要添加多个观察者的话，那么还得保证删除的时候一一对应。如果删除少了，就是上面的崩溃；删除错了，就是下面的崩溃。


```
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <Bar 0x100202de0> for the key path "name" from <Foo 0x100202ac0> because it is not registered as an observer.'
```

再举个例子：

如果添加了观察者，又不用去观察，也会崩溃。

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '<Bar: 0x1002000b0>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
Key path: name
Observed object: <Foo: 0x100200080>
Change: { kind = 1; new = 1; old = 0; }
Context: 0x0'
```

<br>

### YJSafeKVO的范式

虽然不管这些API是有多么的难用跟危险，`KVO`本身还是相当的重要。但是作为一名开发者，我只不过想调用一些简单的方法来完成目的而已。于是这里有了`YJSafeKVO`：

```
[subscriber observeTarget:target keyPath:@"target's property" updates:^(id subscriber, id target, id _Nullable newValue) {
    // 处理值的更新
}];
```

如果A要观察B的属性name的变化，调用方法如下：

```
[A observeTarget:B keyPath:@"name" updates:^(id A, id B, id _Nullable newName) {
    // 根据newName来更新A
}];
```

这样阅读起来也更加自然，或者使用`OBSV`宏以后直接写成"-observe:"

```
[A observe:OBSV(B, name) updates:^(id A, id B, id _Nullable newName) {
    // 根据newName来更新A
}];
```

<br>

### 设计理念

#### 结构图

这张图大致描绘了`YJSafeKVO`的关系结构

```
                               Target
                                  |
                               Manager
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

#### 角色

**被观察对象(Target)**

由于被观察对象是观测值变化的源头，并且它承担着及时通知观察者有关值改变的义务，因此被观察的对象处于KVO链条顶端。

**搬运工(Porter)**

搬运工在注册观察行为的时候被创建出来，它们的工作就是将新的变化值传递给真正想要处理这些变化的对象。它们会把变化包装在一个block中。

**管理者(Manager)**

每个被观察的对象都有一个管理者，来管理这些由于注册观察行为而衍生的搬运工。管理者会把搬运工按照不同的keyPath划分为独立的小组。

由于管理搬运工的机制属于内在行为，那么当被观察者即将被释放的时候，这些搬运工会自动被移除，从而避免了大多数由人为地添加和移除操作不当而造成KVO的崩溃。

**观察者(Observer)**

调用`-observeTarget:` or `-observe:`的对象（或消息接收者）在这里应该被看成是观察者。因为它们才是真正需要观察并及时响应变化的对象。

<br>

#### 因果

当被观察者释放的时候，与之相关的管理者以及所有搬运工都将被释放，也就意味着整个关系图的结束。

如果观察者在被观察者释放之前即将销毁的话，那么与之相关的搬运工也会跟着被释放。

因此关于内部对象释放的工作都是自动完成的，条件就是被观察者或者观察者即将释放的时刻。但是如果二者都不会释放，这时候想要停止观察行为的话，可以人为调用`-[observer unobserve..]`方法来停止观察相应的keyPath。

<br>


### 关于疑虑

#### 如果牵扯进了其他线程该怎么办 ？

比如你观察的属性在其他线程中被赋值，但是你期望block能在主线程中回调并且更新UI。你可以专门指定一个`NSOperationQueue`对象作为参数用于回调。

```
[self observe:OBSV(self.foo, name)
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

### 兼容情况

由于`KVO`是源于`Cocoa`编程的范式，因此只要被观察的对象继承于`NSObject`的话，它自然会与生俱来这种特性，但是对于`Swift`来说，`struct`以及基类不属于`NSObject`的实例对象就无法使用`KVO`了。

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






