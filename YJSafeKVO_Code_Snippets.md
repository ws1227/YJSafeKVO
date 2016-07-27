# YJSafeKVO Code Snippets 

-observe:updates:

```
[<#subscriber#> observe:PACK(<#target#>, <#keyPath#>) updates:^(<#SubscriberClass *subscriber#>, <#TargetClass *target#>, <#NewValueClass * _Nullable newValue#>) {
    <#code#>
}];
```

-bound:

```
[PACK(<#Subscriber#>, <#KeyPath#>) bound:PACK(<#Target#>, <#KeyPath#>)];
```

-piped:convert:

```
[[[PACK(<#subscriber#>, <#keyPath#>) piped:PACK(<#target#>, <#keyPath#>)] convert:^id _Nullable(<#SubscriberClass *subscriber#>, <#TargetClass *target#>, <#NewValueClass * _Nullable newValue#>) {
    <#Code#>
}] ready];
```

-piped:convert:after:

```
 [[[[PACK(<#subscriber#>, <#keyPath#>) piped:PACK(<#target#>, <#keyPath#>)]
    convert:^id _Nonnull(<#SubscriberClass *subscriber#>, <#TargetClass *target#>, <#NewValueClass * _Nullable newValue#>) {
        return <#Code#>;
    }]
   after:^(id  _Nonnull subscriber, id  _Nonnull target) {
       <#Code#>
   }] ready];
```
    
-piped:taken:convert:after:

```
[[[[[PACK(<#subscriber#>, <#keyPath#>) piped:PACK(<#target#>, <#keyPath#>)]
     taken:^BOOL(<#SubscriberClass *subscriber#>, <#TargetClass *target#>, <#NewValueClass * _Nullable newValue#>) {
         return <#code#>;
     }]
     convert:^id _Nonnull(<#SubscriberClass *subscriber#>, <#TargetClass *target#>, <#NewValueClass * _Nullable newValue#>) {
         return <#code#>;
     }]
     after:^(<#SubscriberClass *subscriber#>, <#TargetClass *target#>) {
         <#code#>
     }] ready];
```

-flooded:reduce:

```
[PACK(<#subscriber#>, <#keyPath#>) flooded:@[ PACK(<#target1#>, <#keyPath1#>), PACK(<#target2#>, <#keyPath2#>) ] reduce:^id _Nullable(<#NewValueClass * _Nullable newValue1#>, <#NewValueClass * _Nullable newValue2#>) {
    return <#code#>;
}];
```




