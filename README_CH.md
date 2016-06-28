# YJSafeKVO

[![CI Status](http://img.shields.io/travis/huang-kun/YJSafeKVO.svg?style=flat)](https://travis-ci.org/huang-kun/YJSafeKVO)
[![Version](https://img.shields.io/cocoapods/v/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![License](https://img.shields.io/cocoapods/l/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)
[![Platform](https://img.shields.io/cocoapods/p/YJSafeKVO.svg?style=flat)](http://cocoapods.org/pods/YJSafeKVO)

## 简介

If you prefer reading in English, tap [here](https://github.com/huang-kun/YJSafeKVO/blob/master/README.md).

<br>

### 先来吐槽

在`Cocoa`和`Cocoa Touch`编程中，`KVO`的范式一直扮演着重要的角色：你需要添加观察者、观察属性值的改变、移除观察者。如果实现的稍有差错，那么结果基本就是崩溃。

举个例子：

（假设foo和bar都是实例变量，他们的类继承自NSObject）

当你需要观察foo的某个属性时，添加了bar作为观察者，但是忘了在foo被销毁前移除bar的话，于是你就收获了一份的崩溃日志：

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'An instance 0x100102560 of class Foo was deallocated while key value observers were still registered with it. Current observation info: <NSKeyValueObservationInfo 0x100104990> (
<NSKeyValueObservance 0x100104770: Observer: 0x100102f30, Key path: count, Options: <New: YES, Old: YES, Prior: NO> Context: 0x0, Property: 0x100100340>
)'
```

当然还有一些情况，比如当你需要观察的对象的类是有系统创建提供的话，那么你不可能通过重载`-dealloc`的方法来释放观察者，毕竟这不是自己写的类（也可以有其他解决方案，但实现起来并不优雅）。

再举个例子：

如果需要添加多个观察者的话，那么还得保证删除的时候一一对应。如果删除少了，就是上面的崩溃；删除错了，就是下面的崩溃。


```
*** Terminating app due to uncaught exception 'NSRangeException', reason: 'Cannot remove an observer <Bar 0x100202de0> for the key path "count" from <Foo 0x100202ac0> because it is not registered as an observer.'
```

再举个例子：

如果添加了观察者，又不用去观察，也会崩溃。

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '<Bar: 0x1002000b0>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
Key path: count
Observed object: <Foo: 0x100200080>
Change: { kind = 1; new = 1; old = 0; }
Context: 0x0'
```

<br>

### 解决方案

虽然不管这些API是有多么的难用跟危险，`KVO`本身还是相当的重要。但是作为一名开发者，我只不过想调用一些简单的方法来完成目的而已。于是这里给出了解决方法：

`YJSafeKVO`的目标，就是为已经适应`Cocoa`编程的开发者，提供一套使用简洁的接口，避免由于操作不当而引发不必要的崩溃。

* 支持block参数
* 会隐式生成观察者，并且自动清理，没有以上崩溃问题
* 当不需要观察的时候，允许自行停止观察行为
* 支持在同一个对象的同一个keyPath中添加多次观察行为
* 支持标记一个（或多个）观察行为，以便自行停止观察的时候指定所要停止的观察行为
* 支持`NSOperationQueue`用于添加回调block
* 提供了`@keyPath`静态检查

如果我需要观察foo的属性name，在name的值改变时做出响应，那么我就调用：

```
[foo observeKeyPath:@"name"
            options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
    			     // foo更新了name的值
            }];
```

还可以这样写（推荐）：

```
[foo observeKeyPath:@keyPath(foo.name)
            options:YJKeyValueObservingOldToNew
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
    			     // foo更新了name的值
            }];
```

<br>

### 设计理念

这套`KVO`不允许自行添加观察者。调用`YJSafeKVO`提供的API，会隐式生成观察者，并很好的在内部被组织和管理。

**为什么要把观察者给隐藏起来？**

* 为了保持API的使用简洁，减少困惑
* 降低了由于管理观察者而造成问题的可能性
* 允许观察相同的keyPath而生成多个观察者
* 由于生成的观察者是自我管理的，因此能够保证观察者在被观察者释放前，首先被移除掉，从而避免崩溃

**难道真的没有控制观察者的途径吗？**

其实有的，而且也应该有的。可以调用方法的时候通过设置`identifier`参数来为每个或者一组观察者指定一个标记，以便未来的时候可以人为去清理。这时只需要清理匹配了标记的观察者，而不是所有观察了同一个keyPath的观察者。

设想一下这个情况：现在有个单例对象的同一个属性被很多其他对象所观察着，当其中一个对象结束观察以后，如果调用`[singleton unobserveKeyPath:]`的话，会导致观察这个属性的所有观察者都被释放，那么其他的对象也就无法继续进行观察了。

为了避免这个问题，需要：

* 调用`[singleton observeKeyPath:options:identifier:queue:changes:]`传入`identifier`来标记观察者
* 调用`[singleton unobserveKeyPath:forIdentifier:]`就只会移除匹配了标记的观察者

<br>

### 关于疑虑

#### 为什么要定义`YJKeyValueObservingOldToNew`和`YJKeyValueObservingUpToDate` ？

因为个人原因，会常用到这两个值。比如`YJKeyValueObservingOldToNew`其实就是替代了`NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew`，而每次又懒得写上一堆文字来表示一个组合值，希望代码能更简短些。而`YJKeyValueObservingUpToDate`则表示`.Initial | .New`，意味着使用后block会立即收到回调。

<br>

#### 这个`@keyPath`是神马 ?

它具有静态检查`key path`的特性（不用填写字符串对象，然后等到运行时再去判断）。自从苹果宣布`Swift 3`将支持`#keyPath`的特性以后，可以得出一个结论：对于`key path`的静态检查不仅能够保证代码安全，并且也会成为趋势。在`Objective C`中使用`@keyPath`就跟使用`@selector`差不多是一个道理。

<br>

#### 如果牵扯进了其他线程该怎么办 ？

比如你观察的属性在其他线程中被赋值，但是你期望block能在主线程中回调并且更新UI。你可以使用另一个API，专门指定一个`NSOperationQueue`对象作为参数用于回调。

```
[foo observeKeyPath:@keyPath(foo.name)
            options:YJKeyValueObservingOldToNew
         identifier:nil
              queue:[NSOperationQueue mainQueue]
            changes:^(id  _Nonnull receiver, id  _Nullable newValue, NSDictionary<NSString *,id> * _Nonnull change) {
                // 回调将在主线程中执行
            }];
```

如果你对`NSNotificationCenter`的`-addObserverForName:object:queue:usingBlock:`不陌生的话，那么使用上面的方法就不成问题了。

<br>

#### 假如被观察者一直不被释放的话，那么所有产生的观察者就一直不被释放喽 ？

理论上说是的，不过当你完成观察任务后，你可以调用`-[foo unobserveKeyPath:@keyPath(foo.name)]`来自行清理观察者。

<br>

#### 对于使用`YJSafeKVO`提供的接口还需要注意哪些问题呢 ?

1. 在回调block中，默认会带有一个`newValue`的参数，但是不包含`oldValue`，如果需要的话，可以从change字典中获取。

2. 当你调用任何带有`unobserve..`前缀的方法时，它所做的只是清除由`YJSafeKVO`隐式生成的观察者，而不会好心地去帮你清理其他的观察者（比如你自己使用系统提供的方法或者其他第三方库的方法创建的观察者）。

3. 还有需要留意的就是`YJSafeKVO`所产生的所属关系链，被观察的消息接收者对象拥有隐式生成的观察者，隐式持有block对象，当接收者被销毁时，整个链条就会从顶端开始依次释放对象。特别注意的就是在使用block的时候，需要避免引用循环即可。

<br>

### 兼容情况

由于`KVO`是源于`Cocoa`编程的范式，因此只要被观察的对象继承于`NSObject`的话，它自然会与生俱来这种特性，但是对于`Swift`来说，`struct`以及基类不属于`NSObject`的实例对象就无法使用`KVO`了。

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

YJSafeKVO is available under the MIT license. See the LICENSE file for more info.






