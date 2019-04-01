## 导入方式

```
pod 'DzyImagePicker'
```

## 初始化方式

正方形：  

```swift
// 默认正方形、需要裁剪  所以可以不进行参数的赋值
let vc = DzyImagePickerVC()
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo1.gif)  


长方形:  

```swift
let vc = DzyImagePickerVC()
// 0.66 = 宽 / 高
vc.cropScale = 0.66
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo2.gif)  


原图:  

```swift
let vc = DzyImagePickerVC()
vc.delegate = self
vc.ifCrop = false
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

## 获取结果

```swift
func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage) {
    imgView.image = image
}

func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage) {
    imgView.image = image
}
```