import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

Future<void> _emit(String method, Object? args) async {
  const codec = StandardMethodCodec();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    'sy_rtc_flutter_sdk/events',
    codec.encodeMethodCall(MethodCall(method, args)),
    (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native quality names map to one level enum', () {
    const cases = {
      'excellent': SyNetworkQualityLevel.excellent,
      'good': SyNetworkQualityLevel.good,
      'medium': SyNetworkQualityLevel.poor, // Android
      'poor': SyNetworkQualityLevel.poor, // iOS
      'bad': SyNetworkQualityLevel.bad,
      'die': SyNetworkQualityLevel.down, // Android
      'down': SyNetworkQualityLevel.down, // iOS
      'unknown': SyNetworkQualityLevel.unknown,
      'garbage': SyNetworkQualityLevel.unknown,
    };
    cases.forEach((raw, level) {
      expect(SyNetworkQualityLevel.fromNative(raw), level, reason: raw);
    });
    expect(SyNetworkQualityLevel.fromNative(null), SyNetworkQualityLevel.unknown);
  });

  test('packet loss is normalized to 0-1 on both platforms', () {
    final android = SyRtcStats.fromMap(<Object?, Object?>{
      'uid': 'u2',
      'quality': 'medium',
      'rttMs': 120,
      'lossPercent': 5.0,
      'txBitrate': 300000,
      'rxBitrate': 280000,
    });
    expect(android.packetLossRate, closeTo(0.05, 1e-9));
    expect(android.rttMs, 120);
    expect(android.quality, SyNetworkQualityLevel.poor);
    expect(android.txBitrate, 300000);
    expect(android.uid, 'u2');
    expect(android.raw['lossPercent'], 5.0);

    final ios = SyRtcStats.fromMap(<Object?, Object?>{
      'networkType': 'wifi',
      'uid': 'u3',
      'quality': 'down',
      'rttMs': 88.6,
      'packetLoss': 0.05,
    });
    expect(ios.packetLossRate, closeTo(0.05, 1e-9));
    expect(ios.rttMs, 89);
    expect(ios.quality, SyNetworkQualityLevel.down);
    expect(ios.networkType, 'wifi');

    expect(SyRtcStats.fromMap(<Object?, Object?>{'lossPercent': 250}).packetLossRate, 1.0);
    expect(SyRtcStats.fromMap(<Object?, Object?>{}).packetLossRate, isNull);
  });

  test('audio route ints are translated per platform in Dart', () {
    expect(
      SyAudioRoute.fromNative(routing: 0, platform: TargetPlatform.android),
      SyAudioRoute.speaker,
    );
    expect(
      SyAudioRoute.fromNative(routing: 3, platform: TargetPlatform.android),
      SyAudioRoute.earpiece,
    );
    expect(
      SyAudioRoute.fromNative(routing: 0, platform: TargetPlatform.iOS),
      SyAudioRoute.headset,
    );
    expect(
      SyAudioRoute.fromNative(routing: 3, platform: TargetPlatform.iOS),
      SyAudioRoute.speaker,
    );
    expect(
      SyAudioRoute.fromNative(routing: 5, platform: TargetPlatform.iOS),
      SyAudioRoute.bluetooth,
    );
    expect(
      SyAudioRoute.fromNative(routing: -1, platform: TargetPlatform.iOS),
      SyAudioRoute.unknown,
    );
    // A valid native name wins over the int.
    expect(
      SyAudioRoute.fromNative(
          name: 'bluetooth', routing: 0, platform: TargetPlatform.android),
      SyAudioRoute.bluetooth,
    );
  });

  test('engine forwards unified quality, stats and route events', () async {
    final levels = <SyNetworkQualityLevel>[];
    final stats = <SyRtcStats>[];
    final routes = <SyAudioRoute>[];
    const channel = MethodChannel('sy_rtc_flutter_sdk');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final engine = SyRtcEngine();
    await engine.init('app'); // registers the native event handler
    engine.setEventHandler(SyRtcEventHandler(
      onNetworkQualityLevel: (uid, tx, rx) => levels.add(tx),
      onRtcStats: stats.add,
      onAudioRoute: routes.add,
    ));

    await _emit('onNetworkQuality', {
      'uid': 'u2',
      'txQuality': 'die',
      'rxQuality': 'die',
    });
    await _emit('onRtcStats', {
      'stats': {'uid': 'u2', 'quality': 'good', 'lossPercent': 2.0, 'rttMs': 60},
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _emit('onAudioRoutingChanged', {'routing': 1});
    debugDefaultTargetPlatformOverride = null;

    final videoEvents = <SyLocalVideoStateChangedEvent>[];
    final sub = engine.events
        .where((e) => e is SyLocalVideoStateChangedEvent)
        .cast<SyLocalVideoStateChangedEvent>()
        .listen(videoEvents.add);
    await _emit('onLocalVideoStateChanged',
        {'state': 'screen_capturing', 'error': ''}); // Android
    await _emit('onLocalVideoStateChanged',
        {'state': 'capturing', 'error': 'screen'}); // iOS
    await _emit('onLocalVideoStateChanged',
        {'state': 'capturing', 'error': 'ok'}); // camera
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(videoEvents.map((e) => e.state),
        everyElement(SyLocalVideoStreamState.capturing));
    expect(videoEvents.map((e) => e.isScreenCapture), [true, true, false]);

    expect(levels, [SyNetworkQualityLevel.down]);
    expect(stats.single.packetLossRate, closeTo(0.02, 1e-9));
    expect(stats.single.quality, SyNetworkQualityLevel.good);
    expect(routes, [SyAudioRoute.earpiece]);
  });
}
