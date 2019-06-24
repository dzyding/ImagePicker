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
    /// 缓存/选中
    public var caches: [(UIImage?, Int)] = []
    /// 选中的数量
    public var selectedNum: Int = 0 {
        didSet {
            sureBtn.setTitle("选择(\(selectedNum))", for: .normal)
        }
    }
    /// 选中图片对应的 index (比如 sIndexs[1]，代表第二张图片对应的 index)
    public var sIndexs = [Int](repeating: -1, count: 20)
    
    public var album: String?
 
    public var photos: PHFetchResult<PHAsset>?
    
    private weak var collectionView: UICollectionView?
    
    private var observer: Any?
    
    init(_ type: DzyImagePickerType) {
        super.init(nibName: nil, bundle: nil)
        self.type = type
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.alpha = 0.5
        
        setNaviItem()
        setViewControllers()
        setCollectionView()
        setSureBtn()
        
        if photos != nil {
            navigationItem.title = album
            caches = [(UIImage?, Int)](repeating: (nil, -1), count: photos?.count ?? 0)
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
    
    
    private func saveImage(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (result, error) in
            if result {
                self.saveSuccessAction(image)
            }
        }
    }
    
    private func saveSuccessAction(_ image: UIImage) {
        (0..<sIndexs.count).forEach { (index) in
            if sIndexs[index] != -1 {
                sIndexs[index] += 1
            }
        }
        sIndexs[selectedNum] = 1
        selectedNum += 1
        caches.insert((image, selectedNum), at: 0)
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
            caches = [(UIImage?, Int)](repeating: (nil, -1), count: photos?.count ?? 0)
        }
        
        if ifReload {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    //    MARK: - 多选时的确认操作
    @objc public func severalSureAction() {
        guard let photos = photos, photos.count > 0 else {return}
        delegate?.selectedFinshAndBeginDownload(self)
        let group = DispatchGroup()
        
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        var imgs: [UIImage] = []
        let handler: (UIImage?, [AnyHashable : Any]?) -> (Void) = { (image, _) in
            if let image = image {
                imgs.append(image)
            }
            group.leave()
        }
        
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
        
        for pIndex in sIndexs {
            if pIndex == -1 {break}
            if pIndex < photos.count {
                let photo = photos[pIndex]
                group.enter()
                let manager = PHImageManager.default()
                manager.requestImage(
                    for: photo,
                    targetSize: sizeHandler(photo),
                    contentMode: .aspectFit,
                    options: option,
                    resultHandler: handler
                )
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.delegate?.imagePicker(self, getImages: imgs)
            self.dismiss(animated: true, completion: nil)
        }
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
            action: #selector(severalSureAction),
            for: .touchUpInside
        )
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 20.0
        btn.layer.masksToBounds = true
        return btn
    }()
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
        return cell!
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as? ImagePickCell
        cell?.imgView?.image = nil
        if indexPath.item == 0 {
            cell?.camearStyle()
        }else {
            let row = indexPath.row - 1
            let photo = photos?.object(at: row)
            let cache = caches[row]
            cell?.updateViews(photo, cache: cache, complete: { [weak self] (image) in
                self?.caches[row].0 = image
            })
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 { // 相机
            if type.isSeveral && selectedNum >= type.maxCount {
                return
            }
            let vc = DzyCameraVC()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        guard let photo = photos?.object(at: indexPath.row - 1) else {return}
        switch type {
        case .edit(let editType):
            let vc = DzyImageBrowserVC(photo, type: editType)
            navigationController?.pushViewController(vc, animated: true)
        case .origin(let originType):
            let option = PHImageRequestOptions()
            option.resizeMode = .exact
            option.deliveryMode = .highQualityFormat
            option.isSynchronous = true
            
            let handler: (UIImage?, [AnyHashable : Any]?) -> (Void) = { [unowned self] (image, _) in
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
            let manager = PHImageManager.default()
            manager.requestImage(for: photo, targetSize: CGSize(width: photo.pixelWidth, height: photo.pixelHeight), contentMode: .aspectFit, options: option, resultHandler: handler)
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
}

extension DzyImagePickerVC: ImagePickCellDelegate {
    open func pickCell(_ pickCell: ImagePickCell, didSelectedBtn btn: UIButton) {
        let row = pickCell.index - 1
        func updateOne() {
            let cache = caches[row]
            let indexPath = IndexPath(row: pickCell.index, section: 0)
            if let cell = collectionView?.cellForItem(at: indexPath) as? ImagePickCell {
                cell.updateSelectedType(cache)
            }
        }
        if caches[row].1 == -1 { // 选中
            if selectedNum >= type.maxCount {
                return
            }
            sIndexs[selectedNum] = pickCell.index
            selectedNum += 1
            caches[row].1 = selectedNum
            updateOne()
        }else { // 取消选中
            // 之前选择的第几张照片
            let old = caches[row].1
            // 将照片对应的 index 移除（后面照片对应的 index 就会自动往前）
            sIndexs.remove(at: old - 1)
            // 在最后面补充一个
            sIndexs.append(-1)
            // 选中图片减少一
            selectedNum -= 1
            // 取消选中状态
            caches[row].1 = -1
            // 如果点击的正好是最后一张
            if old == selectedNum + 1 {
                updateOne()
            }else {// 如果点击的是中间的某张
                (old - 1..<sIndexs.count).forEach { (i) in
                    // 获取 cache 对应的 index
                    let index = sIndexs[i]
                    if index != -1 {
                        caches[index - 1].1 -= 1
                    }
                }
                collectionView?.reloadData()
            }
        }
    }
}
