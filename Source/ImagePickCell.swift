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

protocol ImagePickCellDelegate: class {
    func pickCell(_ pickCell: ImagePickCell, didSelectedBtn btn: UIButton)
}

open class ImagePickCell: UICollectionViewCell {
    
    weak var delegate: ImagePickCellDelegate?
    
    weak var imgView: UIImageView?
    
    var idf: String?
    
    var index: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        basicStep()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func basicStep() {
        let imgView = UIImageView()
        contentView.addSubview(imgView)
        self.imgView = imgView
        
        contentView.addSubview(numBtn)
        numBtn.isHidden = true
        
        imgView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView).inset(UIEdgeInsets.zero)
        }
        
        numBtn.snp.makeConstraints { (make) in
            make.top.right.equalTo(0)
            make.width.height.equalTo(30)
        }
    }
    
    //    MARK: - 选中
    @objc func selectedAction(_ btn: UIButton) {
        delegate?.pickCell(self, didSelectedBtn: btn)
    }
    
    //    MARK: - 相机 cell 的样式
    public func camearStyle() {
        numBtn.isHidden = true
        imgView?.contentMode = .scaleAspectFit
        imgView?.image = PickerManager.default.loadImageFromBunlde("photo")
    }
    
    //    MARK: - 更新选中状态
    public func updateSelectedType(_ selectNum: Int) {
        let type = PickerManager.default.type
        switch type {
        case .origin(.several):
            let num = selectNum
            numBtn.isHidden = false
            numBtn.setTitle(num == -1 ? nil : "\(num)", for: .normal)
            numBtn.isSelected = num != -1
        default:
            numBtn.isHidden = true
        }
    }
    
    //    MARK: - 更新视图
    public func updateViews(_ photo: PHAsset?, cache: UIImage?, selectNum: Int, complete: ((UIImage?) -> ())?) {
        updateSelectedType(selectNum)
        imgView?.contentMode = .scaleToFill
        idf = photo?.localIdentifier
        if let cache = cache {
            imgView?.image = cache
            return
        }
        let option = PHImageRequestOptions()
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = false
        
        guard let photo = photo else {return}
        let manager = PHImageManager.default()
        manager.requestImage(for: photo, targetSize: PickerManager.smallSize, contentMode: .aspectFill, options: option) { (image, info) in
            complete?(image)
            DispatchQueue.main.async {
                if self.idf == photo.localIdentifier {
                    self.imgView?.image = image
                }
            }
        }
    }
    
    //    MARK: - 懒加载
    private lazy var numBtn: UIButton = {
        let normalImg = PickerManager.default
            .loadImageFromBunlde("img_selected_no")
        let selectedImg = PickerManager.default
            .loadImageFromBunlde("img_selected")
        
        let numBtn = UIButton(type: .custom)
        numBtn.setTitleColor(.white, for: .normal)
        numBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        numBtn.setBackgroundImage(normalImg, for: .normal)
        numBtn.setBackgroundImage(selectedImg, for: .selected)
        numBtn.addTarget(
            self, action: #selector(selectedAction(_:)), for: .touchUpInside
        )
        numBtn.tag = 9
        return numBtn
    }()
}
