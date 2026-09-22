# SY RTC Flutter Example

验证 UI：配置、权限、加入/离开、静音、**真实本地/远端视频 PlatformView**。

默认对接本地 Go 后端 `rtc-backend-go`（`:8080`）：

| | iOS 模拟器 | Android 模拟器 | 真机 |
|--|-----------|----------------|------|
| API | `http://127.0.0.1:8080` | `http://10.0.2.2:8080` | 电脑局域网 IP，如 `http://192.168.x.x:8080` |
| 信令 | `ws://127.0.0.1:8080/ws/signaling` | `ws://10.0.2.2:8080/ws/signaling` | 同样改 host |
| Token | `POST /api/rtc/token?channelId&uid` + `X-App-Id` / `X-App-Secret` | 同左 | 同左 |

## 运行

```bash
# 先启动 Go 后端
cd ../../rtc-backend-go && make run   # :8080

cd ../sy_rtc_flutter_sdk/example
flutter pub get
flutter run            # 选择 iOS 模拟器或 Android 模拟器
flutter run -d <id>    # 真机（推荐验证摄像头画面）
```

填写控制台里的 **AppId / AppSecret**（应用需开通 RTC 产品）。

## 能力

- 请求麦克风 / 摄像头权限
- 初始化 SDK（apiBase + signaling）
- 加入 / 离开频道
- 静音 / 取消静音
- **启用视频**：`SyRtcVideoView`（`AndroidView` / `UiKitView`，viewType=`sy_rtc_flutter_sdk/video_view`）
  - 本地：`onPlatformViewCreated` → `setupLocalVideo(viewId)` → 原生 `SurfaceViewRenderer` / `RTCMTLVideoView`
  - 远端：用户加入后重建远端 `SyRtcVideoView(uid:)` → `setupRemoteVideo`

## 模拟器 vs 真机

- **模拟器**：信令与 Token 可用；麦克风不稳定；**摄像头通常没有**（PlatformView 黑屏属正常）。
- **真机**：完整音视频画面。iOS Info.plist 已含麦克风/摄像头说明；Android Manifest 已声明权限与 cleartext。

## 权限

- iOS：`example/ios/Runner/Info.plist`
- Android：`example/android/app/src/main/AndroidManifest.xml`（含 cleartext 以便 http://127.0.0.1:8080）
