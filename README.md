# Promise

使用promise的三大要素实现的一个简单的promise库。 

具体可以查看这篇[blog](https://www.jianshu.com/p/5a737083aec1)

# 使用

可以类似这样去封装一个Promise:

```swift
func getModel() -> Promise<Model> {
    let promise = Promise<Model>()
    modelService.load(
        onSuccess: promise.fulfill,
        onFailed: promise.reject
    )
    return promise
}
```

然后再链式处理。

```swift
    getModel()
    .then({
        transfromToViewModel($0)
    })
    .then(on: DispatchQueue.main) {
        display($0)
    }
```

