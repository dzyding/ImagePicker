## 简介
仿微信裁剪头像功能，多图选择

## 待开发功能
优化内存

## 导入方式

```
pod 'DzyImagePicker'
```

## 初始化方式

正方形：  

```swift
let vc = DzyImagePickerVC(.edit(.square))
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo1.gif)  


长方形:  

```swift
let vc = DzyImagePickerVC(.edit(.rect(0.66)))
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

![gif](https://github.com/dzyding/ImagePicker/blob/master/demo2.gif)  


原图:  

```swift
let vc = DzyImagePickerVC(.origin(.single))
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

多张原图:

```swift
let vc = DzyImagePickerVC(.origin(.several(9)))
vc.delegate = self
let navi = UINavigationController(rootViewController: vc)
present(navi, animated: true, completion: nil)
```

## 获取结果

```swift
// 裁剪过的单图
func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage) {

}

// 原图
func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage) {

}

// 多图，选择完毕
func selectedFinshAndBeginDownload(_ picker: DzyImagePickerVC?) {

}

// 多图，获取结果
func imagePicker(_ picker: DzyImagePickerVC?, getImages imgs: [UIImage]) {
    
}
```