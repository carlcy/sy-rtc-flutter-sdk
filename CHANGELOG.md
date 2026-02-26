## 1.4.0

### 新功能

- **频道消息**：新增 `sendChannelMessage(message)` 方法和 `onChannelMessage` 事件，支持向频道内所有用户广播自定义消息（JSON 格式），可用于麦位同步、自定义信令等场景
- **在线人数修复**：修复后加入房间的用户无法看到已有用户的问题（SDK 收到 `user-list` 时现在会正确触发 `onUserJoined`）

### 改进

- **Flutter Example**：麦位状态通过频道消息实现跨用户实时同步（上麦/下麦/静音/退出）
- **Demo 地址**：所有 demo 中的 API/信令地址改为域名（`https://syrtcapi.shengyuchenyao.cn`）

### 升级说明

- Flutter：`sy_rtc_flutter_sdk: ^1.4.0`
- Android：`com.sy.rtc:sy-rtc-android-sdk:1.4.0`
- iOS：`pod 'SyRtcSDK', '~> 1.4.0'` 或 SPM tag `v1.4.0`

---

## 1.3.1

### Fixes

- **Fix**: Android crash on init due to missing `BLUETOOTH_CONNECT` permission on Android 12+ (asynchronous `BluetoothHeadset.getConnectedDevices()` in `initializeAudioDevices`)
- **Fix**: Android release build crash due to R8/ProGuard stripping `org.webrtc.*` JNI classes (added consumer ProGuard rules)
- **Fix**: Improved error handling in Android native plugin with `try-catch(Throwable)` to prevent unhandled native crashes
- **Improvement**: iOS native demo now has a complete Xcode project with programmatic UI
- **Improvement**: Android native demo updated to use local SDK AAR with Bluetooth permissions

---

## 1.3.0

### 语音功能修复与三端版本统一

- **版本**：Flutter / Android / iOS 三端统一为 **1.3.0**；Flutter 插件内 `android/build.gradle`、`ios/sy_rtc_flutter_sdk.podspec` 已同步为 1.3.0，Android 依赖为 `sy-rtc-android-sdk:v1.3.0`。
- **语音相关修复与优化**：
  - **Android**：`enableLocalAudio`/`muteLocalAudio` 仅控制 WebRTC `localAudioTrack`，不再误操作 `AudioRecord`；`enableAudio`/`disableAudio` 改为控制 `localAudioTrack`，与语音推流一致；`join()` 增加 channelId/uid/token 空校验并回调 `onError`。
  - **iOS**：`muteLocalAudio` 实际生效（`localAudioTrack?.isEnabled = !muted`）；`enableLocalAudio` 同时设置 `localAudioTrack?.isEnabled`；`enableAudio`/`disableAudio` 同步设置 `localAudioTrack`；`join()` 增加参数空校验并回调 `onError(1000, ...)`。
  - **Flutter**：事件处理 `_handleMethodCall` 增加 try/catch，解析异常时推送 `SyErrorEvent` 并回调 `onError`，避免崩溃；补全 default 分支与返回值。
- **发布**：各 SDK 与 Flutter 示例版本已更新为 1.3.0；建议先提交代码再打 tag 发版。

### 升级说明

1. Flutter：`sy_rtc_flutter_sdk: ^1.3.0`（或 `path` 使用本地）。
2. Android：`com.github.carlcy:sy-rtc-android-sdk:v1.3.0`。
3. iOS：`pod 'SyRtcSDK', '~> 1.3.0'` 或 SPM 选择 1.3.0。

---

## 1.2.0

### 版本统一与示例完善

- **版本**：Flutter / Android / iOS SDK 及示例统一为 **1.2.0**。
- **Flutter 示例**：
  - 新增配置页：API 基础 URL、信令 URL、AppId、可选 JWT。
  - 新增 Token 拉取：通过 `POST /api/rtc/token` 获取 RTC Token（需配置 JWT）。
  - 主流程：保存并初始化 → 拉取 Token / 手动输入 → 加入/离开频道、静音、直播控制。
  - 示例版本号：`1.2.0+0`；README 补充 Android/iOS 打包与 NDK 问题说明。
- **Android 示例构建**：AGP 8.3、Gradle 8.7，满足 Flutter 最低要求；若 NDK 报错请按 README 处理。
- **iOS 构建**：`flutter build ios --no-codesign` 与 `flutter run` 已验证通过（建议先 `flutter clean`）。
- **发布**：各 SDK 与 Demo 中引用版本均已更新为 1.2.0，并更新版本说明与发布指南。

### 升级说明

1. 更新 Flutter 依赖：`sy_rtc_flutter_sdk: ^1.2.0`（或 `path: ../` 使用本地）。
2. 更新 Android：`com.github.carlcy:sy-rtc-android-sdk:v1.2.0`。
3. 更新 iOS：`pod 'SyRtcSDK', '~> 1.2.0'` 或 SPM 选择 1.2.0。

---

## 1.0.6

### 重大更新
- ✅ **RTMP服务器集成**：完整的RTMP服务器部署和鉴权机制
- ✅ **自动生成推流地址**：SDK支持自动生成RTMP推流地址，无需手动配置
- ✅ **完整鉴权机制**：推流和播放双重鉴权，确保不同AppId的流完全隔离
- ✅ **后端集成文档**：完整的后端集成指南和API参考文档

### 更新内容

#### Flutter SDK
- ✅ 支持 `startRtmpStreamWithTranscoding` 传入空字符串，自动使用后端生成的RTMP地址
- ✅ 更新文档说明，明确Token获取流程

#### Android SDK
- ✅ 支持 `startRtmpStreamWithTranscoding` 传入空字符串，自动使用后端生成的RTMP地址
- ✅ 版本号更新至 1.0.6

#### iOS SDK
- ✅ 支持 `startRtmpStreamWithTranscoding` 传入空字符串，自动使用后端生成的RTMP地址
- ✅ 版本号更新至 1.0.6

#### 用户端前端
- ✅ 文档更新：添加后端集成指南和API参考文档标签页
- ✅ 导航栏修复：首页和文档不再同时高亮
- ✅ 文档完善：添加完整的SDK API文档，直播和语聊分开

#### 后端服务
- ✅ **rtc-service**：新增RTMP鉴权服务（RtmpAuthController、RtmpAuthService、RtmpUrlService）
- ✅ **rtc-service**：新增获取推流和播放地址接口（`GET /api/rtc/live/stream-urls`）
- ✅ **rtc-service**：自动生成RTMP地址功能（如果rtmpUrls为空）
- ✅ **RTMP服务器**：完整的SRS配置，支持HTTP回调鉴权
- ✅ **RTMP服务器**：流名称格式为 `{appId}_{channelId}`，确保不同AppId的流隔离

### 重要提示
- **RTMP服务器**：已集成到部署脚本，自动部署SRS RTMP服务器
- **鉴权机制**：推流和播放都需要通过鉴权，确保安全性
- **Token获取**：SDK的Token必须从你的后端服务器获取，不能直接在前端调用SY RTC的API
- **后端集成**：请参考 `BACKEND_INTEGRATION_GUIDE.md` 和 `API_REFERENCE.md` 完成后端集成

### 升级说明
1. **SDK升级**：更新Flutter/Android/iOS SDK到1.0.6版本
2. **后端部署**：重新部署 `rtc-service` 模块（包含RTMP鉴权功能）
3. **RTMP服务器**：运行 `./deploy.sh` 自动部署RTMP服务器
4. **文档更新**：查看 `BACKEND_INTEGRATION_GUIDE.md` 了解完整的后端集成流程

## 1.0.5

### 重大更新
- ✅ **统一版本号**：Flutter/Android/iOS 三端版本统一为 1.0.5
- ✅ **直播控制UI**：Flutter SDK 新增完整的直播控制可视化界面（开播/停播/切换布局/实时调整转码配置）
- ✅ **用户端前端优化**：RTC 和直播功能分离为独立模块，新增房间管理和直播任务管理页面
- ✅ **管理端前端优化**：RTC 和直播管理分离，新增消耗统计页面（房间数、用户数、时长消耗）
- ✅ **后端API完善**：新增 RTC 和直播消耗统计接口，支持详细的消费数据查询

### 更新内容

#### Flutter SDK
- ✅ 新增 `LiveControlPage` 可视化直播控制页面
- ✅ 修复 `SyLiveTranscoding` 和 `SyTranscodingUser` 导入冲突问题
- ✅ 完善直播推流功能，支持动态切换布局和转码配置

#### Android SDK
- ✅ 版本号更新至 1.0.5
- ✅ 完善示例应用，支持基本 RTC 功能演示

#### iOS SDK
- ✅ 版本号更新至 1.0.5
- ✅ 完善示例应用，支持基本 RTC 功能演示
- ✅ 与 Flutter SDK 同步更新

#### 用户端前端
- ✅ RTC 房间管理：新增房间列表、人数统计、消耗时长统计页面
- ✅ 直播任务管理：新增直播任务列表、状态查询、停止控制页面
- ✅ 文档完善：更新 Guide 页面，添加 RTC 和直播对比说明、常见问题
- ✅ 修复 TypeScript 编译错误

#### 管理端前端
- ✅ RTC 消耗统计：新增总房间数、活跃房间、总用户数、总消耗时长统计
- ✅ 直播消耗统计：新增总直播任务数、运行中任务、总用户数、总消耗时长统计
- ✅ 直播任务管理：支持强制停流、封禁/解封、布局切换功能
- ✅ 菜单结构优化：RTC 和直播功能分离为独立模块

#### 后端服务
- ✅ 新增 `CallLog` 实体和 `CallLogMapper`（用于 RTC 消耗统计）
- ✅ 新增 `RtcConsumptionController`：提供 RTC 消耗统计和详情列表接口
- ✅ 新增 `LiveConsumptionController`：提供直播消耗统计和详情列表接口

### 重要提示
- 本次更新统一了三端 SDK 版本号，建议同时更新 Flutter/Android/iOS SDK
- 用户端和管理端前端已重新部署，包含所有新功能
- 后端 API 已更新，支持详细的消耗统计查询

## 0.1.1

### 更新内容
- ✅ iOS：Flutter 插件内置 iOS 端实现并通过 CocoaPods 自动集成（无需手动配置 SPM/Pod 依赖，最低 iOS 13.0）
- ✅ Flutter：`init` 支持传入 `signalingUrl`（用于配置 `/ws/signaling`）
- ✅ 多人语聊：信令协议增强（`user-list` + `toUid`），适配多人 Mesh 连接模型
- ✅ 文档：同步更新安装/发布说明，避免旧文档导致集成失败

## 0.1.2

### 更新内容
- ✅ 事件通道：兼容 `sy_rtc_flutter_sdk/events`，确保 Android/iOS 原生事件都能被 Dart 端接收
- ✅ 错误回调：Android/iOS 原生错误统一透传到 `engine.onError`
- ✅ RTMP：未集成推流库时改为显式错误回调（避免“看似成功实际失败”）

## 0.1.3

### 更新内容
- ✅ Flutter 插件：补齐 Dart 层大量 MethodChannel 能力在 Android/iOS 原生侧的实现，消除 MissingPlugin
- ✅ iOS：修复内置 SyRtcSDK 编译问题，示例工程可 `flutter build ios --no-codesign` 通过
- ✅ WebRTC 直播旁路：新增服务端 egress 组件（`rtc-egress-service`）与后端控制接口（`/api/rtc/egress/*`）

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

### 更新内容
- ✅ 初始发布：基础语聊能力（初始化/加入离开/本地静音/角色设置/事件回调）
