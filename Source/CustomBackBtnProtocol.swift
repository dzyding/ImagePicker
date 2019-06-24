//
//  CustomBackBtnProtocol.swift
//  Example
//
//  Created by edz on 2019/6/24.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

protocol CustomBackBtnProtocol where Self: UIViewController {
    func customBackBtn() -> UIButton
}

extension CustomBackBtnProtocol {
    func customBackBtn() -> UIButton {
        navigationItem.hidesBackButton = true
        
        let image = PickerManager.default.loadImageFromBunlde("back")
        let left = UIButton(type: .custom)
        left.setImage(image, for: .normal)
        left.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let leftBtn = UIBarButtonItem(customView: left)
        navigationItem.leftBarButtonItem = leftBtn
        return left
    }
}
