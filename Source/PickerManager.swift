//
//  PickerManager.swift
//  190119_DKImagePickerController
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
}
