//
//  PickerManager.swift
//  Example
//
//  Created by edz on 2019/4/1.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import Photos

public protocol DzyImagePickerVCDelegate: class {
    /// 裁剪过的
    func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage)
    /// 原始图片
    func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage)
    
    /// 多张图片选择完毕，开始加载
    func selectedFinshAndBeginDownload(_ picker: DzyImagePickerVC?)
    /// 获取多张图片
    func imagePicker(_ picker: DzyImagePickerVC?, getImages imgs: [UIImage])
}

struct PickerConfig {
    static let MainColor = UIColor(
        red: 253.0/255.0, green: 126.0/255.0, blue: 37.0/255.0, alpha: 1
    )
    /// 多选时图片的最大宽/高
    static let maxSize: Int = 1500
    /// 缩略图
    static let smallSize: CGSize = {
        let screenW = UIScreen.main.bounds.size.width
        let scale = UIScreen.main.scale
        let x = (screenW - 6.0) / 4.0
        return CGSize(width: x * scale, height: x * scale)
    }()
    /// 异步
    static let asynOption: PHImageRequestOptions = {
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        return option
    }()
    /// 同步
    static let synOption: PHImageRequestOptions = {
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = true
        return option
    }()
}

public struct PickerNotice {
    // 拍完照保存图片
    static let SaveImage = Notification.Name("DzySaveImage")
}

/// 统一保存，不然几个界面间跳转的时候，需要传来传去的
struct PickerManager {
    
    static var `default` = PickerManager()
    
    var type: DzyImagePickerType = .origin(.single)
    
    weak var delegate: DzyImagePickerVCDelegate?
    
    /// 读取 bundle 中的图片
    public func loadImageFromBunlde(_ name: String) -> UIImage? {
        let bundle = Bundle(url: Bundle(for: DzyImagePickerVC.self).url(forResource: "DzyImagePicker", withExtension: "bundle")!)
        return UIImage(contentsOfFile: bundle?.path(forResource: name, ofType: "png") ?? "")
    }
}

public func dzy_log<T>(_ msg: T, file: String = #file, line:Int = #line) {
    #if DEBUG
    guard let fileName:String = file.components(separatedBy: "/").last else {
        print("文件位置错误")
        return
    }
    print("[\(fileName)_line:\(line)]- \(msg)")
    #endif
}
