//
//  DzyImagePickerVC.swift
//  190119_DKImagePickerController
//
//  Created by edz on 2019/1/19.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import Photos
import SnapKit

class DzyImagePickerVC: UIViewController {
    /// 高 / 宽
    var cropScale: CGFloat = 1
    
    var handler: ((UIImage?) -> ())?
    
    var album: String?
 
    var photos: PHFetchResult<PHAsset>?
    
    private weak var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.alpha = 0.7
        
        setNaviItem()
        setViewControllers()
        setCollectionView()
        
        if let _ = photos {
            navigationItem.title = album
            collectionView?.reloadData()
        }else {
            navigationItem.title = "全部照片"
            checkAuthorization()
        }
    }
    
    //    MARK: - 取消
    @objc func cancelAction() {
        dismiss(animated: true, completion: nil)
    }
    
    //    MARK: - 返回
    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - 判断权限
    func checkAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .denied:
        // 用户拒绝,提示开启
            let alert = UIAlertController(title: "请前往设置界面开启访问权限", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "是", style: .default) { (_) in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            // 尚未请求,立即请求
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                if status == .authorized {
                    self.getPhotoAlbums()
                }
            })
        case .restricted:
            // 应用程序无权访问
            print("restricted")
        case .authorized:
            // 用户已授权
            getPhotoAlbums()
        }
    }
    
    //    MARK: - 获取所有相册
    func getPhotoAlbums() {
        //创建一个PHFetchOptions对象检索照片
        let options = PHFetchOptions()
        //通过创建时间来检索
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //通过数据类型来检索
        options.predicate = NSPredicate(format: "mediaType in %@", [PHAssetMediaType.image.rawValue])
        //找到所有相片
        photos = PHAsset.fetchAssets(with: options)
        self.collectionView?.reloadData()
    }
    
    func setNaviItem() {
        navigationItem.hidesBackButton = true
        
        let right = UIButton(type: .custom)
        right.setTitle("取消", for: .normal)
        right.setTitleColor(UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1), for: .normal)
        right.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        right.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        right.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let rightBtn = UIBarButtonItem(customView: right)
        navigationItem.rightBarButtonItem = rightBtn
        
        let left = UIButton(type: .custom)
        left.setImage(UIImage(named: "dzy_back"), for: .normal)
        left.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        left.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let leftBtn = UIBarButtonItem(customView: left)
        navigationItem.leftBarButtonItem = leftBtn
    }
    
    func setViewControllers() {
        if navigationController?.viewControllers.count == 1 {
            let vc = DzyAlbumsVC()
            vc.cropScale = cropScale
            vc.handler = handler
            var vcs = navigationController?.viewControllers
            vcs?.insert(vc, at: 0)
            navigationController?.setViewControllers(vcs!, animated: true)
        }
    }
    
    func setCollectionView() {
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickCell", for: indexPath) as? ImagePickCell
        cell?.updateViews(photos?.object(at: indexPath.row))
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let photo = photos?.object(at: indexPath.row) {
            var type: CropType = .square
            if cropScale != 1 {
                type = .rectangle(cropScale)
            }
            let vc = DzyImageBrowserVC(photo, type: type)
            vc.pickerVC = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
