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
    /// 展示层
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    /// 当前使用设备
    private var device = AVCaptureDevice.default(for: .video)
    
    private lazy var session = AVCaptureSession()
    /// 输出模式
    private weak var output: AVCaptureOutput?
    
    // 隐藏状态栏
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setNeedsStatusBarAppearanceUpdate()
        
        setUI()
        setCamera()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    //    MARK: - 拍照的设置
    private func setCamera() {
        if let device = device {
            do {
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
                
                updatePresetAction(device)
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
    @objc open func takePhotoAction() {
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
    
    //    MARK: - 取消
    @objc open func cancelAction() {
        navigationController?.popViewController(animated: true)
    }
    
    //    MARK: - 旋转相机
    @objc open func rotateAction() {
        func getCamera(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            var arr: [AVCaptureDevice.DeviceType] = []
            if #available(iOS 11.1, *) {
                arr = [.builtInTrueDepthCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera]
            }else if #available(iOS 10.2, *) {
                arr = [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera]
            }else {
                arr = [.builtInTelephotoCamera, .builtInWideAngleCamera]
            }
            // 从高到低
            for type in arr {
                if let device = AVCaptureDevice.default(type, for: .video, position: position) {
                    return device
                }
            }
            return nil
        }
        if let device = device {
            var newDevice: AVCaptureDevice?
            if device.position == .back {
                newDevice = getCamera(.front)
            }else {
                newDevice = getCamera(.back)
            }
            if let newDevice = newDevice,
                let oldInput = session.inputs.first
            {
                do {
                    self.device = newDevice
                    let newInput = try AVCaptureDeviceInput(device: newDevice)
                    session.beginConfiguration()
                    session.removeInput(oldInput)
                    updatePresetAction(newDevice)
                    session.addInput(newInput)
                    session.commitConfiguration()
                }catch {
                    print(error)
                }
            }
        }
    }
    
    //    MARK: - 预更改分辨率
    func updatePresetAction(_ device: AVCaptureDevice) {
        if session.canSetSessionPreset(.hd4K3840x2160) && device.supportsSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        }else if session.canSetSessionPreset(.hd1920x1080) && device.supportsSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }else if session.canSetSessionPreset(.hd1280x720) && device.supportsSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }else {
            session.sessionPreset = .high
        }
    }
    
    //    MARK: - 对焦
    
    //    MARK: - 界面设置
    private func setUI() {
        let takePhotoBtn = TakePhotoBtn(type: .custom)
        takePhotoBtn.addTarget(self, action: #selector(takePhotoAction), for: .touchUpInside)
        view.addSubview(takePhotoBtn)
        
        let cancelBtn = CancelBtn(type: .custom)
        cancelBtn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
        let rotate = PickerManager.default.loadImageFromBunlde("rotate")
        let rotateBtn = UIButton(type: .custom)
        rotateBtn.setImage(rotate, for: .normal)
        rotateBtn.addTarget(self, action: #selector(rotateAction), for: .touchUpInside)
        view.addSubview(rotateBtn)
        
        takePhotoBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(80)
            make.centerX.equalTo(view)
            make.bottom.equalTo(-50)
        }
        
        cancelBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(70)
            make.centerY.equalTo(takePhotoBtn)
            make.right.equalTo(takePhotoBtn.snp.left).offset(-30)
        }
        
        rotateBtn.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.width.height.equalTo(50)
        }
    }
}

extension DzyCameraVC: AVCapturePhotoCaptureDelegate {

    @available(iOS 11.0, *)
    open func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    // iOS 10.0
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let buffer = photoSampleBuffer,
            let jpegData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
            let image = UIImage(data: jpegData)
        {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc open func image(_ image: UIImage, didFinishSavingWithError error: Error, contextInfo: UnsafeRawPointer) {
        print("成功")
    }
}
