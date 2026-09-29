import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('sy_rtc_flutter_sdk');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'hasFeature') return true;
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('quality tier wire values match the backend', () {
    expect(SyQualityTier.audio.wireValue, 'audio');
    expect(SyQualityTier.sd.wireValue, 'sd');
    expect(SyQualityTier.hd.wireValue, 'hd');
    expect(SyQualityTier.fhd.wireValue, 'fhd');
    expect(SyQualityTier.tryParse('FHD'), SyQualityTier.fhd);
    expect(SyQualityTier.tryParse('4k'), isNull);
    expect(SyVideoQualityPreset.standard().qualityTier, SyQualityTier.sd);
    expect(SyVideoQualityPreset.hd().qualityTier, SyQualityTier.hd);
    expect(SyVideoQualityPreset.ultraHd().qualityTier, SyQualityTier.fhd);
    expect(SyQualityTier.fhd.videoPreset?.height, 1080);
    expect(SyQualityTier.audio.videoPreset, isNull);
  });

  test('setQualityTier(sd) pushes encoder config', () async {
    final engine = SyRtcEngine();
    await engine.setQualityTier(SyQualityTier.sd);
    final encoder =
        calls.where((c) => c.method == 'setVideoEncoderConfiguration');
    expect(encoder, isNotEmpty);
    final args = encoder.last.arguments as Map;
    expect(args['width'], 854);
    expect(args['height'], 480);
  });

  test('setQualityTier(audio) disables video', () async {
    final engine = SyRtcEngine();
    await engine.setQualityTier(SyQualityTier.audio);
    expect(
      calls.map((c) => c.method),
      containsAll(['setAudioQuality', 'disableVideo']),
    );
  });

  test('renewToken forwards the new token', () async {
    final engine = SyRtcEngine();
    await engine.renewToken('next-token');
    final renew = calls.where((c) => c.method == 'renewToken').last;
    expect((renew.arguments as Map)['token'], 'next-token');
  });
}
