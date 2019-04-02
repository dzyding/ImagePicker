//
//  PickerManager.swift
//  Example
//
//  Created by edz on 2019/4/1.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit

/// 统一保存，不然几个界面间跳转的时候，需要传来传去的
struct PickerManager {
    
    static var `default` = PickerManager()
    /// 高 / 宽
    var cropScale: CGFloat = 1
    
    var ifCrop: Bool = true
    
    weak var delegate: DzyImagePickerVCDelegate?
    
    /// 读取 bundle 中的图片
    public func loadImageFromBunlde(_ name: String) -> UIImage? {
        let bundle = Bundle(url: Bundle(for: DzyImagePickerVC.self).url(forResource: "DzyImagePicker", withExtension: "bundle")!)
        return UIImage(contentsOfFile: bundle?.path(forResource: name, ofType: "png") ?? "")
    }
}
