## 0.1.1

### 更新内容
- ✅ iOS：Flutter 插件内置 iOS 端实现并通过 CocoaPods 自动集成（无需手动配置 SPM/Pod 依赖，最低 iOS 13.0）
- ✅ Flutter：`init` 支持传入 `signalingUrl`（用于配置 `/ws/signaling`）
- ✅ 多人语聊：信令协议增强（`user-list` + `toUid`），适配多人 Mesh 连接模型
- ✅ 文档：同步更新安装/发布说明，避免旧文档导致集成失败

## 0.1.0

### 更新内容
- ✅ 更新版本号至 0.1.0
- ✅ 更新 iOS SDK 依赖方式为 Swift Package Manager（GitHub）
- ✅ 更新 Android SDK 依赖方式为 JitPack
- ✅ 完善文档说明，明确原生 SDK 配置要求
- ✅ 更新 iOS 最低版本要求至 13.0

### 重要提示
- Flutter SDK 需要依赖原生 Android SDK；iOS 端已在插件内置并自动集成
- Android SDK 已发布到 JitPack: `com.github.carlcy:sy-rtc-android-sdk:v1.0.0`

## 0.0.1

* TODO: Describe initial release.
