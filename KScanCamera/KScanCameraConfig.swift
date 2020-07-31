//
//  KScanCameraConfig.swift
//  KScanCamera
//
//  Created by WHB on 2020/3/2.
//  Copyright © 2020 WHB. All rights reserved.
//

import AVFoundation

/// 扫码参数配置
public struct KScanCameraConfig {
    /// 扫描分辨率
    public var preset: AVCaptureSession.Preset = .hd1920x1080
    /// 扫码界面标题
    public var title: String = "二维码"
    /// 扫码界面提示文字
    public var message: String = "将二维码放入扫描框内，即可自动识别"
    /// 是否隐藏从相册选择
    public var isAlbumHidden: Bool = false
    /// 相机被禁用时，请求相机权限提示文字
    public var cameraAccessMsg: String = "相机访问权限被禁用，请启用APP对相机的访问权限"
    
    public init() {
        //
    }
}
