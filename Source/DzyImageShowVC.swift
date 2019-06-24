//
//  DzyImageShowVC.swift
//  Example
//
//  Created by edz on 2019/6/24.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

/// 仅仅是展示用
class DzyImageShowVC: UIViewController, CustomBackBtnProtocol {
    
    private let topH: CGFloat = 50.0
    
    private let image: UIImage
    
    init(_ image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    deinit {
        dzy_log("销毁")
    }

    private func initUI() {
        scrollView.addSubview(imageIV)
        view.addSubview(scrollView)
        customBackBtn().addTarget(
            self,
            action: #selector(backAction),
            for: .touchUpInside
        )
    }
    
    @objc private func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    //    MARK: - 缩放的方法
    private func zoomingFun() {
        //等比例放大图片以后，让放大后的ImageView保持在ScrollView的中央
        let offsetX = scrollView.bounds.size.width > scrollView.contentSize.width ?
            (scrollView.bounds.size.width - scrollView.contentSize.width ) / 2.0 : 0.0
        let offsetY = scrollView.bounds.size.height > scrollView.contentSize.height ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2.0 : 0.0
        imageIV.center = CGPoint(x: scrollView.contentSize.width / 2.0 + offsetX, y: scrollView.contentSize.height / 2.0 + offsetY)
    }
    
    //    MARK: - 懒加载
    private lazy var scrollView: UIScrollView = {
        var frame = UIScreen.main.bounds
        let scrollView = UIScrollView(frame: frame)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.contentSize = frame.size
        return scrollView
    }()
    
    private lazy var imageIV: UIImageView = {
        let frame = scrollView.bounds
        let imgView = UIImageView(frame: frame)
        imgView.image = image
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
}

extension DzyImageShowVC: UIScrollViewDelegate {
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageIV
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomingFun()
    }
}
