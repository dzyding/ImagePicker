//
//  ViewController.swift
//  Example
//
//  Created by edz on 2019/4/2.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func rectangleAction(_ sender: Any) {
        let vc = DzyImagePickerVC(.edit(.rect(0.66)))
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    @IBAction func squareAction(_ sender: Any) {
        let vc = DzyImagePickerVC(.edit(.square))
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    @IBAction func originAction(_ sender: Any) {
        let vc = DzyImagePickerVC(.origin(.single))
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    @IBAction func severalAction(_ sender: UIButton) {
        let vc = DzyImagePickerVC(.origin(.several(9)))
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    private func addImgs(_ images: [UIImage]) {
        DispatchQueue.main.async {
            (0..<self.stackView.arrangedSubviews.count).forEach { (_) in
                self.stackView.arrangedSubviews.first?.removeFromSuperview()
            }
            images.forEach { (image) in
                let imgView = UIImageView(image: image)
                imgView.layer.masksToBounds = true
                imgView.contentMode = .scaleAspectFit
                imgView.snp.makeConstraints({ (make) in
                    make.width.equalTo(250)
                })
                self.stackView.addArrangedSubview(imgView)
            }
        }
    }
}

extension ViewController: DzyImagePickerVCDelegate {
    
    func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage) {
        addImgs([image])
    }
    
    func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage) {
        addImgs([image])
    }
    
    func selectedFinshAndBeginDownload(_ picker: DzyImagePickerVC?) {
        print("开始")
    }
    
    func imagePicker(_ picker: DzyImagePickerVC?, getImages imgs: [UIImage]) {
        print("结束")
        addImgs(imgs)
    }
}
