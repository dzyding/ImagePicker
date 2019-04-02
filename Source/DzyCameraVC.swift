//
//  DzyCameraVC.swift
//  Example
//
//  Created by edz on 2019/4/1.
//  Copyright © 2019 dzy. All rights reserved.
//

import UIKit
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
    
    var device = AVCaptureDevice.default(for: .video)

    override func viewDidLoad() {
        super.viewDidLoad()
        basicStep()
    }
    
    func basicStep() {
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
                
                var dic: [String : Any] = [:]
                if #available(iOS 11.0, *) {
                    //AVVideoCompressionPropertiesKey 设置压缩属性的
                    dic = [AVVideoCodecKey : AVVideoCodecType.jpeg]
                } else {
                    dic = [AVVideoCodecKey : AVVideoCodecJPEG]
                }
                if #available(iOS 10.0, *) {
                    let output = AVCapturePhotoOutput()
                    
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        // 支持的
                        let avai = output.availablePhotoCodecTypes
                        print(avai)
                        let settings = AVCapturePhotoSettings(format: dic)
                        output.capturePhoto(with: settings, delegate: self)
                    }
                }else {
                    let output = AVCaptureStillImageOutput()
                    output.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                        
                        guard let connection = output.connection(with: .video) else {return}
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
                session.startRunning()
            }catch{
                print(error)
            }
        }
    }
}

extension DzyCameraVC: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error, contextInfo: UnsafeRawPointer) {
        print("成功")
    }
}
