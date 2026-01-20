# 故障排除指南

## IDE 显示错误但代码正常

如果 IDE（VS Code / Android Studio）显示错误，但 `flutter analyze` 没有错误，这是 IDE 缓存问题。

### 解决方法：

1. **清理并重新获取依赖**：
```bash
cd sy_rtc_flutter_sdk
flutter clean
flutter pub get
```

2. **重启 IDE**：
- VS Code: 重启窗口
- Android Studio: File → Invalidate Caches / Restart

3. **重新运行分析**：
```bash
flutter analyze
```

## 常见问题

### 1. 类型推断错误

如果看到 `The getter 'uid' isn't defined` 类似的错误，确保在监听事件时明确指定类型：

```dart
// ✅ 正确
_engine.onUserJoined.listen((SyUserJoinedEvent event) {
  print(event.uid);
});

// ❌ 错误（可能在某些 IDE 中）
_engine.onUserJoined.listen((event) {
  print(event.uid); // IDE 可能无法推断类型
});
```

### 2. 导入错误

确保导入正确的包：

```dart
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
```

### 3. 方法未找到

确保使用正确的 API：

```dart
final engine = SyRtcEngine(); // 单例
await engine.init('app_id');
await engine.join('channel', 'uid', 'token');
```

## 验证代码

运行以下命令验证：

```bash
cd sy_rtc_flutter_sdk
flutter analyze
cd example
flutter analyze
```

如果都显示 "No issues found!"，说明代码没有问题。

