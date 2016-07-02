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

### 解决方案

虽然不管这些API是有多么的难用跟危险，`KVO`本身还是相当的重要。但是作为一名开发者，我只不过想调用一些简单的方法来完成目的而已。于是这里有了`YJSafeKVO`：

比如在controller的实现中，假如你需要观察foo的name属性的变化，在获得新值后来更新label，只需要：

```
[self observeTarget:self.foo keyPath:@"name" updates:^(Controller *self, Foo *foo, NSString *newValue) {
    if (newValue) self.label.text = newValue;
}];
```

或者使用`YJKVO`宏表达式：

```
[self observe:YJKVO(self.foo, name) updates:^(Controller *self, Foo *foo, NSString *newValue) {
    if (newValue) self.label.text = newValue;
}];
```

没有崩溃和引用循环（把block中的变量receiver改为self），It just work.

<br>

### 设计理念

`YJSafeKVO`不允许自行添加观察者。调用`YJSafeKVO`提供的API，会隐式生成观察者，并很好的在内部被组织和管理。

**为什么要把观察者给隐藏起来？**

* 为了保持API的使用简洁，减少困惑
* 降低了由于管理观察者而造成问题的可能性
* 允许观察相同的keyPath而生成多个观察者
* 由于生成的观察者是自我管理的，因此能够保证观察者在被观察者释放前，首先被移除掉，从而避免崩溃

<br>

### 关于疑虑

#### 如果牵扯进了其他线程该怎么办 ？

比如你观察的属性在其他线程中被赋值，但是你期望block能在主线程中回调并且更新UI。你可以专门指定一个`NSOperationQueue`对象作为参数用于回调。

```
[self observe:YJKVO(self.foo, name)
      options:NSKeyValueObservingOptionNew
        queue:[NSOperationQueue mainQueue]
      changes:^(id receiver, id target, NSDictionary *change) {
    // 回调将在主线程中执行
}
```

如果你对`NSNotificationCenter`的`-addObserverForName:object:queue:usingBlock:`不陌生的话，那么使用上面的方法就不成问题了。

<br>

#### 对于使用`YJSafeKVO`提供的接口还需要注意哪些问题呢 ?

1. 当你调用任何带有`unobserve..`前缀的方法时，它所做的只是清除由`YJSafeKVO`隐式生成的观察者，而不会好心地去帮你清理其他的观察者（比如你自己使用系统提供的方法或者其他第三方库的方法创建的观察者）。

2. 还有需要说明的就是`YJSafeKVO`所产生的所属关系链，被观察的目标对象(target)拥有隐式生成的观察者(observers)，而观察者会持有block对象，当被观察者(target)被释放时，整个链条就会从顶端开始依次释放对象；当消息接收者(receiver, 或者说订阅者subscriber)在被观察者释放前被释放的话，只有与其相关的隐式观察者会被依次释放。

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






