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
    
    // 对焦视图
    private lazy var focusView: FocusView = {
        let frame = CGRect(x: 0, y: 0, width: 150.0, height: 150.0)
        let focusV = FocusView(frame: frame)
        focusV.tag = 99
        return focusV
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setNeedsStatusBarAppearanceUpdate()
        
        setUI()
        setCamera()
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
    @objc open func takePhotoAction(_ btn: UIButton) {
        btn.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            btn.isUserInteractionEnabled = true
        }
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
                output.captureStillImageAsynchronously(from: connection) { [weak self] (buffer, error) in
                    if let buffer = buffer,
                        let jpegData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                        let image = UIImage(data: jpegData)
                    {
                        self?.saveAndNextAction(image)
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
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        if view.viewWithTag(99) != nil {
            return
        }
        let size = UIScreen.main.bounds.size
        let point = tap.location(in: view)
        let x = point.x / size.width
        let y = point.y / size.height
        showFocusView(point)
        focusAction(CGPoint(x: x, y: y))
    }
    
    private func focusAction(_ point: CGPoint) {
        do {
            try device?.lockForConfiguration()
            // 每次对焦 还原
            device?.setExposureTargetBias(0, completionHandler: nil)
            
            if device?.isFocusPointOfInterestSupported == true,
                device?.isFocusModeSupported(.autoFocus) == true
            {
                device?.focusPointOfInterest = point
                device?.focusMode = .autoFocus
            }
            
            if device?.isExposurePointOfInterestSupported == true,
                device?.isExposureModeSupported(.autoExpose) == true
            {
                device?.exposurePointOfInterest = point
                device?.exposureMode = .autoExpose
            }
            device?.unlockForConfiguration()
        }catch {
            print(error)
        }
    }
    
    private func showFocusView(_ point: CGPoint) {
        view.addSubview(focusView)
        var center = point
        center.x += 150.0 / 4.0
        focusView.center = center
    }
    
    //    MARK: - 调整曝光
    @objc private func panAction(_ pan: UIPanGestureRecognizer) {
        guard let focusV = view.viewWithTag(99) as? FocusView else {return}
        var last: CGPoint = .zero
        switch pan.state {
        case .began:
            last = pan.translation(in: view)
        case .changed:
            focusV.lastTime = Date().timeIntervalSince1970
            let now = pan.translation(in: view)
            let change = last.y - now.y
            exposureAction(change)
            last = now
        case .ended:
            focusV.updateLastTime()
        default:
            break
        }
    }
    
    private func exposureAction(_ change: CGFloat) {
        var bias = device?.exposureTargetBias ?? 0
        let x = Float(change / 2000.0)
        bias += x
        if bias > 3.0 {
            bias = 3.0
        }else if bias < -3.0 {
            bias = -3.0
        }
        do {
            try device?.lockForConfiguration()
            updateSunLocation(bias)
            device?.setExposureTargetBias(bias, completionHandler: nil)
            device?.unlockForConfiguration()
        }catch {
            print(error)
        }
    }
    
    private func updateSunLocation(_ bias: Float) {
        if let v = view.viewWithTag(99) as? FocusView {
            v.updateSunLocation(-bias)
        }
    }
    
    //    MARK: - 保存照片，并根据参数判断是否跳转到裁剪界面
    private func saveAndNextAction(_ image: UIImage) {
        DispatchQueue.main.async {
            let type = PickerManager.default.type
            switch type {
            case .origin(let originType):
                switch originType {
                case .single:
                    UIImageWriteToSavedPhotosAlbum(
                        image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil
                    )
                    self.dismiss(animated: true, completion: nil)
                    PickerManager.default.delegate?.imagePicker(nil, getOriginImage: image)
                case .several:
                    NotificationCenter.default.post(
                        name: PickerNotice.SaveImage,
                        object: nil,
                        userInfo: ["image" : image]
                    )
                    self.navigationController?.popViewController(animated: true)
                }
            case .edit(let editType):
                let vc = DzyImageBrowserVC(image, type: editType)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    //    MARK: - 界面设置
    private func setUI() {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        view.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        view.addGestureRecognizer(pan)
        
        let takePhotoBtn = TakePhotoBtn(type: .custom)
        takePhotoBtn.addTarget(self, action: #selector(takePhotoAction(_:)), for: .touchUpInside)
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
            saveAndNextAction(image)
        }
    }
    
    // iOS 10.0
    open func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let buffer = photoSampleBuffer,
            let jpegData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
            let image = UIImage(data: jpegData)
        {
            saveAndNextAction(image)
        }
    }
    
    @objc open func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("成功")
    }
}
