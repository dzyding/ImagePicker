//
//  DzyImagePickerVC.swift
//  Example
//
//  Created by edz on 2019/1/19.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import Photos
import SnapKit

public enum DzyImagePickerType {
    case origin(OriginType) //原图
    case edit(EditType)     //编辑
    
    public enum OriginType {
        case single         // 单图
        case several(Int)   // 多张(张数)
    }
    
    public enum EditType {
        case square         //正方形
        case rect(CGFloat)  //长方形
    }
    
    var isSeveral: Bool {
        switch self {
        case .origin(.several):
            return true
        default:
            return false
        }
    }
    
    var maxCount: Int {
        switch self {
        case .origin(.several(let count)):
            return count
        default:
           return 0
        }
    }
}

public class DzyImagePickerVC: UIViewController, CustomBackBtnProtocol {
    /// 代理
    public weak var delegate: DzyImagePickerVCDelegate? {
        set {
            PickerManager.default.delegate = newValue
        }get {
            return PickerManager.default.delegate
        }
    }
    
    /// 图片选择器类型
    public var type: DzyImagePickerType {
        set {
            PickerManager.default.type = newValue
        }get {
            return PickerManager.default.type
        }
    }
    /// 选中状态 没张图片对应的被选中的顺序，未选中就是 -1
    public var select: [Int] = []
    /// 缓存
    public var caches = NSCache<NSString, UIImage>()
    /// apple 缓存策略
    public var cacheManager = PHCachingImageManager()
    /// 上一次瑜加载的区域
    public var previousPreheatRect = CGRect.zero
    /// 选中的数量
    public var selectedNum: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.sureBtn.setTitle(
                    "选择(\(self.selectedNum))", for: .normal
                )
            }
        }
    }
    /// 选中图片对应的 index (比如 sIndexs[1]，代表第二张图片对应的 index)
    public var sIndexs = [Int](repeating: -1, count: 20)
    
    public var album: String?
 
    public var photos: PHFetchResult<PHAsset>?
    
    private weak var collectionView: UICollectionView?
    
    private var observer: Any?
    
    public init(_ type: DzyImagePickerType) {
        super.init(nibName: nil, bundle: nil)
        self.type = type
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setNaviItem()
        setViewControllers()
        setCollectionView()
        setSureBtn()
        cacheManager.stopCachingImagesForAllAssets()
        
        if let photos = photos {
            navigationItem.title = album
            select = [Int](repeating: -1, count: photos.count)
        }else {
            navigationItem.title = "全部照片"
            checkAuthorization()
        }
        
        observer = NotificationCenter.default.addObserver(
            forName: PickerNotice.SaveImage,
            object: nil,
            queue: nil,
            using:
        { [weak self] (noti) in
            if let image = noti.userInfo?["image"] as? UIImage {
                self?.saveImage(image)
            }
        })
    }
    
    deinit {
        dzy_log("销毁")
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    
    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
            nil)
//        guard let imageData = image.pngData() else {return}
//        var identifier: String = ""
//        PHPhotoLibrary.shared().performChanges({
//            let request = PHAssetCreationRequest.forAsset()
//            request.addResource(with: .photo, data: imageData, options: nil)
//            if let idf = request.placeholderForCreatedAsset?.localIdentifier {
//                identifier = idf
//            }
//        }) { (result, error) in
//            if result {
//
//            }
//        }
    }
    
    private func saveSuccessAction(_ image: UIImage) {
        (0..<sIndexs.count).forEach { (index) in
            if sIndexs[index] != -1 {
                sIndexs[index] += 1
            }
        }
        sIndexs[selectedNum] = 1
        selectedNum += 1
//        caches.setObject(image, forKey: NSString(string: identifier)
        select.insert(selectedNum, at: 0)
        getPhotoAlbums(true, initCaches: false)
    }
    
    //    MARK: - 取消
    @objc private func cancelAction() {
        dismiss(animated: true, completion: nil)
    }
    
    //    MARK: - 返回
    @objc private func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - 判断权限
    private func checkAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .denied:
            // 用户拒绝,提示开启
            gotoSettingsAction()
        case .notDetermined:
            // 尚未请求,立即请求
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                if status == .authorized {
                    self.getPhotoAlbums(true)
                }else {
                    self.gotoSettingsAction()
                }
            })
        case .restricted:
            // 应用程序无权访问
            gotoSettingsAction()
        case .authorized:
            // 用户已授权
            getPhotoAlbums()
        @unknown default:
            break
        }
    }
    
    //    MARK: - 前往设置界面
    private func gotoSettingsAction() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "提示", message: "请前往设置应用中开启对应的访问权限", preferredStyle: .alert)
            let action = UIAlertAction(title: "是", style: .default) { [weak self] (_) in
                alert.dismiss(animated: true, completion: nil)
                self?.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //    MARK: - 获取所有相册
    public func getPhotoAlbums(_ ifReload: Bool = false, initCaches: Bool = true) {
        //创建一个PHFetchOptions对象检索照片
        let options = PHFetchOptions()
        //通过创建时间来检索
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //通过数据类型来检索
        options.predicate = NSPredicate(format: "mediaType in %@", [PHAssetMediaType.image.rawValue])
        //找到所有相片
        photos = PHAsset.fetchAssets(with: options)
        if initCaches {
            select = [Int](repeating: -1, count: photos?.count ?? 0)
        }
        
        if ifReload {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    //    MARK: - 多选时的确认操作
    @objc public func severalSureAction(_ btn: UIButton) {
        guard let photos = photos, photos.count > 0 else {return}
        btn.isUserInteractionEnabled = false
        delegate?.selectedFinshAndBeginDownload(self)
        let group = DispatchGroup()
        // 获取 Size
        let sizeHandler: (PHAsset) -> CGSize = { photo in
            let w = photo.pixelWidth
            let h = photo.pixelHeight
            if w <= h {
                let height = CGFloat(min(PickerConfig.maxSize, h))
                let width = height / CGFloat(h) * CGFloat(w)
                return CGSize(width: width, height: height)
            }else {
                let width = CGFloat(min(PickerConfig.maxSize, w))
                let height = width / CGFloat(w) * CGFloat(h)
                return CGSize(width: width, height: height)
            }
        }
        
        // 循环异步请求
        let indexs = sIndexs.filter({$0 != -1})
        var imgs = [UIImage](repeating: UIImage(), count: indexs.count)
        let IDKEY = "PHImageResultRequestIDKey"
        // Int 为照片的 Key， Double 为进度
        var progressDic: [Int : Double] = [:]
        
        func updateProgress() {
            let max = Double(indexs.count)
            var current: Double = 0
            progressDic.forEach({
                current += $1
            })
            DispatchQueue.main.async {
                let value = (current / max) * 100.0
                let str = String(format: "%.0lf", value)
                self.hudAndTextView.updateMsg("\(str)/100")
            }
        }
        
        let handler: PHAssetImageProgressHandler = { (value, error, point, info) in
            if let rId = info?[IDKEY] as? Int {
                progressDic[rId] = value
                updateProgress()
            }
        }
        
        hudAndTextView.show(view)
        hudAndTextView.updateMsg("0/100")
        for (index, value) in indexs.enumerated() {
            let i = value - 1
            if i < photos.count {
                let photo = photos[i]
                group.enter()
                let options = PickerConfig.asynOption
                options.isNetworkAccessAllowed = true
                options.progressHandler = handler
                let manager = PHImageManager.default()
                manager.requestImage(
                    for: photo,
                    targetSize: sizeHandler(photo),
                    contentMode: .aspectFit,
                    options: options
                ) { (image, info) in
                    if let image = image,
                        let rId = info?[IDKEY] as? Int
                    {
                        imgs[index] = image
                        progressDic[rId] = 1
                        updateProgress()
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.hudAndTextView.disMiss()
            self.delegate?.imagePicker(self, getImages: imgs)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //    MARK: - 刷新缓存过的项目
    func updateCachedAssets() {
        guard let collectionView = collectionView else {return}
        if !isViewLoaded || view.window == nil {return}
        // 预热区域 preheatRect 是 可见区域 visibleRect 的两倍高
        let visibleRect = CGRect(
            x: 0,
            y: collectionView.contentOffset.y,
            width: collectionView.bounds.size.width,
            height: collectionView.bounds.size.height
        )
        let preheatRect = visibleRect.insetBy(
            dx: 0, dy: -0.5 * visibleRect.size.height
        )
        // 只有当可见区域与最后一个预热区域显著不同时才更新
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > view.bounds.size.height / 3.0 {
            computeDifference(previousPreheatRect, and: preheatRect, removeHandler: { (removedRect) in
                self.imageManagerStopCachingImages(removedRect)
            }) { (addedRect) in
                self.imageManagerStartCachingImages(addedRect)
            }
            previousPreheatRect = preheatRect
        }
    }
    
    //    MARK: - 计算缓存区域
    func computeDifference(_ oldRect: CGRect, and newRect: CGRect, removeHandler: (CGRect) -> (), addHandler: (CGRect) -> ())
    {
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            //添加 向下滑动时 newRect 除去与 oldRect 相交部分的区域（即：屏幕外底部的预热区域）
            if (newMaxY > oldMaxY) {
                let rectToAdd = CGRect(
                    x: newRect.origin.x,
                    y: oldMaxY,
                    width: newRect.size.width,
                    height: (newMaxY - oldMaxY)
                )
                addHandler(rectToAdd)
            }
            //添加 向上滑动时 newRect 除去与 oldRect 相交部分的区域（即：屏幕外顶部的预热区域）
            if (oldMinY > newMinY) {
                let rectToAdd = CGRect(
                    x: newRect.origin.x,
                    y: newMinY,
                    width: newRect.size.width,
                    height: (oldMinY - newMinY)
                )
                addHandler(rectToAdd)
            }
            //移除 向上滑动时 oldRect 除去与 newRect 相交部分的区域（即：屏幕外底部的预热区域）
            if (newMaxY < oldMaxY) {
                let rectToRemove = CGRect(
                    x: newRect.origin.x,
                    y: newMaxY,
                    width: newRect.size.width,
                    height: (oldMaxY - newMaxY)
                )
                removeHandler(rectToRemove)
            }
            //移除 向下滑动时 oldRect 除去与 newRect 相交部分的区域（即：屏幕外顶部的预热区域）
            if (oldMinY < newMinY) {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removeHandler(rectToRemove)
            }
        }else {
            addHandler(newRect)
            removeHandler(oldRect)
        }
    }
    
    //    MARK: - 开始缓存，移除缓存
    func indexPathsForElements(_ rect: CGRect) -> [PHAsset] {
        guard let collectionView = collectionView,
            let fetchResult = photos
        else {return []}
        return collectionView.collectionViewLayout
            .layoutAttributesForElements(in: rect)?
            .compactMap({ (layout) -> PHAsset? in
                let indexPath = layout.indexPath
                if indexPath.item == 0 {
                    return nil
                }else {
                    return fetchResult.object(at: indexPath.item - 1)
                }
            }) ?? []
    }
    
    func imageManagerStartCachingImages(_ rect: CGRect) {
        let addAssets = indexPathsForElements(rect)
        cacheManager.startCachingImages(
            for: addAssets,
            targetSize: PickerConfig.smallSize,
            contentMode: .aspectFill,
            options: PickerConfig.asynOption
        )
    }
    
    func imageManagerStopCachingImages(_ rect: CGRect) {
        let removeAssets = indexPathsForElements(rect)
        cacheManager.stopCachingImages(
            for: removeAssets,
            targetSize: PickerConfig.smallSize,
            contentMode: .aspectFill,
            options: PickerConfig.asynOption
        )
    }
    
    //    MARK: - UI
    private func setNaviItem() {
        customBackBtn().addTarget(
            self,
            action: #selector(backAction),
            for: .touchUpInside
        )
        
        let x: CGFloat = 51.0/255.0
        let right = UIButton(type: .custom)
        right.setTitle("取消", for: .normal)
        right.setTitleColor(
            UIColor(red: x, green: x, blue: x, alpha: 1),
            for: .normal
        )
        right.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        right.addTarget(
            self,
            action: #selector(cancelAction),
            for: .touchUpInside
        )
        right.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let rightBtn = UIBarButtonItem(customView: right)
        navigationItem.rightBarButtonItem = rightBtn
    }
    
    private func setViewControllers() {
        if navigationController?.viewControllers.count == 1 {
            let vc = DzyAlbumsVC()
            var vcs = navigationController?.viewControllers
            vcs?.insert(vc, at: 0)
            navigationController?.setViewControllers(vcs!, animated: true)
        }
    }
    
    private func setCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        self.collectionView = collectionView
        collectionView.register(ImagePickCell.self, forCellWithReuseIdentifier: "ImagePickCell")
        let kind = UICollectionView.elementKindSectionFooter
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: kind,
            withReuseIdentifier: "footer"
        )
        
        collectionView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.top.equalTo(topLayoutGuide.snp.bottom)
                make.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            make.left.right.equalTo(0)
        }
    }
    
    // 如果是多选，下面要多个确认的按钮
    private func setSureBtn() {
        if type.isSeveral {
            view.addSubview(sureBtn)
            
            sureBtn.snp.makeConstraints { (make) in
                if #available(iOS 11.0, *) {
                    make.bottom
                        .equalTo(view.safeAreaLayoutGuide.snp.bottom)
                        .offset(-10)
                } else {
                    make.bottom
                        .equalTo(bottomLayoutGuide.snp.top)
                        .offset(-10)
                }
                make.width.equalTo(100.0)
                make.height.equalTo(40.0)
                make.centerX.equalTo(view)
            }
        }
    }
    
    //    MARK: - 懒加载
    private lazy var sureBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = PickerConfig.MainColor
        btn.setTitle("选择(0)", for: .normal)
        btn.addTarget(
            self,
            action: #selector(severalSureAction(_:)),
            for: .touchUpInside
        )
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 20.0
        btn.layer.masksToBounds = true
        return btn
    }()
    
    private lazy var signlHudView = ProgressView(.hud)
    
    private lazy var hudAndTextView = ProgressView(.hudAndText)
}

extension DzyImagePickerVC:
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (photos?.count ?? 0) + 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickCell", for: indexPath) as? ImagePickCell
        if case .origin(.several) = type {
            cell?.delegate = self
            cell?.index = indexPath.row
        }
        cell?.imgView?.image = nil
        if indexPath.item == 0 {
            cell?.camearStyle()
        }else {
            let row = indexPath.row - 1
            let photo = photos?.object(at: row)
            let idf = NSString(string: photo?.localIdentifier ?? "")
            let cache = caches.object(forKey: NSString(string: idf))
            if row < select.count {
                cell?.updateViews(photo, cache: cache, selectNum: select[row], complete: { [weak self] (image) in
                    if let image = image {
                        self?.caches.setObject(image, forKey: idf)
                    }
                })
            }
        }
        return cell!
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 { // 相机
            if type.isSeveral && selectedNum >= type.maxCount {
                return
            }
            let vc = DzyCameraVC()
            navigationController?.pushViewController(vc, animated: true)
            // 防止点相机的同时点了一张别的图，会卡住
            collectionView.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                collectionView.isUserInteractionEnabled = true
            }
            return
        }
        guard let photo = photos?.object(at: indexPath.row - 1) else {return}
        switch type {
        case .edit(let editType):
            let vc = DzyImageBrowserVC(photo, type: editType)
            navigationController?.pushViewController(vc, animated: true)
        case .origin(let originType):
            let handler: (UIImage?, [AnyHashable : Any]?) -> (Void) = { (image, _) in
                DispatchQueue.main.async { [unowned self] in
                    self.signlHudView.disMiss()
                    if let image = image {
                        switch originType {
                        case .single:
                            self.dismiss(animated: true, completion: nil)
                            PickerManager.default.delegate?.imagePicker(self, getOriginImage: image)
                        case .several:
                            let vc = DzyImageShowVC(image)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
            signlHudView.show(self.view)
            let options = PickerConfig.asynOption
            options.isNetworkAccessAllowed = true
            let manager = PHImageManager.default()
            manager.requestImage(for: photo, targetSize: CGSize(width: photo.pixelWidth, height: photo.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: handler)
        }
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let screenW = UIScreen.main.bounds.size.width
        let x = (screenW - 6.0) / 4.0
        return CGSize(width: x, height: x)
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 2.0
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 2.0
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        let width = UIScreen.main.bounds.size.width
        return type.isSeveral ? CGSize(width: width, height: 60.0) : .zero
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "footer",
            for: indexPath
        )
        footer.backgroundColor = .white
        return footer
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

extension DzyImagePickerVC: ImagePickCellDelegate {
    open func pickCell(_ pickCell: ImagePickCell, didSelectedBtn btn: UIButton) {
        let row = pickCell.index - 1
        func updateOne() {
            let selectNum = select[row] // caches[row]
            let indexPath = IndexPath(row: pickCell.index, section: 0)
            if let cell = collectionView?.cellForItem(at: indexPath) as? ImagePickCell {
                cell.updateSelectedType(selectNum)
            }
        }
        if select[row] == -1 { // 选中
            if selectedNum >= type.maxCount {
                return
            }
            sIndexs[selectedNum] = pickCell.index
            selectedNum += 1
            select[row] = selectedNum
            updateOne()
        }else { // 取消选中
            // 之前选择的第几张照片
            let old = select[row]
            // 将照片对应的 index 移除（后面照片对应的 index 就会自动往前）
            sIndexs.remove(at: old - 1)
            // 在最后面补充一个
            sIndexs.append(-1)
            // 选中图片减少一
            selectedNum -= 1
            // 取消选中状态
            select[row] = -1
            // 如果点击的正好是最后一张
            if old == selectedNum + 1 {
                updateOne()
            }else {// 如果点击的是中间的某张
                (old - 1..<sIndexs.count).forEach { (i) in
                    // 获取 cache 对应的 index
                    let index = sIndexs[i]
                    if index != -1 {
                        select[index - 1] -= 1
                    }
                }
                collectionView?.reloadData()
            }
        }
    }
}

extension DzyImagePickerVC {
    @objc open func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            self.saveSuccessAction(image)
        }
    }
}
