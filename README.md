## 导入方式

```
pod 'DzyImagePicker'
```

## 使用方式

正方形：  

```swift
let vc = DzyImagePickerVC()
vc.handler = {
    self.imgView.image = $0
}
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo1.gif)  


长方形:  

```swift
let vc = DzyImagePickerVC()
// 0.66 = 宽 / 高
vc.cropScale = 0.66
vc.handler = {
    self.imgView.image = $0
}
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo2.gif)