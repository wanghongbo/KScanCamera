//
//  KScanCameraViewController.swift
//  KScanCamera
//
//  Created by WHB on 2019/10/31.
//  Copyright © 2019 WHB. All rights reserved.
//

import UIKit
import AVFoundation
import TZImagePickerController

/// 点击相机界面取消（返回）按钮所执行的事件
public enum KCameraCancelEvent {
    /// 对于present的相机实例，请使用dismiss
    case dismiss
    /// 对于push进navigationController的相机实例，请使用pop
    case pop
    /// 对于push进navigationController的相机实例，如果navigationController有多级界面，想退出到第一级界面，请使用popToRoot
    case popToRoot
}

public class KScanCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// 点击取消执行的事件
    public var cancelEvent: KCameraCancelEvent = .pop
    /// 识别到二维码
    public var didReceiveCode: ((_ code: String) -> Void)?
    /// 点击取消
    public var didCancel: (() -> Void)?
    /// 扫码界面配置
    public var config = KScanCameraConfig()
    
    private var cameraAccessMsg: String {
        get {
            return self.config.cameraAccessMsg
        } set {
            return
        }
    }
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var albumBtn: UIButton!
    @IBOutlet weak var scanActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scanView: KScanDrawView!
    @IBOutlet weak var scanLine: UIImageView!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var torchView: UIView!
    @IBOutlet weak var torchImgView: UIImageView!
    @IBOutlet weak var torchMsgLbl: UILabel!
    
    private lazy var torchOnImg = UIImage(named: "torch_open", in: KScanCameraViewController.bundle, compatibleWith: nil)
    private lazy var torchOffImg = UIImage(named: "torch_close", in: KScanCameraViewController.bundle, compatibleWith: nil)
    private let torchOnMsg = "轻触关闭"
    private let torchOffMsg = "轻触照亮"
    
    private var captureSessionStarted = false
    private var didAppear = false
    
    // MARK: 生命周期
    
    public static var instance: KScanCameraViewController {
        let sb = UIStoryboard(name: "KScanCamera", bundle: bundle)
        let vc = sb.instantiateViewController(withIdentifier: "KScanCameraViewController") as! KScanCameraViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    public final override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAppResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    public final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public final override func viewDidLayoutSubviews() {
        let videoOrientation: AVCaptureVideoOrientation
        let statusBarOrientation: UIInterfaceOrientation
        if #available(iOS 13, *) {
            if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
                statusBarOrientation = interfaceOrientation
            } else {
                statusBarOrientation = .portrait
            }
        } else {
            statusBarOrientation = UIApplication.shared.statusBarOrientation
        }
        switch statusBarOrientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        case .unknown:
            videoOrientation = .portrait
        @unknown default:
            videoOrientation = .portrait
        }
        self.previewLayer.connection?.videoOrientation = videoOrientation
        self.previewLayer.frame = self.view.frame
    }
    
    public final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.didAppear {
            self.didAppear = true
            self.checkCameraAuthorization { (allowed: Bool) in
                if allowed {
                    self.captureSessionStarted = true
                    DispatchQueue.main.async {
                        self.view.layer.insertSublayer(self.previewLayer, at: 0)
                        self.captureSession.startRunning()
                        self.scanActivityIndicator.stopAnimating()
                        self.startScanAnimation()
                        self.setRectOfInterest()
                    }
                }
            }
        } else {
            self.checkCameraAuthorization { (allowed: Bool) in
                if allowed {
                    DispatchQueue.main.async {
                        self.captureSession.startRunning()
                        self.startScanAnimation()
                    }
                }
            }
        }
    }
    
    public final override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.turnOffTorch()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate，二维码输出代理
    
    public final func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            if let qrCode = metadataObj.stringValue {
                self.captureSession.stopRunning()
                self.didReceiveCode?(qrCode)
            }
        }
    }
    
    /// 视频输出，用于检测光线明暗
    public final func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: kCGImagePropertyExifDictionary as String) as? NSMutableDictionary
        if let brightnessValue = exifData?[kCGImagePropertyExifBrightnessValue] as? CGFloat {
            // 视频输出是在后台线程执行，执行UI操作前需要切换到主线程
            DispatchQueue.main.async {
                self.showOrHideTorchView(with: brightnessValue)
            }
        }
    }
    
    // MARK: 通知
    
    @objc private func onAppResignActive() {
        self.turnOffTorch()
    }
    
    @objc private func onAppBecomeActive() {
        self.startScanAnimation()
    }
    
    // MARK: 事件响应

    @IBAction func dismiss(_ sender: Any) {
        switch self.cancelEvent {
        case .dismiss:
            self.dismiss(animated: true, completion: nil)
        case .pop:
            self.navigationController?.popViewController(animated: true)
        case .popToRoot:
            self.navigationController?.popToRootViewController(animated: true)
        }
        self.didCancel?()
    }
    
    @IBAction func switchTorch(_ sender: Any) {
        guard let device = self.captureDevice, device.hasTorch else {
            return
        }
        do {
            try device.lockForConfiguration()
            if device.torchMode != .on {
                self.torchView.layer.removeAllAnimations()
                device.torchMode = .on
                self.torchImgView.image = self.torchOnImg
                self.torchMsgLbl.text = self.torchOnMsg
            } else {
                device.torchMode = .off
                self.torchImgView.image = self.torchOffImg
                self.torchMsgLbl.text = self.torchOffMsg
            }
            device.unlockForConfiguration()
        } catch {
            //
        }
    }
    
    @IBAction func openAlbum(_ sender: Any) {
        if let picker = TZImagePickerController(maxImagesCount: 1, delegate: nil) {
            picker.allowTakeVideo = false
            picker.allowTakePicture = false
            picker.didFinishPickingPhotosHandle = { [weak self] (photos, assets, isSelectOriginalPhoto) in
                guard let photos = photos, photos.count > 0 else {
                    return
                }
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
                if let ciImage = CIImage(image: photos[0]), let fecture = detector?.features(in: ciImage).first as? CIQRCodeFeature, let result = fecture.messageString {
                    self?.didReceiveCode?(result)
                }
            }
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    // MARK: 暴露方法
    
    /// 开始识别
    public func startCapture() {
        self.checkCameraAuthorization { (allowed: Bool) in
            if allowed {
                DispatchQueue.main.async {
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    // MARK: 私有方法
    
    private func checkCameraAuthorization(completion: @escaping (_ success: Bool) -> Void) {
        // 检查相机访问权限
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .denied, .restricted:
            let alert = UIAlertController(title: "提示", message: self.cameraAccessMsg, preferredStyle: .alert)
            let settingAction = UIAlertAction(title: "去启用", style: .default) { (_) in
                let url = URL(string: UIApplication.openSettingsURLString)!
                if UIApplication.shared.canOpenURL(url){
                    UIApplication.shared.openURL(url)
                }
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(settingAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { (success: Bool) in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .authorized:
            completion(true)
        default:
            break
        }
    }
    
    private func setupUI() {
        self.titleLbl.text = self.config.title
        self.messageLbl.text = self.config.message
        self.albumBtn.isHidden = self.config.isAlbumHidden
        let title = self.cancelEvent == .dismiss ? "取消" : "返回"
        self.cancelBtn.setTitle(title, for: .normal)
    }
    
    /// 开启扫描动画
    private func startScanAnimation() {
        if self.captureSessionStarted {
            self.scanLine.layer.removeAllAnimations()
            self.scanLine.isHidden = false
            let scanAnimation = CABasicAnimation(keyPath: "position.y")
            scanAnimation.duration = 2
            scanAnimation.repeatCount = HUGE
            scanAnimation.toValue = self.scanView.frame.height
            self.scanLine.layer.add(scanAnimation, forKey: "scanAnimation")
        }
    }
    
    private func showOrHideTorchView(with brightness: CGFloat) {
        guard let device = self.captureDevice, device.hasTorch else {
            return
        }
        if brightness < 0 {
            if self.torchView.alpha < 0.001 {
                UIView.animate(withDuration: 0.4, animations: {
                    self.torchView.alpha = 1.0
                }, completion: { (_) in
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.duration = 0.4
                    animation.repeatCount = 2
                    animation.autoreverses = true
                    animation.fromValue = 1.0
                    animation.toValue = 0.0
                    self.torchView.layer.add(animation, forKey: "alphaAnimation")
                })
            }
        } else {
            if device.torchMode == .on {
                return
            }
            if !(self.torchView.alpha < 0.001) {
                self.torchView.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.4, animations: {
                    self.torchView.alpha = 0.0
                })
            }
        }
    }
    
    private func turnOffTorch() {
        guard let device = self.captureDevice, device.hasTorch else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            self.torchImgView.image = self.torchOffImg
            self.torchMsgLbl.text = self.torchOffMsg
            device.unlockForConfiguration()
        } catch {
            //
        }
    }
    
    // MARK: 屏幕旋转
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.setRectOfInterest()
            self.startScanAnimation()
        }
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: getters and setters
    
    public final override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var captureSession: AVCaptureSession = {
        let captureSession = AVCaptureSession()
        // 添加输入源
        if self.captureDeviceInput != nil && captureSession.canAddInput(captureDeviceInput!) {
            captureSession.addInput(captureDeviceInput!)
        }
        // 添加二维码输出源
        if captureSession.canAddOutput(self.captureMetaDataOutput) {
            captureSession.addOutput(self.captureMetaDataOutput)
            // 需要将AVCaptureOutput添加到AVCaptureSession后才能设置metadataObjectTypes，否则会崩溃
            self.captureMetaDataOutput.metadataObjectTypes = self.captureMetaDataOutput.availableMetadataObjectTypes.filter({ (type) -> Bool in
                return type != .face    // 需要将face类型排除在外
            })
        }
        // 添加视频流输出源
        if captureSession.canAddOutput(self.captureVideoDataOutput) {
            captureSession.addOutput(self.captureVideoDataOutput)
        }
        // 扫描分辨率
        if captureSession.canSetSessionPreset(self.config.preset) {
            captureSession.sessionPreset = self.config.preset
        }
        return captureSession
    }()
    
    private lazy var captureDevice: AVCaptureDevice? = {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        return device
    }()
    
    private lazy var captureDeviceInput: AVCaptureInput? = {
        guard let device = self.captureDevice else {
            return nil
        }
        let deviceInput = try? AVCaptureDeviceInput(device: device)
        return deviceInput
    }()
    
    private lazy var captureMetaDataOutput: AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    private lazy var captureVideoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)
        return output
    }()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }()

    /// 设置二维码识别区域
    private func setRectOfInterest() {
        let scanRect = self.scanView.frame
        let interestRect = self.previewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
        self.captureMetaDataOutput.rectOfInterest = interestRect
    }
    
    private static var bundle: Bundle? = {
        var bundle: Bundle?
        if let path = Bundle.main.path(forResource: "KScanCameraBundle", ofType: "bundle") ??  // podfile: #use_frameworks!
            Bundle.main.path(forResource: "Frameworks/KScanCamera.framework/KScanCameraBundle", ofType: "bundle") { // podfile: use_frameworks!
            bundle = Bundle(path: path)
        } else {    // Example Project
            bundle = Bundle.main
        }
        return bundle
    }()
}
