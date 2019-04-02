//
//  ImagePickCell.swift
//  Example
//
//  Created by edz on 2019/3/15.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import SnapKit
import Photos

class ImagePickCell: UICollectionViewCell {
    
    weak var imgView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        basicStep()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func basicStep() {
        let imgView = UIImageView()
        contentView.addSubview(imgView)
        self.imgView = imgView
        
        imgView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView).inset(UIEdgeInsets.zero)
        }
    }
    
    public func updateViews(_ photo: PHAsset?, cache: UIImage?, complete: ((UIImage?) -> ())?) {
        imgView?.contentMode = .scaleToFill
        if let cache = cache {
            imgView?.image = cache
            return
        }
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        if let photo = photo {
            let manager = PHImageManager.default()
            manager.requestImage(for: photo, targetSize: CGSize(width: 500.0, height: 500.0), contentMode: .aspectFill, options: option) { (image, info) in
                DispatchQueue.main.async {
                    self.imgView?.image = image
                    complete?(image)
                }
            }
        }
    }
}
