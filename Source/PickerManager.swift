//
//  PickerManager.swift
//  Example
//
//  Created by edz on 2019/4/1.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit

@objc public protocol DzyImagePickerVCDelegate {
    /// 裁剪过的
    func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage)
    /// 原始图片
    func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage)
}

// 拍完照保存图片
let Notice_SaveImage = Notification.Name("DzySaveImage")

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
