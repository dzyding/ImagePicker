//
//  AlbumsCell.swift
//  190119_DKImagePickerController
//
//  Created by edz on 2019/3/29.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import SnapKit

class AlbumsCell: UITableViewCell {
    
    weak var imgView: UIImageView?
    
    weak var nameLB: UILabel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        basicStep()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func basicStep() {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        contentView.addSubview(imgView)
        self.imgView = imgView
        
        let nameLB = UILabel()
        nameLB.textColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1)
        nameLB.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(nameLB)
        self.nameLB = nameLB
        
        imgView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(10)
            make.width.equalTo(imgView.snp.height)
        }
        
        nameLB.snp.makeConstraints { (make) in
            make.left.equalTo(imgView.snp.right).offset(10)
            make.centerY.equalTo(imgView)
        }
    }
}
