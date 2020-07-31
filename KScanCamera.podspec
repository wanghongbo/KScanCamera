#
#  Be sure to run `pod spec lint KScanCamera.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "KScanCamera"
  spec.version      = "1.0.1"
  spec.summary      = "iOS扫描二维码组件"

  spec.description  = <<-DESC
  iOS扫描二维码组件，使用Swift语言实现，支持界面定制，支持取景框，支持iPhone、iPad，支持方向旋转，支持闪光灯，可从相册选择二维码图片进行识别。
                   DESC

  spec.homepage     = "https://github.com/wanghongbo/KScanCamera"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = { "WHB" => "wanghongboskate@hotmail.com" }

  spec.platform     = :ios, "9.0"

  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/wanghongbo/KScanCamera.git", :tag => spec.version.to_s }

  spec.source_files  = "KScanCamera/*.{swift}"

  spec.resource_bundle = { 'KScanCameraBundle' => ['KScanCamera/Resources/*.storyboard', 'KScanCamera/Resources/*.xcassets'] }

  spec.dependency "TZImagePickerController", "~> 3.4.0"

end
