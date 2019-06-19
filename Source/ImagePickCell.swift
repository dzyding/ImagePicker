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
    
    private var numLB: UILabel? {
        return selectView.viewWithTag(9) as? UILabel
    }
    
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
        
        contentView.addSubview(selectView)
        selectView.isHidden = true
        
        imgView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView).inset(UIEdgeInsets.zero)
        }
        
        selectView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView).inset(UIEdgeInsets.zero)
        }
    }
    
    public func camearStyle() {
        selectView.isHidden = true
        imgView?.contentMode = .scaleAspectFit
        imgView?.image = PickerManager.default.loadImageFromBunlde("photo")
    }
    
    public func updateViews(_ photo: PHAsset?, cache: (UIImage?, Int), complete: ((UIImage?) -> ())?) {
        imgView?.contentMode = .scaleToFill
        selectView.isHidden = cache.1 == -1
        numLB?.text = "\(cache.1)"
        
        if let cache = cache.0 {
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
    
    //    MARK: - 懒加载
    private lazy var selectView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.blue.cgColor
        view.layer.borderWidth = 3
        
        let numLB = UILabel()
        numLB.textColor = .white
        numLB.textAlignment = .center
        numLB.backgroundColor = .blue
        numLB.font = UIFont.systemFont(ofSize: 12)
        numLB.tag = 9
        view.addSubview(numLB)
        
        numLB.snp.makeConstraints({ (make) in
            make.top.right.equalTo(view)
            make.height.width.equalTo(20)
        })
        return view
    }()
}
