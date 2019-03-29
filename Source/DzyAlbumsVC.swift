//
//  DzyAlbumsVC.swift
//  190119_DKImagePickerController
//
//  Created by edz on 2019/3/29.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import Photos
import SnapKit

class DzyAlbumsVC: UIViewController {
    /// 高 / 宽
    var cropScale: CGFloat = 1
    
    var handler: ((UIImage?) -> ())?
    
    // 所有相册
    private var albums = [[String: PHFetchResult<PHAsset>]]()
    
    private weak var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "全部相册"
        basicStep()
        loadAlbums()
    }
    
    // 获取所有相册 
    func loadAlbums() {
        //创建一个PHFetchOptions对象检索照片
        let options = PHFetchOptions()
        //通过创建时间来检索
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //通过数据类型来检索
        options.predicate = NSPredicate(format: "mediaType in %@", [PHAssetMediaType.image.rawValue])
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        //获取用户创建的相册
        let userAlbums = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        //获取智能相册
        let smartAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        
        userAlbums.enumerateObjects(options: .concurrent) { (collection, index, stop) in
            if let assetCollection = collection as? PHAssetCollection,
                let key = assetCollection.localizedTitle
            {
                let result = PHAsset.fetchAssets(in: assetCollection, options: options)
                if result.count > 0 {
                    self.albums.append([key : result])
                }
            }
        }
        
        smartAlbum.enumerateObjects(options: .concurrent) { (collection, index, stop) in
            if let key = collection.localizedTitle {
                let result = PHAsset.fetchAssets(in: collection, options: options)
                if result.count > 0 {
                    self.albums.append([(key == "All Photos" ? "全部照片" : key) : result])
                }
            }
        }
        tableView?.reloadData()
    }
    
    func basicStep() {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        view.addSubview(tableView)
        self.tableView = tableView
        
        tableView.register(AlbumsCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.snp.makeConstraints { (make) in
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

extension DzyAlbumsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = albums[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! AlbumsCell
        cell.nameLB?.text = album.keys.first
        if let image = album.values.first?.firstObject {
            PHImageManager.default().requestImage(for: image, targetSize: CGSize(width: 180, height: 180), contentMode: .aspectFit, options: nil) { (img, info) in
                cell.imgView?.image = img
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = albums[indexPath.row]
        let vc = DzyImagePickerVC()
        vc.album = album.keys.first
        vc.photos = album.values.first
        vc.cropScale = cropScale
        vc.handler = handler
        navigationController?.pushViewController(vc, animated: true)
    }
}
