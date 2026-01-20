#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sy_rtc_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sy_rtc_flutter_sdk'
  s.version          = '0.1.0'
  s.summary          = 'SY RTC Flutter SDK - A Flutter plugin for real-time audio and video communication'
  s.description      = <<-DESC
SY RTC Flutter SDK provides real-time audio and video communication capabilities for Flutter applications.
This plugin requires native Android and iOS SDKs to be configured in your project.
                       DESC
  s.homepage         = 'https://github.com/carlcy/sy_rtc_flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SY RTC Team' => 'support@sy-rtc.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  # iOS SDK 依赖（通过 Swift Package Manager）
  # 用户需要在 Xcode 中手动添加：https://github.com/carlcy/sy-rtc-ios-sdk
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'sy_rtc_flutter_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
