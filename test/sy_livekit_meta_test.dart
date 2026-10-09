import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

/// LiveKit media plane: Dart only passes the meta=true JSON through; the native
/// SDKs parse it (mediaWired + sfuUrl/sfuToken) and run media on LiveKit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sy_rtc_flutter_sdk');
  final calls = <MethodCall>[];
  final metaData = {
    'token': 'sy.tok',
    'mediaWired': true,
    'sfuKind': 'livekit',
    'sfuUrl': 'wss://lk.example',
    'sfuToken': 'lk.tok',
    'sfuRoom': 'app__room-1',
    'sfuIdentity': 'u1',
    'sfuExpireAt': 1791596481,
  };

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'httpRequest') {
        final url = (call.arguments as Map)['url'] as String;
        return {
          'code': 0,
          'data': url.contains('meta=true') ? metaData : {'token': 'sy.tok'},
        };
      }
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetchToken(meta: true) returns the whole JSON, not just token', () async {
    final room = SyRoomService(apiBaseUrl: 'https://api.example', appId: 'app');
    final meta = await room.fetchToken(channelId: 'room-1', uid: 'u1', meta: true);
    expect(jsonDecode(meta), metaData);
    final plain = await room.fetchToken(channelId: 'room-1', uid: 'u1');
    expect(plain, 'sy.tok');
  });

  test('join / renewToken pass the meta JSON to native unchanged', () async {
    final engine = SyRtcEngine();
    await engine.init('app');
    final meta = jsonEncode(metaData);
    await engine.join('room-1', 'u1', meta);
    await engine.renewToken(meta);
    final join = calls.lastWhere((c) => c.method == 'join');
    expect((join.arguments as Map)['token'], meta);
    final renew = calls.lastWhere((c) => c.method == 'renewToken');
    expect((renew.arguments as Map)['token'], meta);
  });

  test('LiveKit connection reasons map to interrupt / rejoinSuccess', () {
    expect(syConnectionReasonFromNative('sfu_lost'), SyConnectionChangedReason.interrupt);
    expect(syConnectionReasonFromNative('sfu_reconnecting'), SyConnectionChangedReason.interrupt);
    expect(syConnectionReasonFromNative('sfu_reconnected'), SyConnectionChangedReason.rejoinSuccess);
  });
}
