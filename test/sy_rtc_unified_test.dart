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
    expect(
        SyNetworkQualityLevel.fromNative(null), SyNetworkQualityLevel.unknown);
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

    expect(
        SyRtcStats.fromMap(<Object?, Object?>{'lossPercent': 250})
            .packetLossRate,
        1.0);
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
      'stats': {
        'uid': 'u2',
        'quality': 'good',
        'lossPercent': 2.0,
        'rttMs': 60
      },
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

  test('cross-platform mute video and SEI events reach the handler', () async {
    const channel = MethodChannel('sy_rtc_flutter_sdk');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'sendSei' ? 0 : null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final engine = SyRtcEngine();
    await engine.init('app');
    final muted = <String>[];
    final sei = <List<int>>[];
    engine.setEventHandler(SyRtcEventHandler(
      onUserMuteVideo: (uid, m) => muted.add('$uid:$m'),
      onSeiMessage: (uid, streamId, data) => sei.add(data),
    ));
    await _emit('onUserMuteVideo', {'uid': 'u2', 'muted': true});
    // Android sends List<int>, iOS sends [UInt8] (also a list on the Dart side).
    await _emit('onSeiMessage', {
      'uid': 'u2',
      'streamId': 1,
      'data': [1, 2, 3],
    });
    expect(muted, ['u2:true']);
    expect(sei, [
      [1, 2, 3]
    ]);
    expect(await engine.sendSei(1, Uint8List.fromList([9])), 0);
    expect(calls.last.method, 'sendSei');
    expect(calls.last.arguments['streamId'], 1);
  });

  test('reconnect events and unified connection reasons', () async {
    const channel = MethodChannel('sy_rtc_flutter_sdk');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final engine = SyRtcEngine();
    await engine.init('app');
    final log = <String>[];
    final reasons = <SyConnectionChangedReason>[];
    engine.setEventHandler(SyRtcEventHandler(
      onReconnecting: (e) =>
          log.add('ing:${e.reason}:${e.attempt}/${e.maxAttempts}:${e.delayMs}'),
      onReconnected: (r) => log.add('ok:$r'),
      onReconnectFailed: (r) => log.add('fail:$r'),
      onConnectionStateChanged: (state, reason) => reasons.add(reason),
    ));
    await _emit('onReconnecting',
        {'reason': 'ice', 'attempt': 2, 'maxAttempts': 5, 'delayMs': 2000});
    await _emit('onReconnected', {'reason': 'ice'});
    await _emit('onReconnectFailed', {'reason': 'signaling'});
    for (final r in [
      'joining',
      'join_success',
      'signaling',
      'rejoin_success',
      'leave'
    ]) {
      await _emit(
          'onConnectionStateChanged', {'state': 'connected', 'reason': r});
    }
    expect(log, ['ing:ice:2/5:2000', 'ok:ice', 'fail:signaling']);
    expect(reasons, [
      SyConnectionChangedReason.connecting,
      SyConnectionChangedReason.joinSuccess,
      SyConnectionChangedReason.interrupt,
      SyConnectionChangedReason.rejoinSuccess,
      SyConnectionChangedReason.leaveChannel,
    ]);
    expect(SyReconnectPolicy.delaysMs, [1000, 2000, 4000, 8000, 16000]);
  });

  test('error codes are the unified cross-platform values', () async {
    expect(SyRtcErrorCode.invalidArgument, 1000);
    expect(SyRtcErrorCode.signaling, 1002);
    expect(SyRtcErrorCode.reconnectFailed, 1003);
    expect(SyRtcErrorCode.kicked, 1004);
    expect(SyRtcErrorCode.camera, 1005);
    expect(SyRtcErrorCode.screenShare, 1006);
    expect(SyRtcErrorCode.customCapture, 1007);
    expect(SyRtcErrorCode.audioRoute, 1009);
    expect(SyRtcErrorCode.forbidden, 403);
    expect(SyRtcErrorCode.isCredentialBlocked(4032), isTrue);
    expect(SyRtcErrorCode.isCredentialBlocked(1004), isFalse);

    const channel = MethodChannel('sy_rtc_flutter_sdk');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final engine = SyRtcEngine();
    await engine.init('app');
    final errors = <int>[];
    final tokenErrors = <SyTokenBusinessCode>[];
    engine.setEventHandler(SyRtcEventHandler(
      onError: (code, _) => errors.add(code),
      onTokenError: (code, _) => tokenErrors.add(code),
    ));
    await _emit('onError', {'errCode': 4032, 'errMsg': '访问凭证已吊销'});
    await _emit('onError', {'errCode': SyRtcErrorCode.kicked, 'errMsg': 'kicked'});
    expect(errors, [4032, 1004]);
    expect(tokenErrors, [SyTokenBusinessCode.revoked]);
  });
}
