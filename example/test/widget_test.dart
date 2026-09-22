import 'package:flutter_test/flutter_test.dart';
import 'package:sy_rtc_flutter_sdk_example/main.dart';

void main() {
  testWidgets('verification UI loads', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('SY RTC'), findsWidgets);
    expect(find.text('初始化'), findsOneWidget);
    expect(find.text('加入'), findsOneWidget);
  });
}
