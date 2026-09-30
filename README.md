# SY RTC Flutter SDK

[![pub package](https://img.shields.io/pub/v/sy_rtc_flutter_sdk.svg)](https://pub.dev/packages/sy_rtc_flutter_sdk)

**当前版本**: 3.2.0

Flutter 实时音视频插件。Android / iOS 原生能力分别来自 [sy-rtc-android-sdk](https://github.com/carlcy/sy-rtc-android-sdk) 与 [sy-rtc-ios-sdk](https://github.com/carlcy/sy-rtc-ios-sdk)。

客户工程只在 `pubspec.yaml` 里写包名和版本，然后 `flutter pub get`。不要下载 zip、不要把 AAR / framework 拷进工程。

## 客户依赖（直接复制）

```yaml
dependencies:
  sy_rtc_flutter_sdk: ^3.2.0
```

包还没出现在 pub.dev 时，用已经打好的 tag（不要写 `ref: main`）：

```yaml
dependencies:
  sy_rtc_flutter_sdk:
    git:
      url: https://github.com/carlcy/sy-rtc-flutter-sdk.git
      ref: v3.2.0
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

插件用 `api` 传递这份坐标（须先在 JitPack 发布 tag `v3.2.0`）：

```gradle
implementation 'com.github.carlcy:sy-rtc-android-sdk:v3.2.0'
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

**iOS 原生 SDK 为什么还在插件里，而不是 CocoaPods 坐标：**

目标坐标是 `pod 'SyRtcSDK', '3.2.0'`，源码仓库是 `https://github.com/carlcy/sy-rtc-ios-sdk`（tag `v3.2.0`，也有 SPM 的 `Package.swift`）。CocoaPods 的 `s.dependency` 只能解析 trunk 或 spec 仓库，不能写 git URL。trunk 上还没有 `SyRtcSDK` 3.2.0。因此插件编译 `ios/SyRtcSDK` 源码（与分支 `cursor/versioned-spm-cocoapods-3ccc` 对齐，采集设备列表改为系统输入口）。WebRTC 使用 `WebRTC-SDK` `125.6422.07`，和 iOS SDK 同一份二进制；源码仍是 `import WebRTC`。

Android 已经能按坐标拉取，所以 example 里的本地 AAR / flatDir 已去掉。

维护者把 iOS SDK 推上 trunk 之后，把 `ios/sy_rtc_flutter_sdk.podspec` 改成：

```ruby
s.dependency 'SyRtcSDK', '3.2.0'
s.dependency 'WebRTC-SDK', '~> 125.6422.07'
```

并删除 pod 内的 `SyRtcSDK` 源码，同时给插件 Swift 补上 `import SyRtcSDK`。在那之前不要让客户自己 `pod 'SyRtcSDK'`，否则会和插件里的同名类型重复。

### 3. 初始化

```dart
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

final engine = SyRtcEngine();

await engine.init(
  appId, // 控制台分配的 AppId
  apiBaseUrl: 'https://syrtcapi.shengyuchenyao.cn',
  signalingUrl: 'wss://syrtcapi.shengyuchenyao.cn/ws/signaling',
);
```

传了 `apiBaseUrl` 时，SDK 会查询该 AppId 是否开通 `rtc`。视频相关接口在未开通时会抛错。

### 4. 获取 Token

Token 由你的业务服务器调用 SY 的 `POST /api/rtc/token` 签发。客户端不要自己拼 Token，也不要在正式包里放 AppSecret。

```dart
final room = SyRoomService(apiBaseUrl: apiBase, appId: appId);
room.setAuthToken(userJwt); // 或仅测试环境 room.setAppSecret(appSecret);

final token = await room.fetchToken(
  channelId: channelId,
  uid: uid,
  tier: SyQualityTier.sd, // audio | sd | hd | fhd
);
```

查询参数与后端一致：`channelId`、`uid`、`expireHours`、`role`、`qualityTier`。

### 5. 加入频道

```dart
engine.onUserJoined.listen((event) {
  debugPrint('远端加入 ${event.uid}');
});

await engine.setClientRole('host'); // 观众用 'audience'
await engine.join(channelId, uid, token);
await engine.enableLocalAudio(true);
```

离开与释放：

```dart
await engine.leave();
engine.dispose();
```

### 6. 渲染视频

```dart
await engine.enableVideo(quality: SyVideoQualityPreset.standard());
await engine.enableLocalVideo(true);
await engine.startPreview();

// 本地预览：uid 留空
SyRtcVideoView(engine: engine, mirror: true);

// 远端：onUserJoined 拿到 uid 后
SyRtcVideoView(engine: engine, uid: remoteUid);
```

`SyRtcVideoView` 是 `AndroidView` / `UiKitView`，viewType 为 `sy_rtc_flutter_sdk/video_view`。模拟器通常没有摄像头，画面黑屏不代表绑定失败。

### 7. 续期 Token

在 `onTokenPrivilegeWillExpire`（即将过期）和 `onRequestToken`（已过期）里向业务服务器再要一次 Token，然后交给引擎。引擎只保存新 Token，供后续重连使用，不会中途拆掉信令连接。

```dart
engine.setEventHandler(SyRtcEventHandler(
  onTokenPrivilegeWillExpire: () async {
    final next = await room.fetchToken(
      channelId: channelId,
      uid: uid,
      tier: SyQualityTier.sd,
    );
    await engine.renewToken(next);
  },
  onRequestToken: () async {
    final next = await room.fetchToken(
      channelId: channelId,
      uid: uid,
      tier: SyQualityTier.sd,
    );
    await engine.renewToken(next);
  },
));
```

### 8. 切换画质

`SyQualityTier` 与后端 `qualityTier` 对齐。先拿新档位的 Token 并 `renewToken`，再改本地编码，避免本地分辨率高于 Token 允许的档位。

```dart
final next = await room.fetchToken(
  channelId: channelId,
  uid: uid,
  tier: SyQualityTier.hd,
);
await engine.renewToken(next);
await engine.setQualityTier(SyQualityTier.hd);
```

| 档位 | 后端取值 | 本地编码 |
| --- | --- | --- |
| 语音 | `audio` | 关闭视频模块 |
| 标清 | `sd` | 480p |
| 高清 | `hd` | 720p |
| 超清 | `fhd` | 1080p |

原有的 `setVideoQuality` / `setVideoEncoderConfiguration` 不变。4K 预设 `SyVideoQualityPreset.ultraHd()` 在换 Token 时映射到 `fhd`，因为后端没有单独的 4K 档。

也可以一次做完续期和编码：

```dart
await engine.switchQualityTier(tier: SyQualityTier.hd, token: nextToken);
```

### 9. 频道属性

用用户 JWT，不要用 AppSecret。

```dart
room.setAuthToken(userJwt);
await room.setChannelMeta(channelId: channelId, key: 'title', value: '演示房');
final meta = await room.getChannelMeta(channelId: channelId);
await room.deleteChannelMeta(channelId: channelId, key: 'title');
```

对应 `POST /api/rtc/channel/meta/set|get|delete`，请求头 `Authorization: Bearer <JWT>`。

### 10. Token 业务码

`POST /api/rtc/token` 或引擎 `onError` 返回这些码时，会抛出 `SyTokenException`，并额外回调 `onTokenError`（原来的 `onError` 仍会触发）。

| 码 | 含义 |
| --- | --- |
| 4031 | Token 无效 |
| 4032 | Token 已过期 |
| 4033 | 权限不足（角色或画质档位不允许） |

### 11. 已接通的原生能力

音量、网络质量、路由、摄像头、屏幕共享、静音、数据流和重连都转到当前原生实现。两端算法和接口并不相同，下面是实际行为。

**音量。** `enableAudioVolumeIndication` 之后，`onVolumeIndication` 里的 `volume` 两端都是 0–255。Android 用 PCM RMS；本地用户的 `uid` 是 `local`。iOS 把 WebRTC `audioLevel`（0–1）乘 255；本地 `uid` 是进房时的 uid。没有统计样本时音量是 0。`vad` 只在 iOS 且 `reportVad: true`、能量大于 0.02 时为 1；Android 没有人声检测，`vad` 为 0。

**网络质量。** 请用 `onNetworkQualityLevel`（或事件的 `txLevel` / `rxLevel`），类型是两端统一的 `SyNetworkQualityLevel`：`unknown` / `excellent` / `good` / `poor` / `bad` / `down`。质量由本机 RTT 和丢包算出，没有样本时是 `unknown`，不会填成 excellent。一次回调里的上下行用同一组统计。

```dart
engine.setEventHandler(SyRtcEventHandler(
  onNetworkQualityLevel: (uid, tx, rx) {
    if (tx == SyNetworkQualityLevel.bad || tx == SyNetworkQualityLevel.down) {
      engine.setQualityTier(SyQualityTier.sd);
    }
  },
  onRtcStats: (stats) {
    // packetLossRate 两端都是 0–1；rttMs 为毫秒
    debugPrint('${stats.uid} rtt=${stats.rttMs} loss=${stats.packetLossRate}');
  },
));
```

名字已在 Dart 层统一，阈值仍由各端原生计算：

| 统一档位 | Android 原名 / 阈值 | iOS 原名 / 阈值 |
| --- | --- | --- |
| `down` | `die`：丢包 ≥30% 或 RTT ≥1000ms | `down`：丢包 ≥50% 或 RTT ≥2000ms |
| `bad` | `bad`：≥15% 或 ≥500ms | `bad`：≥20% 或 ≥600ms |
| `poor` | `medium`：≥8% 或 ≥300ms | `poor`：≥8% 或 ≥250ms |
| `good` | `good`：≥3% 或 ≥150ms | `good`：≥2% 或 ≥100ms |
| `excellent` | 其余 | 其余 |

旧的 `onNetworkQuality` / `SyNetworkQuality` 仍按原生名字回调，只为兼容保留；原文在 `txQualityRaw` / `rxQualityRaw`。

**通话统计。** `onRtcStats` 的 `SyRtcStats` 新增 `uid`、`rttMs`、`packetLossRate`（**统一为 0–1 的比例**，Android 原生的 0–100 `lossPercent` 已除以 100）、`txBitrate` / `rxBitrate`（bit/s，仅 Android）、`quality`（统一档位）、`networkType`（仅 iOS）和原始字段 `raw`。3.2.0 起 iOS 也会回调 `onRtcStats`。

**音频路由。** 请用 `SyAudioRoute` 和 `onAudioRoute`。原生整数在 Dart 层按平台翻译（`SyAudioRoute.fromNative`），事件里的 `routing` 仍是原生整数，不要跨平台比较：Android 0 扬声器、1 耳机、2 蓝牙、3 听筒；iOS 0 耳机、1 听筒、3 扬声器、5 蓝牙、-1 未知。`setAudioRoute` 两端都只能切 `speaker` 和 `earpiece`，返回 0；耳机和蓝牙返回 -1。Android 会在设备接上且没强制扬声器时上报 `headset` / `bluetooth`。iOS 的蓝牙和有线耳机只上报，主动设置会再回调 `onError` 1004。

**设备与摄像头。** Android 采集/播放设备来自 `AudioManager`。iOS 采集设备来自 `AVAudioSession.availableInputs`，没有输入口时是空列表。iOS 播放设备只有 `speaker` 和 `earpiece`。`switchCamera` 两端都有。`useFrontCamera` 只在 iOS 生效，Android 返回 -2。

**屏幕共享。** Android 先弹出 MediaProjection 授权，同意后帧进本地视频轨；返回 0 表示已启动，-1 表示拒绝或失败。SDK 没有 `mediaProjection` 前台服务，Android 10 及以上可能还要宿主自己声明。iOS 是应用内 ReplayKit，帧进 WebRTC；返回 0 只表示调用已发出，失败走 `onError` 1008。这不是跨进程的 Broadcast Extension。

**静音。** `isLocalAudioMuted` / `isLocalVideoMuted` 读原生状态。`isRemoteAudioMuted` / `isRemoteVideoMuted` 只在 Android 有结果，iOS 返回 null。iOS 另有 `onUserMuteVideo`；Android 的远端视频静音走 `onRemoteVideoStateChanged`。

**数据与附加信息。** `createDataStream` / `sendStreamMessage` 两端都走 DataChannel。`sendSei` 只在 Android 存在：DataChannel 消息，带 `SYSEI` 前缀，不是码流 SEI；iOS 返回 -2。`setStreamExtraInfo` 走频道信令。Android 未进房返回 -1；iOS 没有返回值，插件在引擎存在时返回 0。`getStreamExtraInfo` 只在 iOS 有值，Android 返回 null。

**自定义采集。** `enableCustomVideoCapture(true)` 会停掉摄像头。送帧仍是原生类型：Android `org.webrtc.VideoFrame`，iOS `CVPixelBuffer`。方法通道不接收像素，避免假装帧已经进编码器。美颜提亮仍用 `setBeautyEffectOptions`。自定义帧处理器同样是原生钩子，不会把帧回调到 Dart。

**重连。** 听 `onConnectionStateChanged` 的 `nativeReason`，以及 `onRejoinChannelSuccess`。Android 信令最多再试 3 次，用尽后 `onError` 1003；ICE 会 `restartIce`，恢复后重进房回调。iOS 信令按 1、2、4、8、16 秒退避，最多 5 次，用尽后 `nativeReason` 为 `signaling_give_up`，`onError` 1005。

**网络类型。** `getNetworkType` 在 iOS 上可能是 `wifi`、`cellular`、`ethernet`、`none`、`unknown`（进房后才开始监视）。Android 3.2.0 的同名方法固定返回 `unknown`。

## 示例

```bash
cd example
flutter pub get
flutter run
```

示例默认请求 `https://syrtcapi.shengyuchenyao.cn`。覆盖地址：

```bash
flutter run --dart-define=SY_API_BASE=https://your-api.example
```

页面上可以初始化、拉取 Token、加入/离开、静音、打开视频、续期 Token，以及在语音/标清/高清/超清之间切换。

## 发布到 pub.dev（维护者）

客户要写的那一行是：

```yaml
sy_rtc_flutter_sdk: ^3.2.0
```

发布前：

1. 先发布原生 Android tag `v3.2.0`，确认 JitPack 能解析 `com.github.carlcy:sy-rtc-android-sdk:v3.2.0`，再发 Flutter 包。插件已经写成这个坐标。
2. iOS 目标是 `SyRtcSDK` 3.2.0。trunk 还没有这个 pod，所以插件继续编译内置源码，WebRTC 依赖 `WebRTC-SDK` `125.6422.07`。推送步骤在 [sy-rtc-ios-sdk 的发布说明](https://github.com/carlcy/sy-rtc-ios-sdk/blob/main/PUBLISH_GUIDE.md)：`pod trunk register` → `pod lib lint SyRtcSDK.podspec` → `pod trunk push SyRtcSDK.podspec`。trunk 上出现 3.2.0 后，把 podspec 改成 `s.dependency 'SyRtcSDK', '3.2.0'`，删除 `ios/SyRtcSDK`，并在插件 Swift 里 `import SyRtcSDK`。在那之前不要让客户自己再 `pod 'SyRtcSDK'`。
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
git tag v3.2.0
git push origin v3.2.0
```

`dart pub publish` 会带上 `example/`。example 继续使用 `path: ../`，这是 pub.dev 对插件示例的常规写法。

## 常见问题

**初始化或进房失败。** 核对 AppId、Token 是否过期、麦克风/摄像头是否已授权。Token 必须来自业务服务器。

**Android 构建找不到 `com.github.carlcy:sy-rtc-android-sdk`。** 宿主仓库列表里没有 `https://jitpack.io`。不要改回本地 AAR。

**iOS 模拟器黑屏。** 模拟器通常没有摄像头。用真机看 `SyRtcVideoView`。

**没有声音。** 依次 `enableLocalAudio(true)`、`muteLocalAudio(false)`、`setClientRole('host')`。

## 许可证

MIT License
