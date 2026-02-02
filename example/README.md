# SY RTC Flutter SDK 示例

本示例演示如何使用 `sy_rtc_flutter_sdk` 进行语聊房与直播相关功能测试。

## 功能说明

- **配置**：填写 API 基础 URL、信令 URL、AppId，可选填写 JWT（用于拉取 RTC Token）。
- **初始化**：点击「保存并初始化」后，SDK 会请求后端功能权限（语聊/直播）。
- **拉取 Token**：若已填 JWT，可点击「拉取 Token」从后端 `POST /api/rtc/token` 获取 RTC Token；否则需手动粘贴 Token。
- **加入/离开频道**：使用频道 ID、用户 ID 和 Token 加入或离开 RTC 频道。
- **静音/取消静音**：在频道内控制本地麦克风。
- **直播控制面板**：进入直播控制页，配置 RTMP 推流地址、布局与转码参数，进行开播/停播。

## 环境要求

- Flutter SDK 3.6+
- Android：Android SDK（API 21+）
- iOS：Xcode 与 CocoaPods（真机/模拟器）

## 依赖

示例使用本地插件路径依赖：

```yaml
dependencies:
  sy_rtc_flutter_sdk:
    path: ../
  http: ^1.2.0
```

首次运行前请执行：

```bash
cd sy_rtc_flutter_sdk/example
flutter pub get
```

## 打包与运行

### Android

- **调试 APK**（用于测试）：
  ```bash
  cd sy_rtc_flutter_sdk/example
  flutter build apk --debug
  ```
  输出：`build/app/outputs/flutter-apk/app-debug.apk`

- **Release APK**（正式包）：
  ```bash
  flutter build apk --release
  ```
  输出：`build/app/outputs/flutter-apk/app-release.apk`

- **直接安装到设备**：
  ```bash
  flutter run
  ```
  或先 `flutter devices` 选择设备后 `flutter run -d <device_id>`。

### iOS

- **真机/模拟器运行**：
  ```bash
  cd sy_rtc_flutter_sdk/example
  flutter run
  ```
  首次 iOS 构建需安装 CocoaPods 依赖：`cd ios && pod install && cd ..`（若 Flutter 未自动执行）。

- **打包 IPA（需 Apple 开发者账号与签名）**：
  ```bash
  flutter build ipa
  ```
  或使用 Xcode 打开 `ios/Runner.xcworkspace` 进行 Archive 与导出。

- **仅构建 iOS 应用（不打包 IPA）**：
  ```bash
  flutter build ios
  ```

## 从项目根目录执行

若当前在仓库根目录 `rtc`：

```bash
# Android 调试包
flutter build apk --debug -t sy_rtc_flutter_sdk/example/lib/main.dart -C sy_rtc_flutter_sdk/example

# iOS 运行
flutter run -t sy_rtc_flutter_sdk/example/lib/main.dart -C sy_rtc_flutter_sdk/example
```

## 配置说明

- **API 基础 URL**：与后端约定，如 `https://your-rtc-server.com`（不要末尾 `/`）。
- **信令 URL**：WebSocket 地址，如 `wss://your-rtc-server.com/ws/signaling`。
- **AppId**：后端分配的应用 ID。
- **JWT**：用户登录后获得的 Bearer Token，用于调用 `POST /api/rtc/token` 获取 RTC Token；不填则需在「RTC Token」输入框手动粘贴 Token。

后端 RTC Token 接口见项目根目录 `API_REFERENCE.md`（`POST /api/rtc/token`）。

## 权限

- **Android**：已在 `AndroidManifest.xml` 中声明 `INTERNET`、`RECORD_AUDIO`、`MODIFY_AUDIO_SETTINGS`、`CAMERA`、`ACCESS_NETWORK_STATE`。
- **iOS**：已在 `Info.plist` 中配置 `NSMicrophoneUsageDescription`、`NSCameraUsageDescription`；测试环境允许 HTTP 通过 `NSAppTransportSecurity`。

## 常见问题

### Android 构建失败：NDK source.properties 缺失 (CXX1101)

若出现 `NDK at ... did not have a source.properties file`，多为 NDK 下载不完整。处理方式：

1. 删除提示路径下的 NDK 目录（如 `$ANDROID_HOME/ndk/28.2.13676358`）。
2. 再次执行 `flutter build apk --debug`，由 Android Gradle Plugin 自动重新下载 NDK。

## 参考

- [Flutter 官方文档](https://docs.flutter.dev/)
- 项目根目录 `API_REFERENCE.md`：后端 API 说明
- 项目根目录 `SDK_AUDIT_CHECKLIST.md`：SDK 与后端对齐说明
