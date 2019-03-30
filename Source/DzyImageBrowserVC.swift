//
//  DzyImageBrowserVC.swift
//  190119_DKImagePickerController
//
//  Created by edz on 2019/3/15.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import Photos
import SnapKit

enum CornerTag: Int {
    ///左上
    case LT = 1
    /// 左下
    case LB
    /// 右上
    case RT
    /// 右下
    case RB
}

enum CropType {
    case square
    case rectangle(CGFloat) // 高 : 宽
}

public class DzyImageBrowserVC: UIViewController {
    
    private var sW = UIScreen.main.bounds.size.width
    
    private var sH = UIScreen.main.bounds.size.height
    // 裁剪类型
    let type: CropType
    // 最小缩放值
    private let minSize: CGFloat = 50.0
    // iPhone 原始图片数据
    private let photo: PHAsset
    // 缩放图片用的
    private weak var scrollView: UIScrollView?
    // 显示图片用的
    private weak var imgView: UIImageView?
    // 正中间的占位图
    private weak var tempView: UIView?
    // 提交按钮
    private weak var sureBtn: UIButton?
    // 用来判断是否需要还原
    private var lastMoveTime: TimeInterval?
    // 四个角
    private var corners: [UIView] = []
    // 四个最终值
    private var lastPoints = [CGPoint](repeatElement(.zero, count: 4))
    // 隐藏状态栏
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    // 中间占位图的 frame
    lazy var rectF: CGRect = {
        let x: CGFloat = 20.0
        let width = sW - 40.0
        switch type {
        case .square:
            let y = (sH - width) / 2.0
            return CGRect(x: x, y: y, width: width, height: width)
        case .rectangle(let n):
            let height = width * n
            let y = (sH - height) / 2.0
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }()
    
    weak var pickerVC: DzyImagePickerVC?
    
    init(_ photo: PHAsset, type: CropType = .square) {
        self.photo = photo
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setNeedsStatusBarAppearanceUpdate()

        basicStep()
        setMoveView()
        loadImage()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    //    MARK: - 读取照片
    func loadImage() {
        let manager = PHImageManager.default()
        let size = CGSize(width: photo.pixelWidth, height: photo.pixelHeight)
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = true
        manager.requestImage(for: photo, targetSize: size, contentMode: .aspectFit, options: option) { (image, info) in
            self.updateViews(image)
        }
    }
    
    //    MARK: - 设置初始的状态
    func updateViews(_ image: UIImage?) {
        guard let image = image else {return}
        imgView?.image = image
        let imageWHRatio = image.size.width / image.size.height
        var x: CGFloat = 0
        var y: CGFloat = 0
        var w: CGFloat = 0
        var h: CGFloat = 0
        if imageWHRatio < 1 {
            w = imageWHRatio * rectF.height
            h = rectF.height
            x = (rectF.width - w) / 2.0 + (sW - rectF.width) / 2.0
            y = (sH - rectF.height) / 2.0
        }else {
            x = (sW - rectF.width) / 2.0
            w = rectF.width
            h = rectF.width / imageWHRatio
            y = (rectF.height - h) / 2.0 + (sH - rectF.height) / 2.0
        }
        imgView?.frame = CGRect(x: x, y: y, width: w, height: h)
        setScale(image)
    }
    
    // 设置缩放比例
    func setScale(_ image: UIImage) {
        guard let imgView = imgView else {return}
        let imageWHRatio = image.size.width / image.size.height
        // 计算最小缩放比例
        var scale: CGFloat = 0
        var autoScale: CGFloat = 0
        if imageWHRatio < 1 {
            scale = rectF.width / imgView.frame.size.width
        }else {
            scale = rectF.height / imgView.frame.size.height
        }
        
        autoScale = rectF.width / imgView.frame.size.width
        
        scrollView?.minimumZoomScale = scale
        scrollView?.setZoomScale(autoScale, animated: true)
        // 这里有时候不会自动进入 didZoom 的代理
        zoomingFunction()
    }
    
    //    MARK: - 移动操作
    @objc func panAction(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            hideBlackCover()
            lastMoveTime = nil
            checkLastPoint(pan)
        case .changed:
            panUpdateViews(pan)
        case .ended:
            updateLastPoints(pan)
            lastMoveTime = Date().timeIntervalSince1970
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.panEndAction()
            }
        default:
            break
        }
    }
    
    //    MARK: - lastPoints
    // pan 结束以后刷新所有的 lastPoint
    func updateLastPoints(_ pan: UIPanGestureRecognizer) {
        if pan.view == corners[0] {
            let old = lastPoints[0]
            let new = pan.translation(in: pan.view)
            let x = safeX(old, new: new, corner: .LT)
            lastPoints[0] = CGPoint(x: old.x + x, y: old.y + x)
            
            var temp1 = lastPoints[1]
            temp1.x += x
            lastPoints[1] = temp1
            
            var temp2 = lastPoints[2]
            temp2.y += x
            lastPoints[2] = temp2
        }else if pan.view == corners[1] {
            let old = lastPoints[1]
            let new = pan.translation(in: pan.view)
            let x = safeX(old, new: new, corner: .LB)
            lastPoints[1] = CGPoint(x: old.x - x, y: old.y + x)

            var temp0 = lastPoints[0]
            temp0.x -= x
            lastPoints[0] = temp0

            var temp3 = lastPoints[3]
            temp3.y += x
            lastPoints[3] = temp3
        }else if pan.view == corners[2] {
            let old = lastPoints[2]
            let new = pan.translation(in: pan.view)
            let x = safeX(old, new: new, corner: .RT)
            lastPoints[2] = CGPoint(x: old.x - x, y: old.y + x)
            
            var temp0 = lastPoints[0]
            temp0.y += x
            lastPoints[0] = temp0
            
            var temp3 = lastPoints[3]
            temp3.x -= x
            lastPoints[3] = temp3
        }else if pan.view == corners[3] {
            let old = lastPoints[3]
            let new = pan.translation(in: pan.view)
            let x = safeX(old, new: new, corner: .RB)
            lastPoints[3] = CGPoint(x: old.x + x, y: old.y + x)
            
            var temp1 = lastPoints[1]
            temp1.y += x
            lastPoints[1] = temp1
            
            var temp2 = lastPoints[2]
            temp2.x += x
            lastPoints[2] = temp2
        }
    }
    
    // pan 开始时
    func checkLastPoint(_ pan: UIPanGestureRecognizer) {
        var point = CGPoint.zero
        corners.enumerated().forEach { (index, v) in
            if v == pan.view {
                point = lastPoints[index]
            }
        }
        pan.setTranslation(point, in: pan.view)
    }
    
    // 清除
    func clearLastPoint() {
        lastPoints = [CGPoint](repeatElement(.zero, count: 4))
    }
    
    //    MARK: - 隐藏和显示黑色遮罩
    func showBlackCover() {
        (901...904).forEach { (tag) in
            if let v = view.viewWithTag(tag) {
                v.isHidden = false
            }
        }
        sureBtn?.isHidden = false
    }
    
    func hideBlackCover() {
        (901...904).forEach { (tag) in
            if let v = view.viewWithTag(tag) {
                v.isHidden = true
            }
        }
        sureBtn?.isHidden = true
    }
    
    //    MARK: - safeX
    func safeX(_ old: CGPoint, new: CGPoint, corner: CornerTag) -> CGFloat {
        guard let tempView = tempView else {return new.x - old.x}
        switch corner {
        case .LT:
            let lb_point = lastPoints[1]
            let change = (new.y + new.x - old.x - old.y) / 2.0
            if old.x < old.y && old.x + change <= 0 {
                return -old.x
            }else if old.x >= old.y && old.y + change <= 0 {
                return -old.y
            }else if old.y - lb_point.y + change >= tempView.frame.height - minSize {
                return tempView.frame.width - minSize + lb_point.y - old.y
            }else {
                return change
            }
        case .LB:
            let lt_point = lastPoints[0]
            let change = ((new.y - new.x) - (old.y - old.x)) / 2.0
            if old.x < abs(old.y) && old.x - change <= 0 {
                return old.x
            }else if old.x >= abs(old.y) && old.y + change >= 0 {
                return -old.y
            }else if lt_point.y - old.y - change >= tempView.frame.height - minSize {
                return -(tempView.frame.height - minSize - lt_point.y + old.y)
            }else {
                return change
            }
        case .RT:
            let lb_point = lastPoints[1]
            let change = ((new.y - new.x) - (old.y - old.x)) / 2.0
            if abs(old.x) < old.y && old.x - change >= 0 {
                return old.x
            }else if abs(old.x) >= old.y && old.y + change <= 0 {
                return -old.y
            }else if old.y - lb_point.y + change >= tempView.frame.height - minSize {
                return tempView.frame.width - minSize + lb_point.y - old.y
            }else {
                return change
            }
        case .RB:
            let lt_point = lastPoints[0]
            let change = (new.y + new.x - old.x - old.y) / 2.0
            if abs(old.x) < abs(old.y) && old.x + change >= 0 {
                return -old.x
            }else if abs(old.x) >= abs(old.y) && old.y + change >= 0 {
                return -old.y
            }else if lt_point.y - old.y - change >= tempView.frame.height - minSize {
                return -(tempView.frame.height - minSize - lt_point.y + old.y)
            }else {
                return change
            }
        }
    }
    
    //    MARK: - 接着 pan 手势之后做滑动或放大时
    func panNextAction() {
        if let last = lastMoveTime,
            Date().timeIntervalSince1970 - last <= 2 // 两秒内接着 pan 的手势滑动 scrollView
        {
            lastMoveTime = Date().timeIntervalSince1970
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.panEndAction()
            }
        }else {
            lastMoveTime = nil
        }
    }
    
    //    MARK: - 拖动时的处理
    func panUpdateViews(_ pan: UIPanGestureRecognizer) {
        if let v = pan.view,
            let tempView = tempView
        {
            let lt_point = lastPoints[0]
            let lb_point = lastPoints[1]
            let rt_point = lastPoints[2]
            let new = pan.translation(in: v)
            let old = lastPoints[pan.view!.tag - 1]
            // 左上
            if v.tag == CornerTag.LT.rawValue {
                //(100, 100)
                var x = (new.y + new.x - old.x - old.y) / 2.0
                
                switch type {
                case .square:
                    if old.x >= old.y {
                        if old.y + x <= 0 {
                            x = -old.y
                        }else if rectF.size.width - old.x + rt_point.x - x <= minSize {
                            x = rectF.size.width - old.x + rt_point.x - minSize
                        }
                    }else {
                        if old.x + x <= 0 {
                            x = -old.x
                        }else if rectF.size.height - old.y + lb_point.y - x <= minSize {
                            x = rectF.size.height - old.y + lb_point.y - minSize
                        }
                    }
                case .rectangle:
                    if old.x >= old.y && old.y + x <= 0 {
                        x = -old.y
                    }else if old.x < old.y && old.x + x <= 0 {
                        x = -old.x
                    }else if rectF.size.height - old.y + lb_point.y - x <= minSize {
                        x = rectF.size.height - old.y + lb_point.y - minSize
                    }
                }
                
                v.snp.updateConstraints { (make) in
                    make.top.equalTo(tempView).offset(-3 + old.y + x)
                    make.left.equalTo(tempView).offset(-3 + old.x + x)
                }
            }
            
            // 左下
            if v.tag == CornerTag.LB.rawValue {
                var x = ((new.y - new.x) - (old.y - old.x)) / 2.0
                
                switch type {
                case .square:
                    if old.x >= abs(old.y) {
                        if old.y + x >= 0 {
                            x = -old.y
                        }else if rectF.size.width - old.x + rt_point.x + x <= minSize {
                            x = -(rectF.size.width - old.x + rt_point.x - minSize)
                        }
                    }else {
                        if lt_point.x - x <= 0 {
                            x = lt_point.x
                        }else if rectF.size.height + old.y - rt_point.y + x <= minSize {
                            x = -(rectF.size.height + old.y - rt_point.y - minSize)
                        }
                    }
                case .rectangle:
                    if old.x >= abs(old.y) && old.y + x >= 0 {
                        x = -old.y
                    }else if old.x < abs(old.y) && lt_point.x - x <= 0 {
                        x = lt_point.x
                    }else if rectF.size.height + old.y - lt_point.y + x <= minSize {
                        x = -(rectF.size.height + old.y - rt_point.y - minSize)
                    }
                }
                
                if let lt = view.viewWithTag(CornerTag.LT.rawValue) {
                    lt.snp.updateConstraints { (make) in
                        make.left.equalTo(tempView).offset(-3 + lt_point.x - x)
                    }
                }
                v.snp.updateConstraints { (make) in
                    make.bottom.equalTo(tempView).offset(3 + old.y + x)
                }
            }
            
            // 右上
            if v.tag == CornerTag.RT.rawValue {
                var x = ((new.y - new.x) - (old.y - old.x)) / 2.0
                
                switch type {
                case .square:
                    if abs(old.x) >= old.y {
                        if lt_point.y + x <= 0 {
                            x = -lt_point.y
                        }else if rectF.size.width + old.x - lt_point.x - x <= minSize {
                            x = rectF.size.width + old.x - lt_point.x - minSize
                        }
                    }else {
                        if old.x - x >= 0 {
                            x = old.x
                        }else if rectF.size.height + lb_point.y - old.y - x <= minSize {
                            x = rectF.size.height + lb_point.y - old.y - minSize
                        }
                    }
                case .rectangle:
                    if abs(old.x) >= old.y && lt_point.y + x <= 0 {
                        x = -lt_point.y
                    }else if abs(old.x) < old.y && old.x - x >= 0 {
                        x = old.x
                    }else if rectF.size.height + lb_point.y - old.y - x <= minSize {
                        x = rectF.size.height + lb_point.y - old.y - minSize
                    }
                }
                
                if let lt = view.viewWithTag(CornerTag.LT.rawValue) {
                    lt.snp.updateConstraints { (make) in
                        make.top.equalTo(tempView).offset(-3 + lt_point.y + x)
                    }
                }
                v.snp.updateConstraints { (make) in
                    make.right.equalTo(tempView).offset(3 + old.x - x)
                }
            }
            
            // 右下
            if v.tag == CornerTag.RB.rawValue {
                var x = (new.y + new.x - old.x - old.y) / 2.0
                
                switch type {
                case .square:
                    if abs(old.x) >= abs(old.y) {
                        if lb_point.y + x >= 0 {
                            x = -lb_point.y
                        }else if rectF.size.width + old.x - lt_point.x + x <= minSize {
                            x = -(rectF.size.width + old.x - lt_point.x - minSize)
                        }
                    }else {
                        if rt_point.x + x >= 0 {
                            x = -rt_point.x
                        }else if rectF.size.height + old.y - rt_point.y + x <= minSize {
                            x = -(rectF.size.height + old.y - rt_point.y - minSize)
                        }
                    }
                case .rectangle:
                    if abs(old.x) >= abs(old.y) && lb_point.y + x >= 0 {
                        x = -lb_point.y
                    }else if abs(old.x) < abs(old.y) && rt_point.x + x >= 0 {
                        x = -rt_point.x
                    }else if rectF.size.height + old.y - rt_point.y + x <= minSize {
                        x = -(rectF.size.height + old.y - rt_point.y - minSize)
                    }
                }
                
                
                if let rt = view.viewWithTag(CornerTag.RT.rawValue) {
                    rt.snp.updateConstraints { (make) in
                        make.right.equalTo(tempView).offset(3 + rt_point.x + x)
                    }
                }
                if let lb = view.viewWithTag(CornerTag.LB.rawValue) {
                    lb.snp.updateConstraints { (make) in
                        make.bottom.equalTo(tempView).offset(3 + lb_point.y + x)
                    }
                }
            }
        }
    }
    
    //    MARK: - 拖动完成以后还原
    func panEndAction() {
        guard let lastMoveTime = lastMoveTime,
            Date().timeIntervalSince1970 - lastMoveTime >= 2,
            let tempView = tempView else {return}
        self.lastMoveTime = nil
        view.isUserInteractionEnabled = false
        clearLastPoint()
        zoomToSelectRect()
        
        corners[0].snp.updateConstraints({ (make) in
            make.top.left.equalTo(tempView).offset(-3)
        })
        corners[1].snp.updateConstraints({ (make) in
            make.bottom.equalTo(tempView).offset(3)
        })
        corners[2].snp.updateConstraints { (make) in
            make.right.equalTo(tempView).offset(3)
        }
        view.needsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
            self.showBlackCover()
        }) { (_) in
            self.view.isUserInteractionEnabled = true
        }
    }
    
    //    MARK: - 放大到指定的区域
    func zoomToSelectRect() {
        let ltFrame = corners[0].frame
        let rbFrame = corners[3].frame
        let ltpoint = view.convert(CGPoint(x: ltFrame.origin.x + 3, y: ltFrame.origin.y + 3), to: imgView)
        let rbpoint = view.convert(CGPoint(x: rbFrame.maxX - 3, y: rbFrame.maxY - 3), to: imgView)
        let width = rbpoint.x - ltpoint.x
        let height = rbpoint.y - ltpoint.y
        let rect = CGRect(x: ltpoint.x, y: ltpoint.y, width: width, height: height)
        scrollView?.zoom(to: rect, animated: true)
    }
    
    
    //    MARK: - 取消 、还原 和 完成
    @objc func cancelAction() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func restoreAction() {
        scrollView?.setZoomScale(1, animated: true)
    }
    
    @objc func sureAction() {
        guard let imgView = imgView,
            let img = imgView.image,
            let scrollView = scrollView
        else {return}
        
        //图片大小和当前imageView的缩放比例
        let scaleRatio = img.size.width / imgView.frame.size.width
        //scrollView的缩放比例，即是ImageView的缩放比例
        let scrollScale = scrollView.zoomScale
        //裁剪框的 左上、右上和左下三个点在初始ImageView上的坐标位置（注意：转换后的坐标为原始ImageView的坐标计算的，而非缩放后的）
        var ltPoint = view.convert(rectF.origin, to: imgView)
        var rbPoint = view.convert(CGPoint(x: rectF.origin.x + rectF.size.width, y: rectF.origin.y + rectF.size.height), to: imgView)
        
        //计算两个点在缩放后imageView上的坐标
        ltPoint = CGPoint(x: ltPoint.x * scrollScale, y: ltPoint.y * scrollScale)
        rbPoint = CGPoint(x: rbPoint.x * scrollScale, y: rbPoint.y * scrollScale)
        
        //计算裁剪区域在原始图片上的位置
        let width = (rbPoint.x - ltPoint.x) * scaleRatio
        let height = (rbPoint.y - ltPoint.y) * scaleRatio
        let rect = CGRect(x: ltPoint.x * scaleRatio, y: ltPoint.y * scaleRatio, width: width, height: height)
        
        if let ref = img.cgImage,
            let final = ref.cropping(to: rect)
        {
            let new = UIImage(cgImage: final, scale: 1, orientation: .up)
            pickerVC?.handler?(new)
            dismiss(animated: true, completion: nil)
        }
    }
}

extension DzyImageBrowserVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        panNextAction()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imgView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        panNextAction()
        zoomingFunction()
    }
    
    func zoomingFunction() {
        guard let scrollView = scrollView else {return}
        //等比例放大图片以后，让放大后的ImageView保持在ScrollView的中央
        let offsetX = scrollView.bounds.size.width > scrollView.contentSize.width ?
            (scrollView.bounds.size.width - scrollView.contentSize.width ) / 2.0 : 0.0
        let offsetY = scrollView.bounds.size.height > scrollView.contentSize.height ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2.0 : 0.0
        imgView?.center = CGPoint(x: scrollView.contentSize.width / 2.0 + offsetX, y: scrollView.contentSize.height / 2.0 + offsetY)
        
        //设置scrollView的contentSize，最小为self.view.frame
        let scrollW = scrollView.contentSize.width >= sW ? scrollView.contentSize.width : sW
        let scrollH = scrollView.contentSize.height >= sH ? scrollView.contentSize.height : sH
        scrollView.contentSize = CGSize(width: scrollW, height: scrollH)
        
        //设置scrollView的contentInset
        let imageWidth  = imgView!.frame.size.width
        let imageHeight = imgView!.frame.size.height
        let cropWidth   = rectF.width
        let cropHeight  = rectF.height
        
        var leftRightInset: CGFloat = 0
        var topBottomInset: CGFloat = 0
        
        //imageview的大小和裁剪框大小的三种情况，保证imageview最多能滑动到裁剪框的边缘
        if imageWidth <= cropWidth {
            leftRightInset = 0
        }else if imageWidth >= cropWidth && imageWidth <= sW {
            leftRightInset = (imageWidth - cropWidth) / 2.0
        }else {
            leftRightInset = (sW - cropWidth) / 2.0
        }
        
        if imageHeight <= cropHeight {
            topBottomInset = 0
        }else if imageHeight >= cropHeight && imageHeight <= sH {
            topBottomInset = (imageHeight - cropHeight) / 2.0
        }else {
            topBottomInset = (sH - cropHeight) / 2.0
        }
        
        scrollView.contentInset = UIEdgeInsets(top: topBottomInset, left: leftRightInset, bottom: topBottomInset, right: leftRightInset)
    }
}

//MARK: -  UI
extension DzyImageBrowserVC {
    func basicStep() {
        let frame = UIScreen.main.bounds
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
        view.addSubview(scrollView)
        self.scrollView = scrollView
        
        let imgView = UIImageView(frame: frame)
        imgView.contentMode = .scaleAspectFill
        scrollView.addSubview(imgView)
        self.imgView = imgView
        
        let tempView = UIView(frame: rectF)
        tempView.isUserInteractionEnabled = false
        view.addSubview(tempView)
        self.tempView = tempView
        
        setBlackCoverView()
        
        let line = UIView()
        line.backgroundColor = UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 0.7)
        view.addSubview(line)
        
        let cancelBtn = UIButton(type: .custom)
        cancelBtn.setTitle("返回", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelBtn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
        let restoreBtn = UIButton(type: .custom)
        restoreBtn.setTitle("还原", for: .normal)
        restoreBtn.setTitleColor(.white, for: .normal)
        restoreBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        restoreBtn.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
        view.addSubview(restoreBtn)
        
        let sureBtn = UIButton(type: .custom)
        sureBtn.setTitle("完成", for: .normal)
        sureBtn.setTitleColor(.white, for: .normal)
        sureBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        sureBtn.addTarget(self, action: #selector(sureAction), for: .touchUpInside)
        view.addSubview(sureBtn)
        self.sureBtn = sureBtn
        
        line.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(1)
            make.bottom.equalTo(-70)
        }
        
        cancelBtn.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.width.height.equalTo(50)
            make.top.equalTo(line.snp.bottom).offset(10)
        }
        
        restoreBtn.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.width.height.equalTo(cancelBtn)
        }
        
        sureBtn.snp.makeConstraints { (make) in
            make.right.equalTo(-20)
            make.top.width.height.equalTo(cancelBtn)
        }
    }
    
    //    MARK: - 黑色遮罩
    func setBlackCoverView() {
        guard let tempView = tempView else {return}
        let color = UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 51.0 / 255.0, alpha: 0.8)
        
        func getView(_ tag: Int) -> UIView {
            let v = UIView()
            v.backgroundColor = color
            v.isUserInteractionEnabled = false
            v.tag = tag
            view.addSubview(v)
            return v
        }
        
        let top = getView(901)
        let bottom = getView(902)
        let left = getView(903)
        let right = getView(904)
        
        top.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(0)
            make.bottom.equalTo(tempView.snp.top)
        }
        
        bottom.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(0)
            make.top.equalTo(tempView.snp.bottom)
        }
        
        left.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.top.equalTo(top.snp.bottom)
            make.bottom.equalTo(bottom.snp.top)
            make.right.equalTo(tempView.snp.left)
        }
        
        right.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.top.equalTo(top.snp.bottom)
            make.bottom.equalTo(bottom.snp.top)
            make.left.equalTo(tempView.snp.right)
        }
    }
    
    //    MARK: - 设置可移动视图
    func setMoveView() {
        guard let tempView = tempView else {return}
        func getView(_ tag: Int) -> (UIView, UIView, UIView, UIPanGestureRecognizer) {
            let v = UIView()
            v.isUserInteractionEnabled = true
            v.backgroundColor = .clear
            v.tag = tag
            view.addSubview(v)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
            v.addGestureRecognizer(pan)
            
            let line1 = UIView()
            line1.backgroundColor = .white
            v.addSubview(line1)
            
            let line2 = UIView()
            line2.backgroundColor = .white
            v.addSubview(line2)
            
            return (v, line1, line2, pan)
        }
        // 左上
        let lt = getView(1)
        corners.append(lt.0)
        lt.0.snp.makeConstraints { (make) in
            make.top.left.equalTo(tempView).offset(-3)
            make.width.height.equalTo(30)
        }
        
        lt.1.snp.makeConstraints { (make) in
            make.left.top.equalTo(0)
            make.height.equalTo(20)
            make.width.equalTo(3)
        }
        
        lt.2.snp.makeConstraints { (make) in
            make.top.left.equalTo(0)
            make.width.equalTo(20)
            make.height.equalTo(3)
        }
        
        // 左下
        let lb = getView(2)
        corners.append(lb.0)
        lb.0.snp.makeConstraints { (make) in
            make.left.equalTo(lt.0)
            make.bottom.equalTo(tempView).offset(3)
            make.width.height.equalTo(30)
        }
        
        lb.1.snp.makeConstraints { (make) in
            make.left.bottom.equalTo(0)
            make.height.equalTo(20)
            make.width.equalTo(3)
        }
        
        lb.2.snp.makeConstraints { (make) in
            make.left.bottom.equalTo(0)
            make.width.equalTo(20)
            make.height.equalTo(3)
        }
        
        // 右上
        let rt = getView(3)
        corners.append(rt.0)
        rt.0.snp.makeConstraints { (make) in
            make.top.equalTo(lt.0)
            make.right.equalTo(tempView).offset(3)
            make.width.height.equalTo(30)
        }
        
        rt.1.snp.makeConstraints { (make) in
            make.top.right.equalTo(0)
            make.width.equalTo(20)
            make.height.equalTo(3)
        }
        
        rt.2.snp.makeConstraints { (make) in
            make.top.right.equalTo(0)
            make.height.equalTo(20)
            make.width.equalTo(3)
        }
        
        // 右下
        let rb = getView(4)
        corners.append(rb.0)
        rb.0.snp.makeConstraints { (make) in
            make.right.equalTo(rt.0)
            make.bottom.equalTo(lb.0)
            make.width.height.equalTo(30)
        }
        
        rb.1.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(0)
            make.height.equalTo(20)
            make.width.equalTo(3)
        }
        
        rb.2.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(0)
            make.width.equalTo(20)
            make.height.equalTo(3)
        }
        
        let topLine = UIView()
        topLine.backgroundColor = .clear
        topLine.isUserInteractionEnabled = false
        view.insertSubview(topLine, belowSubview: lt.0)
        
        let topShadow = UIView()
        topShadow.backgroundColor = .white
        topShadow.layer.shadowOffset = CGSize(width: 0, height: -1)
        topShadow.layer.shadowRadius = 3
        topShadow.layer.shadowColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1).cgColor
        topShadow.layer.shadowOpacity = 0.7
        topLine.addSubview(topShadow)

        topLine.snp.makeConstraints { (make) in
            make.top.equalTo(lt.0)
            make.left.equalTo(lt.0).offset(3)
            make.right.equalTo(rt.0).offset(-3)
            make.height.equalTo(4)
        }
        
        topShadow.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(1)
            make.bottom.equalTo(-1)
        }
        
        let bottomLine = UIView()
        bottomLine.backgroundColor = .clear
        bottomLine.isUserInteractionEnabled = false
        view.insertSubview(bottomLine, belowSubview: lt.0)
        
        let bottomShadow = UIView()
        bottomShadow.backgroundColor = .white
        bottomShadow.layer.shadowOffset = CGSize(width: 0, height: 1)
        bottomShadow.layer.shadowRadius = 3
        bottomShadow.layer.shadowColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1).cgColor
        bottomShadow.layer.shadowOpacity = 0.7
        bottomLine.addSubview(bottomShadow)

        bottomLine.snp.makeConstraints { (make) in
            make.bottom.equalTo(lb.0)
            make.left.right.equalTo(topLine)
            make.height.equalTo(4)
        }
        
        bottomShadow.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.top.equalTo(1)
            make.height.equalTo(1)
        }
        
        let leftLine = UIView()
        leftLine.backgroundColor = .clear
        leftLine.isUserInteractionEnabled = false
        view.insertSubview(leftLine, belowSubview: lt.0)
        
        let leftShadow = UIView()
        leftShadow.backgroundColor = .white
        leftShadow.layer.shadowOffset = CGSize(width: -1, height: 0)
        leftShadow.layer.shadowRadius = 3
        leftShadow.layer.shadowColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1).cgColor
        leftShadow.layer.shadowOpacity = 0.7
        leftLine.addSubview(leftShadow)
        
        leftLine.snp.makeConstraints { (make) in
            make.top.equalTo(lt.0).offset(3)
            make.bottom.equalTo(lb.0).offset(-3)
            make.left.equalTo(lt.0)
            make.width.equalTo(4)
        }
        
        leftShadow.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.width.equalTo(1)
            make.right.equalTo(-1)
        }

        let rightLine = UIView()
        rightLine.backgroundColor = .clear
        rightLine.isUserInteractionEnabled = false
        view.insertSubview(rightLine, belowSubview: lt.0)
        
        let rightShadow = UIView()
        rightShadow.backgroundColor = .white
        rightShadow.layer.shadowOffset = CGSize(width: 1, height: 0)
        rightShadow.layer.shadowRadius = 3
        rightShadow.layer.shadowColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1).cgColor
        rightShadow.layer.shadowOpacity = 0.7
        rightLine.addSubview(rightShadow)

        rightLine.snp.makeConstraints { (make) in
            make.top.equalTo(rt.0).offset(3)
            make.bottom.equalTo(rb.0).offset(-3)
            make.right.equalTo(rt.0)
            make.width.equalTo(4)
        }
        
        rightShadow.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(1)
            make.width.equalTo(1)
        }
        
        let vLineView = UIView()
        vLineView.backgroundColor = .clear
        vLineView.layer.borderWidth = 1
        vLineView.layer.borderColor = UIColor.white.cgColor
        vLineView.isUserInteractionEnabled = false
        view.addSubview(vLineView)
        
        vLineView.snp.makeConstraints { (make) in
            make.top.equalTo(topLine).offset(2)
            make.bottom.equalTo(bottomLine).offset(-2)
            make.width.equalTo(topLine).multipliedBy(0.33)
            make.centerX.equalTo(topLine)
        }
        
        let hLineView = UIView()
        hLineView.backgroundColor = .clear
        hLineView.layer.borderWidth = 1
        hLineView.layer.borderColor = UIColor.white.cgColor
        hLineView.isUserInteractionEnabled = false
        view.addSubview(hLineView)
        
        hLineView.snp.makeConstraints { (make) in
            make.left.equalTo(leftLine).offset(2)
            make.right.equalTo(rightLine).offset(-2)
            make.height.equalTo(leftLine).multipliedBy(0.33)
            make.centerY.equalTo(leftLine)
        }
    }
}
