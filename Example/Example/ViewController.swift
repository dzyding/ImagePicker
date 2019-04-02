//
//  ViewController.swift
//  Example
//
//  Created by edz on 2019/4/2.
//  Copyright © 2019 灰s. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func rectangleAction(_ sender: Any) {
        let vc = DzyImagePickerVC()
        vc.cropScale = 0.66
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    @IBAction func squareAction(_ sender: Any) {
        let vc = DzyImagePickerVC()
        vc.delegate = self
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
    
    @IBAction func originAction(_ sender: Any) {
        let vc = DzyImagePickerVC()
        vc.delegate = self
        vc.ifCrop = false
        let navi = UINavigationController(rootViewController: vc)
        present(navi, animated: true, completion: nil)
    }
}

extension ViewController: DzyImagePickerVCDelegate {
    
    func imagePicker(_ picker: DzyImagePickerVC?, getCropImage image: UIImage) {
        imgView.image = image
    }
    
    func imagePicker(_ picker: DzyImagePickerVC?, getOriginImage image: UIImage) {
        imgView.image = image
    }
    
}
