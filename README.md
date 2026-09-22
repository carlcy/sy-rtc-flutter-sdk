# SY RTC Flutter SDK

[![pub package](https://img.shields.io/pub/v/sy_rtc_flutter_sdk.svg)](https://pub.dev/packages/sy_rtc_flutter_sdk)

**当前版本**: 3.1.0

SY RTC Flutter SDK 是一个用于实时音视频通信的 Flutter 插件，提供简洁易用的 API 接口。

## ⚠️ 重要提示

- **Android**：需要配置原生 Android SDK 依赖（JitPack）。
- **iOS**：已在插件内置 iOS 端实现并通过 CocoaPods 自动集成（无需你手动在 Xcode 里加 SPM/Pod 依赖）。

## ✨ 特性

- ✅ **跨平台**：支持 Android 和 iOS
- ✅ **简单易用**：API 设计简洁，易于集成和使用
- ✅ **完整功能**：支持房间管理、音频控制、事件监听等核心功能

## 📦 安装

### 步骤一：配置原生 SDK 依赖

#### Android 端配置

在项目的根目录 `android/build.gradle` 中添加 JitPack 仓库：

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }  // 添加 JitPack 仓库
    }
}
```

在 `android/app/build.gradle` 中添加 Android SDK 依赖：

```gradle
dependencies {
    // Android SDK（从 JitPack）
    implementation 'com.github.carlcy:sy-rtc-android-sdk:v3.1.0'
}
```

#### iOS 端配置

无需额外配置。插件 iOS 端会通过 CocoaPods 自动集成所需依赖（最低 iOS 版本 **13.0**）。

### 步骤二：安装 Flutter SDK

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  sy_rtc_flutter_sdk: ^3.1.0
```

然后运行：

```bash
flutter pub get
```

### 方式二：从 Git 安装

```yaml
dependencies:
  sy_rtc_flutter_sdk:
    git:
      url: https://github.com/carlcy/sy_rtc_flutter_sdk.git
      ref: main
```

## 🚀 快速开始

### 1. 导入包

```dart
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
```

### 2. 创建引擎实例

```dart
final engine = SyRtcEngine();
```

### 3. 初始化引擎

```dart
// 方式一：仅初始化（默认只有语聊功能）
await engine.init('your_app_id');

// 方式二：初始化并查询功能权限（推荐）
await engine.init(
  'your_app_id',
  apiBaseUrl: 'https://api.example.com', // 您的API基础URL
);
```

**功能权限说明**：
- 如果提供了 `apiBaseUrl`，SDK 会自动查询 AppId 的功能权限
- 开通了 `rtc` 产品的 AppId 可使用音视频（含实时视频）
- 默认按 `rtc` 产品位校验；IM 为独立 SDK

### 4. 设置事件监听

```dart
// 监听用户加入
engine.onUserJoined.listen((event) {
  print('用户加入: ${event.uid}, 耗时: ${event.elapsed}ms');
});

// 监听用户离开
engine.onUserOffline.listen((event) {
  print('用户离开: ${event.uid}, 原因: ${event.reason}');
});

// 监听音量指示
engine.onVolumeIndication.listen((event) {
  event.speakers.forEach((info) {
    print('用户 ${info.uid} 音量: ${info.volume}');
  });
});
```

### 5. 加入房间

```dart
// 先从服务器获取 Token（不能在前端直接生成）
String token = await getTokenFromServer(appId, channelId, uid);

// 加入房间
await engine.join(
  channelId: 'channel_001',
  uid: 'user_001',
  token: token,
);
```

### 5.1 设置后端 API 认证 Token

```dart
// 用于调用需要登录认证的后端业务接口（与 join 的 RTC Token 不同）
await engine.setApiAuthToken(jwt);
```

**房间列表与在线人数（对标声网）**：业务后端可调用以下接口供客户端展示房间列表、统计与热度：
- `GET /api/room/active`（Header: X-App-Id）— 活跃房间列表，含 `currentSeats`、`maxSeats`、`heat`
- `GET /api/room/statistics`（Header: X-App-Id）— 总房间数、活跃数、当前在线总人数
- `GET /api/room/{channelId}/online-count` — 指定频道当前在线人数（无需加入频道即可查询）

### 6. 检查功能权限

```dart
// 检查是否开通了 RTC 产品（音视频一体）
if (await engine.hasRtcFeature()) {
  await engine.enableLocalAudio(true);
  await engine.enableVideo();
  await engine.startPreview();
} else {
  print('当前 AppId 未开通 RTC 产品');
}
```

### 7. 控制音频

```dart
// 启用本地音频
await engine.enableLocalAudio(true);

// 静音
await engine.muteLocalAudio(true);

// 取消静音
await engine.muteLocalAudio(false);
```

### 7. 设置客户端角色

```dart
// 设置为主播（可以说话）
await engine.setClientRole('host');

// 设置为观众（只能听）
await engine.setClientRole('audience');
```

### 8. 离开房间

```dart
await engine.leave();
```

### 9. 释放资源

```dart
engine.dispose();
```

## 📖 完整示例

```dart
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

class RtcPage extends StatefulWidget {
  @override
  _RtcPageState createState() => _RtcPageState();
}

class _RtcPageState extends State<RtcPage> {
  late SyRtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engine = SyRtcEngine();
    
    // 初始化
    await _engine.init('your_app_id');
    
    // 设置事件监听
    _engine.onUserJoined.listen((event) {
      print('用户加入: ${event.uid}');
    });
    
    _engine.onUserOffline.listen((event) {
      print('用户离开: ${event.uid}');
    });
  }

  Future<void> _joinChannel() async {
    try {
      // 从服务器获取 Token
      String token = await _getTokenFromServer();
      
      await _engine.join(
        channelId: 'channel_001',
        uid: 'user_001',
        token: token,
      );
      
      setState(() {
        _isJoined = true;
      });
      
      // 启用本地音频
      await _engine.enableLocalAudio(true);
    } catch (e) {
      print('加入房间失败: $e');
    }
  }

  Future<void> _leaveChannel() async {
    await _engine.leave();
    setState(() {
      _isJoined = false;
    });
  }

  Future<void> _toggleMute() async {
    await _engine.muteLocalAudio(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RTC 房间')),
      body: Column(
        children: [
          if (!_isJoined)
            ElevatedButton(
              onPressed: _joinChannel,
              child: Text('加入房间'),
            )
          else ...[
            ElevatedButton(
              onPressed: _leaveChannel,
              child: Text('离开房间'),
            ),
            ElevatedButton(
              onPressed: _toggleMute,
              child: Text(_isMuted ? '取消静音' : '静音'),
            ),
          ],
        ],
      ),
    );
  }
}
```

## 🔧 权限配置

### Android

**无需手动配置！** Flutter 插件会自动处理权限。

如果遇到权限问题，检查 `android/app/src/main/AndroidManifest.xml` 是否包含：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS

**无需手动配置！** Flutter 插件会自动处理权限。

如果遇到权限问题，检查 `ios/Runner/Info.plist` 是否包含：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限进行语音通话</string>
```

## 📚 API 文档

### SyRtcEngine

#### 初始化

```dart
Future<void> init(String appId, {String? apiBaseUrl, String? signalingUrl})
```

初始化 RTC 引擎。

**参数：**
- `appId`: 应用ID，从用户后台获取

**示例：**
```dart
await engine.init(
  'your_app_id',
  apiBaseUrl: 'https://api.example.com',
  signalingUrl: 'wss://syrtcapi.shengyuchenyao.cn/ws/signaling',
);
```

#### 加入房间

```dart
Future<void> join({
  required String channelId,
  required String uid,
  required String token,
})
```

加入语音房间。

**参数：**
- `channelId`: 房间ID
- `uid`: 用户ID（字符串类型）
- `token`: 鉴权Token（从服务器获取，不能在前端生成）

**示例：**
```dart
await engine.join(
  channelId: 'channel_001',
  uid: 'user_001',
  token: 'token_from_server',
);
```

#### 离开房间

```dart
Future<void> leave()
```

离开当前房间。

**示例：**
```dart
await engine.leave();
```

#### 启用/禁用本地音频

```dart
Future<void> enableLocalAudio(bool enabled)
```

启用或禁用本地音频采集和播放。

**参数：**
- `enabled`: `true` 为启用，`false` 为禁用

**示例：**
```dart
await engine.enableLocalAudio(true);
```

#### 静音/取消静音

```dart
Future<void> muteLocalAudio(bool muted)
```

静音或取消静音本地音频。

**参数：**
- `muted`: `true` 为静音，`false` 为取消静音

**示例：**
```dart
await engine.muteLocalAudio(true);  // 静音
await engine.muteLocalAudio(false); // 取消静音
```

#### 设置客户端角色

```dart
Future<void> setClientRole(String role)
```

设置客户端角色。

**参数：**
- `role`: `'host'` 或 `'audience'`
  - `'host'`: 主播，可以说话
  - `'audience'`: 观众，只能听

**示例：**
```dart
await engine.setClientRole('host');
```

#### 释放资源

```dart
void dispose()
```

释放引擎资源。在不再使用引擎时调用。

**示例：**
```dart
engine.dispose();
```

### 事件监听

#### 用户加入事件

```dart
Stream<SyUserJoinedEvent> get onUserJoined
```

当有用户加入房间时触发。

**事件数据：**
```dart
class SyUserJoinedEvent {
  final String uid;      // 用户ID
  final int elapsed;      // 加入耗时（毫秒）
}
```

**示例：**
```dart
engine.onUserJoined.listen((event) {
  print('用户 ${event.uid} 加入，耗时 ${event.elapsed}ms');
});
```

#### 用户离开事件

```dart
Stream<SyUserOfflineEvent> get onUserOffline
```

当有用户离开房间时触发。

**事件数据：**
```dart
class SyUserOfflineEvent {
  final String uid;      // 用户ID
  final String reason;    // 离开原因
}
```

**示例：**
```dart
engine.onUserOffline.listen((event) {
  print('用户 ${event.uid} 离开，原因: ${event.reason}');
});
```

#### 音量指示事件

```dart
Stream<SyVolumeIndicationEvent> get onVolumeIndication
```

当检测到用户音量变化时触发。

**事件数据：**
```dart
class SyVolumeIndicationEvent {
  final List<VolumeInfo> speakers;  // 说话者列表
}

class VolumeInfo {
  final String uid;      // 用户ID
  final int volume;      // 音量（0-255）
}
```

**示例：**
```dart
engine.onVolumeIndication.listen((event) {
  event.speakers.forEach((info) {
    print('用户 ${info.uid} 音量: ${info.volume}');
  });
});
```

## 🔑 如何获取 Token？

**重要**：Token 必须从服务器获取，不能在前端直接生成！

### 推荐流程

1. **客户端请求加入房间**
   ```dart
   // 客户端代码
   final response = await http.post(
     Uri.parse('https://your-api.com/rtc/token'),
     body: {
       'appId': appId,
       'channelId': channelId,
       'uid': uid,
     },
   );
   final token = jsonDecode(response.body)['data']['token'];
   ```

2. **服务器生成 Token**
   ```java
   // 服务器代码（Java Spring Boot）
   @PostMapping("/rtc/token")
   public Result<String> generateToken(@RequestBody TokenRequest request) {
       String token = rtcService.generateToken(
           request.getAppId(),
           request.getChannelId(),
           request.getUid()
       );
       return Result.success(token);
   }
   ```

3. **客户端使用 Token 加入房间**
   ```dart
   await engine.join(
     channelId: channelId,
     uid: uid,
     token: token,
   );
   ```

## ❓ 常见问题

### 1. SDK 初始化失败？

**可能原因：**
- AppId 不正确
- 网络连接问题
- 权限未授予

**解决方法：**
- 检查 AppId 是否正确（从用户后台获取）
- 检查网络连接
- 确保已授予麦克风权限（Android/iOS 会自动请求）

### 2. 无法加入房间？

**可能原因：**
- Token 无效或已过期
- 房间不存在
- 账户余额不足

**解决方法：**
- 重新从服务器获取 Token
- 确认房间ID正确
- 检查账户余额

### 3. 没有声音？

**可能原因：**
- 本地音频未启用
- 已静音
- 角色设置为观众

**解决方法：**
```dart
// 启用本地音频
await engine.enableLocalAudio(true);

// 取消静音
await engine.muteLocalAudio(false);

// 设置为主播
await engine.setClientRole('host');
```

### 4. 如何发布到 pub.dev？

**重要**：发布前确保原生 SDK 已发布！

1. **确保原生 SDK 已发布**
   - ✅ Android SDK 已发布到 JitPack（GitHub: carlcy/sy-rtc-android-sdk, v3.1.0）
   - ✅ iOS：Flutter 插件内置并自动集成（iOS 13+）

2. **检查 pubspec.yaml**
   ```yaml
   name: sy_rtc_flutter_sdk
   description: "SY RTC Flutter SDK - A Flutter plugin for real-time audio and video communication"
   version: 3.1.0
   homepage: https://github.com/carlcy/sy_rtc_flutter_sdk
   ```

3. **运行检查**
   ```bash
   flutter pub publish --dry-run
   ```

4. **发布**
   ```bash
   flutter pub publish
   ```

**注意**：用户使用 Flutter SDK 时，需要先配置原生 SDK 依赖（参考上面的"步骤一"）。

## 📱 平台要求

- **Flutter**: >=3.3.0
- **Dart**: >=3.6.2
- **Android**: minSdk 21+ (Android 5.0)
- **iOS**: iOS 13.0+

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题，请提交 Issue 或联系开发团队。

---

**最后更新**: 2026-01-14
