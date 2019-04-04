//
//  TakePhotoBtn.swift
//  Example
//
//  Created by edz on 2019/4/2.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

class TakePhotoBtn: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let size = bounds.size
        let x = size.width / 2.0
        let center = CGPoint(x: x, y: x)
        
        let context = UIGraphicsGetCurrentContext()
        context?.addArc(center: center, radius: x, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: false)
        context?.setFillColor(UIColor(red: 220.0 / 255.0, green: 220.0 / 255.0, blue: 220.0 / 255.0, alpha: 0.7).cgColor)
        context?.fillPath()
        context?.addArc(center: center, radius: x - 10.0, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: false)
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillPath()
    }

}
