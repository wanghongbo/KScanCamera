# KScanCamera

iOS扫描二维码组件，使用Swift语言实现，支持界面定制，支持取景框，支持iPhone、iPad，支持方向旋转，支持闪光灯，可从相册选择二维码图片进行识别（需要引入TZImagePickerController）。

# 用法

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func scan(_ sender: Any) {
        let instance = KScanCameraViewController.instance
        instance.cancelEvent = .pop
        instance.didReceiveCode = {(code: String) -> Void in
            print("----received code: \(code)")
            self.navigationController?.popViewController(animated: true)
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
