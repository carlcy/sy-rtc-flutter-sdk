import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recording config maps codec / quality / mix flags for native', () {
    final m = SyAudioRecordingConfiguration(
      filePath: '/tmp/a.wav',
      codecType: SyAudioCodecType.wav,
      quality: SyAudioRecordingQuality.high,
      includeRemote: false,
    ).toMap();
    expect(m['codecType'], 'wav');
    expect(m['quality'], 'high');
    expect(m['includeLocal'], true);
    expect(m['includeRemote'], false);
    expect(SyAudioRecordingConfiguration(filePath: 'x').toMap()['codecType'], 'aacLc');
  });

  test('startAudioRecording returns native result', () async {
    const channel = MethodChannel('sy_rtc_flutter_sdk');
    Map<dynamic, dynamic>? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'startAudioRecording') {
        sent = call.arguments as Map;
        return sent!['codecType'] == 'wav' ? 0 : -1;
      }
      return null;
    });
    final engine = SyRtcEngine();
    expect(await engine.startAudioRecording(
        SyAudioRecordingConfiguration(filePath: '/tmp/a.wav', codecType: SyAudioCodecType.wav)), 0);
    expect(sent!['includeRemote'], true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
