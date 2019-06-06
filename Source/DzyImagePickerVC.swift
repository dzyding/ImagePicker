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
        case single     // 单图
        case several    // 多个
    }
    
    public enum EditType {
        case square         //正方形
        case rect(CGFloat)  //长方形
    }
}

public class DzyImagePickerVC: UIViewController {
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
    
    /// 缓存
    public var caches: [UIImage?] = []
    
    public var album: String?
 
    public var photos: PHFetchResult<PHAsset>? {
        didSet {
            caches = [UIImage?](repeating: nil, count: photos?.count ?? 0)
        }
    }
    
    private weak var collectionView: UICollectionView?
    
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
        navigationController?.navigationBar.alpha = 0.7
        
        setNaviItem()
        setViewControllers()
        setCollectionView()
        
        if let _ = photos {
            navigationItem.title = album
        }else {
            navigationItem.title = "全部照片"
            checkAuthorization()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
    public func getPhotoAlbums(_ ifReload: Bool = false) {
        //创建一个PHFetchOptions对象检索照片
        let options = PHFetchOptions()
        //通过创建时间来检索
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //通过数据类型来检索
        options.predicate = NSPredicate(format: "mediaType in %@", [PHAssetMediaType.image.rawValue])
        //找到所有相片
        photos = PHAsset.fetchAssets(with: options)
        
        if ifReload {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    //    MARK: - 获取缩略图
    private func loadCompressionImg(_ photo: PHAsset?, item: Int) {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: item, section: 0)) as? ImagePickCell else {return}
        if let image = caches[item - 1] {
            cell.imgView?.image = image
            return
        }
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        option.deliveryMode = .fastFormat
        option.isSynchronous = false
        
        if let photo = photo {
            let manager = PHImageManager.default()
            manager.requestImage(for: photo, targetSize: CGSize(width: 500.0, height: 500.0), contentMode: .aspectFill, options: option) { [weak self] (image, info) in
                cell.imgView?.image = image
                self?.caches[item - 1] = image
            }
        }
    }
    
    //    MARK: - UI
    private func setNaviItem() {
        navigationItem.hidesBackButton = true
        
        let right = UIButton(type: .custom)
        right.setTitle("取消", for: .normal)
        right.setTitleColor(UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1), for: .normal)
        right.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        right.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        right.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let rightBtn = UIBarButtonItem(customView: right)
        navigationItem.rightBarButtonItem = rightBtn
        
        let image = PickerManager.default.loadImageFromBunlde("back")
        let left = UIButton(type: .custom)
        left.setImage(image, for: .normal)
        left.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        left.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let leftBtn = UIBarButtonItem(customView: left)
        navigationItem.leftBarButtonItem = leftBtn
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
        let screenW = UIScreen.main.bounds.size.width
        let x = (screenW - 6.0) / 4.0
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: x, height: x)
        layout.minimumInteritemSpacing = 2.0
        layout.minimumLineSpacing = 2.0
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        self.collectionView = collectionView
        collectionView.register(ImagePickCell.self, forCellWithReuseIdentifier: "ImagePickCell")
        
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
}

extension DzyImagePickerVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (photos?.count ?? 0) + 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickCell", for: indexPath) as? ImagePickCell
        return cell!
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as? ImagePickCell
        cell?.imgView?.image = nil
        if indexPath.item == 0 {
            cell?.imgView?.contentMode = .scaleAspectFit
            cell?.imgView?.image = PickerManager.default.loadImageFromBunlde("photo")
        }else {
            let row = indexPath.row - 1
            let photo = photos?.object(at: row)
            let cache = caches[row]
            cell?.updateViews(photo, cache: cache, complete: { [weak self] (image) in
                self?.caches[row] = image
            })
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 { // 相机
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
            switch originType {
            case .single:
                let option = PHImageRequestOptions()
                option.resizeMode = .exact
                option.deliveryMode = .highQualityFormat
                option.isSynchronous = true
                
                let manager = PHImageManager.default()
                manager.requestImage(for: photo, targetSize: CGSize(width: photo.pixelWidth, height: photo.pixelHeight), contentMode: .aspectFit, options: option) { (image, info) in
                    if let image = image {
                        self.dismiss(animated: true, completion: nil)
                        PickerManager.default.delegate?.imagePicker(self, getOriginImage: image)
                    }
                }
            case .several:
                print("123")
            }
        }
    }
}
