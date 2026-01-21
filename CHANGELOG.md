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
