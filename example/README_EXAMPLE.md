# 运行 example

依赖方式见 [README.md](README.md)。这里只保留本机调试命令。

```bash
cd example
flutter pub get
flutter run
flutter run -d <deviceId>
```

默认对接 `https://syrtcapi.shengyuchenyao.cn`。本机后端用：

```bash
flutter run --dart-define=SY_API_BASE=http://127.0.0.1:8080
```

Android 模拟器访问电脑的 `127.0.0.1` 时，把地址写成 `http://10.0.2.2:8080`。

Token：`POST /api/rtc/token?channelId&uid&qualityTier`，请求头 `X-App-Id`，测试环境可加 `X-App-Secret`。

不要从下载站取 zip 来接 SDK。客户写 `sy_rtc_flutter_sdk: ^3.2.1`。
