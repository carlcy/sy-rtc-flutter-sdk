import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('sy_rtc_flutter_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        // 基础 mock：只要不抛 MissingPluginException 即可
        switch (methodCall.method) {
          case 'init':
          case 'checkFeatures':
          case 'join':
          case 'leave':
            return true;
          case 'hasFeature':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('SyRtcEngine 单例测试', () {
    final engine1 = SyRtcEngine();
    final engine2 = SyRtcEngine();
    expect(engine1, equals(engine2));
  });

  test('初始化引擎', () async {
    final engine = SyRtcEngine();
    await engine.init('test_app_id');
    // 验证初始化成功（实际需要 mock MethodChannel）
  });

  test('加入频道', () async {
    final engine = SyRtcEngine();
    await engine.init('test_app_id');
    await engine.join('channel_001', 'user_001', 'token_here');
    // 验证加入成功（实际需要 mock MethodChannel）
  });
}
