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

目标坐标是 `pod 'SyRtcSDK', '3.2.0'`，源码仓库是 `https://github.com/carlcy/sy-rtc-ios-sdk`（tag `v3.2.0`，也有 SPM 的 `Package.swift`）。CocoaPods 的 `s.dependency` 只能解析 trunk 或 spec 仓库，不能写 git URL。trunk 上还没有 `SyRtcSDK` 3.2.0。因此插件暂时编译 `ios/SyRtcSDK` 源码，并依赖 `GoogleWebRTC`（源码是 `import WebRTC`）。

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

### 11. 还没有在原生侧完成的能力

这些 Dart API 已经接上，但当前原生实现不会给出真实结果，插件不会编造：

- **网络质量**：`onNetworkQuality` 已转发。原生回调目前是空的，流里不会出现数据。
- **音量**：`enableAudioVolumeIndication` 已转发。现有原生实现按间隔回调，音量固定为 0。
- **设备**：`enumerateRecordingDevices` 等已转发。内置 iOS 只返回占位麦克风。
- **屏幕共享**：会调用原生 `startScreenCapture`。Android 还没有系统录屏授权弹窗，iOS 的 ReplayKit 帧还没有送进视频轨。
- **静音查询**：`observedLocalAudioMuted` 只记录本端最近一次 `muteLocalAudio`，不是硬件回读。

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
2. iOS 目标是 `SyRtcSDK` 3.2.0。trunk 还没有这个 pod，所以插件继续编译内置源码。推送步骤在 [sy-rtc-ios-sdk 的发布说明](https://github.com/carlcy/sy-rtc-ios-sdk/blob/main/PUBLISH_GUIDE.md)：`pod trunk register` → `pod lib lint SyRtcSDK.podspec` → `pod trunk push SyRtcSDK.podspec`。trunk 上出现 3.2.0 后，把 podspec 改成 `s.dependency 'SyRtcSDK', '3.2.0'`，删除 `ios/SyRtcSDK`，并在插件 Swift 里 `import SyRtcSDK`。在那之前不要让客户自己再 `pod 'SyRtcSDK'`。
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
