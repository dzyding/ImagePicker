//
//  DzyCameraVC.swift
//  Example
//
//  Created by edz on 2019/4/1.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

class DzyCameraVC: UIViewController {
    
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    lazy var session: AVCaptureSession = {
        let s = AVCaptureSession()
        if s.canSetSessionPreset(.hd4K3840x2160) {
            s.sessionPreset = .hd4K3840x2160
        }else if s.canSetSessionPreset(.hd1920x1080) {
            s.sessionPreset = .hd1920x1080
        }else if s.canSetSessionPreset(.hd1280x720) {
            s.sessionPreset = .hd1280x720
        }else {
            s.sessionPreset = .high
        }
        return s
    }()
    
    private var device = AVCaptureDevice.default(for: .video)
    
    private weak var output: AVCaptureOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setCamera()
    }
    
    //    MARK: - 拍照的设置
    func setCamera() {
        if let device = device {
            do {
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
                
                let deviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(deviceInput)
                {
                    session.addInput(deviceInput)
                }
                
                
                if #available(iOS 10.0, *) {
                    let output = AVCapturePhotoOutput()
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        self.output = output
                    }
                }else {
                    let output = AVCaptureStillImageOutput()
                    output.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        self.output = output
                    }
                }
                session.startRunning()
            }catch{
                print(error)
            }
        }
    }
    
    //    MARK: - 拍照
    @objc func takePhoto() {
        if #available(iOS 10.0, *) {
            if let output = output as? AVCapturePhotoOutput {
                let settings: AVCapturePhotoSettings = {
                    var dic: [String : Any] = [:]
                    if #available(iOS 11.0, *) {
                        dic = [AVVideoCodecKey : AVVideoCodecType.jpeg]
                    } else {
                        dic = [AVVideoCodecKey : AVVideoCodecJPEG]
                    }
                    return AVCapturePhotoSettings(format: dic)
                }()
                output.capturePhoto(with: settings, delegate: self)
            }
        }else {
            if let output = output as? AVCaptureStillImageOutput,
                let connection = output.connection(with: .video)
            {
                connection.videoOrientation = .portrait
                output.captureStillImageAsynchronously(from: connection) { (buffer, error) in
                    if let buffer = buffer,
                        let jpegData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                        let image = UIImage(data: jpegData)
                    {
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            }
        }
    }
    
    //    MARK: - 界面设置
    private func setUI() {
        let btn = TakePhotoBtn(type: .custom)
        btn.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(btn)
        
        btn.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.equalTo(view)
            make.bottom.equalTo(-50)
        }
    }
}

extension DzyCameraVC: AVCapturePhotoCaptureDelegate {

    open func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc open func image(_ image: UIImage, didFinishSavingWithError error: Error, contextInfo: UnsafeRawPointer) {
        print("成功")
    }
}
