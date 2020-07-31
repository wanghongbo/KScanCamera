//
//  ViewController.swift
//  KScanCamera
//
//  Created by WHB on 7/25/20.
//  Copyright © 2020 WHB. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func scan(_ sender: Any) {
        let instance = KScanCameraViewController.instance
        instance.cancelEvent = .pop
        instance.didReceiveCode = {(code: String) -> Void in
            print("----received code: \(code)")
//            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SecondViewController") {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//            instance.startCapture()
        }
        instance.didCancel = {
            print("----canceled")
        }
        var config = KScanCameraConfig()
        config.title = "二维码"
        config.message = "将二维码放入扫描框内，即可自动识别"
        config.isAlbumHidden = false
        config.preset = .hd1920x1080
        config.cameraAccessMsg = "相机访问权限被禁用，请启用APP对相机的访问权限"
        instance.config = config
        self.navigationController?.pushViewController(instance, animated: true)
    }
    
}
