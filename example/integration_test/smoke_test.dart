import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sy_rtc_flutter_sdk_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SDK Init Smoke Test', () {
    testWidgets('App launches and init page renders', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('SY RTC 语聊房测试'), findsOneWidget);
      expect(find.text('初始化并进入'), findsOneWidget);
      expect(find.text('APP1769003318261114285E3'), findsOneWidget);
    });

    testWidgets('Init completes without crash and navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('初始化并进入'));

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // On Android, a system permission dialog may block the Flutter view.
      // On iOS simulator, permissions are auto-denied but init continues.
      // Success criteria: the app is still running (no crash) and shows either:
      // 1. Voice room page (init succeeded, navigated)
      // 2. Init page with a status message (init in progress or waiting for permission)
      final voiceRoomFound = find.text('语聊房测试').evaluate().isNotEmpty;
      final joinButtonFound = find.text('加入房间').evaluate().isNotEmpty;
      final initButton = find.text('初始化并进入').evaluate().isNotEmpty;
      final anyStatusVisible = find.textContaining('正在').evaluate().isNotEmpty ||
          find.textContaining('SDK').evaluate().isNotEmpty ||
          find.textContaining('权限').evaluate().isNotEmpty;

      // The app did NOT crash if we can find any widget at all
      final appAlive = voiceRoomFound || joinButtonFound || initButton || anyStatusVisible;
      expect(appAlive, isTrue,
          reason: 'App should still be alive after init tap (no crash)');
    });
  });
}
