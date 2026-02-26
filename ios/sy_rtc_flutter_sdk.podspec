#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sy_rtc_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sy_rtc_flutter_sdk'
  s.version          = '1.4.0'
  s.summary          = 'SY RTC Flutter SDK - A Flutter plugin for real-time audio and video communication'
  s.description      = <<-DESC
SY RTC Flutter SDK provides real-time audio and video communication capabilities for Flutter applications.
Android 端依赖原生 SDK；iOS 端已在插件内置实现并自动集成（无需手动配置 iOS SDK）。
                       DESC
  s.homepage         = 'https://github.com/carlcy/sy_rtc_flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SY RTC Team' => 'support@sy-rtc.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'SyRtcSDK/**/*.swift'
  s.dependency 'Flutter'
  # iOS 端内置 SyRtcSDK 源码，并依赖 GoogleWebRTC（避免 Flutter 用户手动集成）
  s.dependency 'GoogleWebRTC'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  # Apple Silicon 下 Simulator arm64 可能与部分预编译依赖不匹配，这里一并排除，避免链接失败。
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'sy_rtc_flutter_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
