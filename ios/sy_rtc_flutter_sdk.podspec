#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sy_rtc_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sy_rtc_flutter_sdk'
  s.version          = '3.2.0'
  s.summary          = 'SY RTC Flutter SDK - real-time audio and video calls for Flutter'
  s.description      = <<-DESC
SY RTC Flutter SDK provides real-time audio and video communication capabilities for Flutter applications.
Android 端通过 Gradle 坐标拉取 sy-rtc-android-sdk。
iOS 端在 SyRtcSDK 发布到 CocoaPods trunk 之前，随插件编译仓库内的 SyRtcSDK 源码。
                       DESC
  s.homepage         = 'https://github.com/carlcy/sy-rtc-flutter-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SY RTC Team' => 'support@sy-rtc.com' }
  s.source           = { :path => '.' }
  # 目标坐标（源码在 https://github.com/carlcy/sy-rtc-ios-sdk ，pod 名 SyRtcSDK，tag v3.2.0）：
  #   s.dependency 'SyRtcSDK', '3.2.0'
  #   s.dependency 'WebRTC-SDK', '~> 125.6422.07'
  # CocoaPods 的 s.dependency 只能解析 trunk / spec 仓库，不能写 git URL。
  # trunk 上还没有 SyRtcSDK 3.2.0，因此这里继续编译 ios/SyRtcSDK 源码。
  # trunk 出现 3.2.0 后：改成上面的 dependency，删除 ios/SyRtcSDK，并在 Classes 里 import SyRtcSDK。
  # 内置源码 `import WebRTC`，与 sy-rtc-ios-sdk 3.2.0 一样依赖 WebRTC-SDK 125.6422.07
  # （模块名仍是 WebRTC）。不要改回 GoogleWebRTC，那一版没有这套统计和采集 API。
  s.source_files = 'Classes/**/*', 'SyRtcSDK/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'WebRTC-SDK', '125.6422.07'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  # WebRTC-SDK 125.6422.07 带 arm64 模拟器切片，不能排除 arm64：iOS 26+ 的 Apple Silicon 模拟器只跑 arm64。
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'sy_rtc_flutter_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
