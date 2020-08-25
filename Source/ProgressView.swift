//
//  ProgressView.swift
//  Example
//
//  Created by dingzhiyuan on 2020/8/25.
//  Copyright © 2020 灰s. All rights reserved.
//

import UIKit

public enum ProgressType {
    /// 光一个圈
    case hud
    /// 圈加上汉字
    case hudAndText
}

public class ProgressView: UIView {
    
    private let type: ProgressType
    
    public init(_ type: ProgressType) {
        self.type = type
        super.init(frame: UIScreen.main.bounds)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        dzy_log("销毁")
    }
    
    private func initUI() {
        backgroundColor = .clear
        addSubview(bgView)
        pView.addSubview(hudView)
        switch type {
        case .hudAndText:
            pView.addSubview(msgLB)
        case .hud:
            break
        }
        addSubview(pView)
    }
    
//    MARK: - 显示、隐藏、更新
    public func show(_ view: UIView) {
        view.addSubview(self)
        updateLayout(view)
    }
    
    public func disMiss() {
        updateLayout(nil)
        removeFromSuperview()
    }
    
    public func updateMsg(_ str: String?) {
        msgLB.text = str
    }
    
//    MARK: - 更新约束
    private func updateLayout(_ superView: UIView?) {
        if let _ = superview {
            hudView.startAnimating()
            snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets.zero)
            }
            bgView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets.zero)
            }
            pView.snp.makeConstraints { (make) in
                make.centerX.centerY.equalToSuperview()
                make.width.height.equalTo(90.0)
            }
            switch type {
            case .hud:
                hudView.snp.makeConstraints { (make) in
                    make.centerY.centerX.equalToSuperview()
                }
            case .hudAndText:
                msgLB.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-5)
                    make.height.equalTo(25)
                }
                hudView.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().offset(5)
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(msgLB.snp.top)
                }
            }
        }else {
            hudView.stopAnimating()
            snp.removeConstraints()
            bgView.snp.removeConstraints()
            pView.snp.removeConstraints()
            hudView.snp.removeConstraints()
            msgLB.snp.removeConstraints()
        }
    }
    
//    MARK: - 控件
    /// 背面的半透明视图
    private lazy var bgView: UIView = {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let x: CGFloat = 10.0 / 255.0
        let view = UIView(frame: CGRect(x: 0, y: 0,
                                       width: width, height: height))
        view.backgroundColor = UIColor(red: x, green: x,
                                       blue: x, alpha: 0.5)
        return view
    }()
    
    /// 中间的圈圈视图
    private lazy var pView: UIView = {
        let wh = 90.0
        let x: CGFloat = 200.0 / 255.0
        let view = UIView(frame: CGRect(x: 0, y: 0,
                                       width: x, height: x))
        view.backgroundColor = UIColor(red: x, green: x,
                                       blue: x, alpha: 0.9)
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    /// 菊花
    private lazy var hudView = UIActivityIndicatorView(style: .whiteLarge)
    
    /// label
    private lazy var msgLB: UILabel = {
        let label = UILabel()
        label.textColor = PickerConfig.MainColor
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()
}
