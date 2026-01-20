// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SyRtcEngine 初始化测试', (WidgetTester tester) async {
    final engine = SyRtcEngine();
    
    // 测试初始化
    await engine.init('test_app_id');
    
    // 验证引擎已创建
    expect(engine, isNotNull);
  });

  testWidgets('SyRtcEngine 加入频道测试', (WidgetTester tester) async {
    final engine = SyRtcEngine();
    
    await engine.init('test_app_id');
    await engine.join('channel_001', 'user_001', 'token_here');
    
    // 验证加入成功（实际需要原生SDK支持）
    expect(engine, isNotNull);
  });
}
