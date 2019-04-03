//
//  FocusView.swift
//  Example
//
//  Created by edz on 2019/4/3.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit
import SnapKit

class FocusView: UIView {
    
    private let color = UIColor(red: 232.0 / 255.0, green: 155.0 / 255.0, blue: 55.0 / 255.0, alpha: 1)
    // 是否需要移除
    public var lastTime: Double?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        transform = transform.scaledBy(x: 1.3, y: 1.3)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform.identity
        }) { (_) in
            self.updateLastTime()
        }
    }
    
    public func updateLastTime() {
        lastTime = Date().timeIntervalSince1970
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.removeAction()
        }
    }
    
    public func removeAction() {
        let now = Date().timeIntervalSince1970
        if let lastTime = lastTime,
            now - lastTime >= 1
        {
            removeFromSuperview()
        }
    }
    
    private func setUI() {
        let topLine = UIView()
        topLine.backgroundColor = color
        addSubview(topLine)
        
        let bottomLine = UIView()
        bottomLine.backgroundColor = color
        addSubview(bottomLine)
        
        let image = PickerManager.default.loadImageFromBunlde("sun")
        let imgView = UIImageView(image: image)
        imgView.contentMode = .scaleAspectFit
        addSubview(imgView)
        
        let x = bounds.size.width / 4.0
        imgView.snp.makeConstraints { (make) in
            make.left.equalTo(x * 3.0 - 12.5)
            make.height.width.equalTo(25.0)
            make.centerY.equalTo(self)
        }
        
        topLine.snp.makeConstraints { (make) in
            make.right.equalTo(-x)
            make.top.equalTo(0)
            make.width.equalTo(1)
            make.bottom.equalTo(imgView.snp.top)
        }
        
        bottomLine.snp.makeConstraints { (make) in
            make.right.width.equalTo(topLine)
            make.bottom.equalTo(0)
            make.top.equalTo(imgView.snp.bottom)
        }
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(1)
        let x = rect.size.width / 2.0
        let startPoint = CGPoint(x: 0, y: (rect.height - x) / 2.0)
        // 正方形
        context?.move(to: startPoint)
        context?.addLine(to: CGPoint(x: 0, y: startPoint.y + x))
        context?.addLine(to: CGPoint(x: x, y: startPoint.y + x))
        context?.addLine(to: CGPoint(x: x, y: startPoint.y))
        context?.addLine(to: startPoint)
        
        // 每个边的突出
        let length: CGFloat = 7.0
        context?.move(to: CGPoint(x: 0, y: x))
        context?.addLine(to: CGPoint(x: length, y: x))
        context?.move(to: CGPoint(x: x / 2.0, y: startPoint.y + x))
        context?.addLine(to: CGPoint(x: x / 2.0, y: startPoint.y + x - length))
        context?.move(to: CGPoint(x: x, y: x))
        context?.addLine(to: CGPoint(x: x - length, y: x))
        context?.move(to: CGPoint(x: x / 2.0, y: startPoint.y))
        context?.addLine(to: CGPoint(x: x / 2.0, y: startPoint.y + length))
        
        context?.strokePath()
    }
}
