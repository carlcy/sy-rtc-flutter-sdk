# SY RTC Flutter 示例

这个示例演示客户会走的通话流程：初始化、向业务服务器要 Token、加入频道、渲染本地/远端视频、续期 Token、切换画质。

## 客户怎么依赖 SDK

正式工程写版本，不要下载 zip：

```yaml
dependencies:
  sy_rtc_flutter_sdk: ^3.2.1
```

还没发到 pub.dev 时：

```yaml
dependencies:
  sy_rtc_flutter_sdk:
    git:
      url: https://github.com/carlcy/sy-rtc-flutter-sdk.git
      ref: v3.2.1
```

本目录的 `pubspec.yaml` 使用 `path: ../`，只为了在本仓库里跑当前源码。这不是客户接入方式。

Android 原生库由插件传递，坐标是 `com.github.carlcy:sy-rtc-android-sdk:v3.2.0`（JitPack，需先发布该 tag）。示例不再引用本地 AAR。iOS 依赖 CocoaPods trunk 上的 `SyRtcSDK` 3.2.1（插件传递）。说明见仓库根目录 README。

## 运行

```bash
flutter pub get
flutter run
```

默认 API：`https://syrtcapi.shengyuchenyao.cn`。覆盖：

```bash
flutter run --dart-define=SY_API_BASE=https://your-api.example
```

填写控制台里的 AppId。测试环境可填 AppSecret，用来请求 `POST /api/rtc/token`。正式客户端不要内置 AppSecret。

页面按钮：请求权限、初始化、加入、离开、静音、启用视频、续期 Token、语音/标清/高清/超清。

## 权限

- Android：`example/android/app/src/main/AndroidManifest.xml`
- iOS：`example/ios/Runner/Info.plist`（`NSMicrophoneUsageDescription`、`NSCameraUsageDescription`）

模拟器经常没有摄像头，PlatformView 黑屏是预期情况。真机才能看到画面。
