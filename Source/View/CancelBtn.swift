//
//  CancelBtn.swift
//  Example
//
//  Created by edz on 2019/4/3.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

class CancelBtn: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let width: CGFloat = 32.0
        let height: CGFloat = 15.0
        let rect = CGRect(x: (bounds.size.width - width) / 2.0, y: (bounds.size.height - height) / 2.0, width: width, height: height)
        context?.setLineWidth(2)
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context?.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context?.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        context?.strokePath()
    }
}
