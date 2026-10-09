# SY RTC Flutter SDK

[![pub package](https://img.shields.io/pub/v/sy_rtc_flutter_sdk.svg)](https://pub.dev/packages/sy_rtc_flutter_sdk)

**当前版本**: 3.3.0

Flutter 实时音视频插件。Android / iOS 原生能力分别来自 [sy-rtc-android-sdk](https://github.com/carlcy/sy-rtc-android-sdk) 与 [sy-rtc-ios-sdk](https://github.com/carlcy/sy-rtc-ios-sdk)。

客户工程只在 `pubspec.yaml` 里写包名和版本，然后 `flutter pub get`。不要下载 zip、不要把 AAR / framework 拷进工程。

## 客户依赖（直接复制）

```yaml
dependencies:
  sy_rtc_flutter_sdk: ^3.3.0
```

包还没出现在 pub.dev 时，用已经打好的 tag（不要写 `ref: main`）：

```yaml
dependencies:
  sy_rtc_flutter_sdk:
    git:
      url: https://github.com/carlcy/sy-rtc-flutter-sdk.git
      ref: v3.3.0
```

本仓库 `example/pubspec.yaml` 里的 `path: ../` 只给插件作者本地联调，不是客户接入方式。

然后执行：

```bash
flutter pub get
```

## 快速开始

流程与即构 Flutter 快速开始相同：加依赖 → 配权限 → 初始化 → 向你的服务器要 Token → 进频道 → 渲染画面。

### 1. 添加依赖

见上一节。最低要求：Flutter >= 3.3.0，Dart >= 3.6.2，Android minSdk 21，iOS 13.0。

### 2. 平台配置

#### Android

插件用 `api` 传递这份坐标（须先在 JitPack 发布 tag `v3.3.0`）：

```gradle
implementation 'com.github.carlcy:sy-rtc-android-sdk:v3.3.0'
```

业务模块不用再写一遍，但必须能解析 JitPack。在 `android/build.gradle`：

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

如果工程把仓库收进了 `android/settings.gradle` 的 `dependencyResolutionManagement`，把同一条 `maven { url 'https://jitpack.io' }` 加到那里。

权限（插件 Manifest 会合并进宿主；麦克风和摄像头仍要在运行时申请）：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

运行时申请可以用 `permission_handler`：

```dart
await Permission.microphone.request();
await Permission.camera.request();
```

#### iOS

在 `ios/Runner/Info.plist` 增加用途说明，否则系统不会弹出授权：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限进行语音通话</string>
<key>NSCameraUsageDescription</key>
<string>需要摄像头权限进行视频通话</string>
```

`pod install` 由 Flutter 在构建时执行，最低 iOS 13.0。

**iOS 原生 SDK：** 插件依赖 CocoaPods trunk 上的 `SyRtcSDK` `3.3.0`（源码仓库 `https://github.com/carlcy/sy-rtc-ios-sdk`，tag `v3.3.0`，也有 SPM 的 `Package.swift`），WebRTC 由 `SyRtcSDK` 传递（`WebRTC-SDK` `125.6422.07`）。插件不再内置 iOS 源码，客户无需自己写 `pod 'SyRtcSDK'`。

3.3.0 起 `SyRtcSDK` 依赖 `LiveKitClient` 2.17（不在 Trunk），宿主 `ios/Podfile` 顶部要加：

```ruby
source 'https://github.com/livekit/podspecs.git'
source 'https://cdn.cocoapods.org/'
```

Android 已经能按坐标拉取，所以 example 里的本地 AAR / flatDir 已去掉。

客户要写的那一行是：

```yaml
sy_rtc_flutter_sdk: ^3.3.0
```

发布前：

1. 先发布原生 Android tag，确认 JitPack 能解析 `com.github.carlcy:sy-rtc-android-sdk:v3.3.0`（插件当前用这个坐标），再发 Flutter 包。
2. 先把 iOS SDK 推上 trunk（[sy-rtc-ios-sdk 的发布说明](https://github.com/carlcy/sy-rtc-ios-sdk/blob/main/PUBLISH_GUIDE.md)：`pod lib lint SyRtcSDK.podspec` → `pod trunk push SyRtcSDK.podspec --allow-warnings`），等 CDN 能解析后再改 podspec 里的 `s.dependency 'SyRtcSDK', 'x.y.z'`。
3. 对齐版本号：`pubspec.yaml`、`CHANGELOG.md`、`android/build.gradle` 的 `version`、`ios/sy_rtc_flutter_sdk.podspec` 的 `s.version`。CHANGELOG 最上一项必须是这个版本。
4. 在仓库根目录检查：

```bash
dart pub publish --dry-run
```

没有 error 再发布。首次需要：

```bash
dart pub login
dart pub publish
```

5. 发布成功后打 tag，供 git 依赖使用（tag 与 pubspec 版本一致，带 `v` 前缀）：

```bash
git tag v3.3.0
git push origin v3.3.0
```

`dart pub publish` 会带上 `example/`。example 继续使用 `path: ../`，这是 pub.dev 对插件示例的常规写法。

## 媒体服务器（LiveKit）

服务端配置了 LiveKit 节点时，拉 Token 带 `meta: true`，把返回的 JSON 字符串原样交给 `join` / `renewToken`：

```dart
final metaJson = await rooms.fetchToken(channelId: channelId, uid: uid, meta: true);
await engine.join(channelId, uid, metaJson);
```

- 媒体切换在原生 SDK 里完成（Android `livekit-android`、iOS `LiveKitClient`），Dart 侧只透传 JSON：`mediaWired=true` 且有 `sfuUrl` / `sfuToken` 时走 LiveKit，否则走 P2P，调用方式不变。插件不再额外引入 Dart 的 `livekit_client`，避免同一进程里两套媒体栈。
- 被踢只回调一次 `onKicked`；服务端静音本端回调 `onServerMuteAudio`，SDK 不自动开麦；网络质量 / 音量来自 LiveKit。
- 媒体断开时 `onConnectionStateChanged` 的原因是 `sfu_lost` / `sfu_reconnecting`（映射为 `interrupt`），恢复后是 `sfu_reconnected`（映射为 `rejoinSuccess`）。
- 目前只在 P2P 下可用：屏幕共享、自定义视频源与美颜、数据流、SEI、频道内录音、伴奏混入上行。
- 需要原生 3.3.0 及以上（插件 3.3.0 已依赖 Android `v3.3.0`、iOS `SyRtcSDK` 3.3.0）。iOS 用 CocoaPods 时宿主 `Podfile` 顶部要先写 `source 'https://github.com/livekit/podspecs.git'`，再写 `source 'https://cdn.cocoapods.org/'`（`LiveKitClient` 2.17 不在 Trunk）；Android 宿主仓库要有 `https://jitpack.io`。
- 联调未发布的原生构建：Android 在原生仓库 `./gradlew publishToMavenLocal -PPOM_VERSION=livekit-local`，宿主 `android/gradle.properties` 写 `syRtcAndroidSdkVersion=livekit-local`（不写时插件用 `v3.3.0`）；iOS 在宿主 `Podfile` 写 `pod 'SyRtcSDK', :path => '<rtc-ios-sdk 路径>'`。

## 常见问题

**初始化或进房失败。** 核对 AppId、Token 是否过期、麦克风/摄像头是否已授权。Token 必须来自业务服务器。

**Android 构建找不到 `com.github.carlcy:sy-rtc-android-sdk`。** 宿主仓库列表里没有 `https://jitpack.io`。不要改回本地 AAR。

**iOS 模拟器黑屏。** 模拟器通常没有摄像头。用真机看 `SyRtcVideoView`。

**没有声音。** 依次 `enableLocalAudio(true)`、`muteLocalAudio(false)`、`setClientRole('host')`。

## 许可证

MIT License
