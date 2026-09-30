import 'dart:convert';

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
      if (call.method == 'isLocalAudioMuted') return true;
      if (call.method == 'isRemoteAudioMuted') return null;
      if (call.method == 'sendSei') return -2;
      if (call.method == 'setAudioRoute') {
        final route = (call.arguments as Map)['route'];
        return route == 'speaker' || route == 'earpiece' ? 0 : -1;
      }
      if (call.method == 'getAudioRoute') {
        return <String, Object>{'routing': 0, 'route': 'speaker'};
      }
      if (call.method == 'httpRequest') {
        return <String, dynamic>{'code': 0, 'data': <String, dynamic>{}};
      }
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('token business codes 4031/4032/4033', () {
    expect(SyTokenBusinessCode.tryParse(4031), SyTokenBusinessCode.suspended);
    expect(SyTokenBusinessCode.tryParse(4032), SyTokenBusinessCode.revoked);
    expect(SyTokenBusinessCode.tryParse(4033), SyTokenBusinessCode.expired);
    expect(SyTokenBusinessCode.tryParse(401), isNull);
    final error = SyTokenException.tryFromCode(4032, '过期');
    expect(error?.businessCode, 4032);
    expect(error?.message, '过期');
    expect(kSyRtcFlutterSdkVersion, '3.2.0');
  });

  test('local mute queries native state and quality switch renews token', () async {
    final engine = SyRtcEngine();
    await engine.muteLocalAudio(true);
    expect(await engine.isLocalAudioMuted(), isTrue);
    expect(await engine.isRemoteAudioMuted('u2'), isNull);
    expect(await engine.setAudioRoute(SyAudioRoute.bluetooth), -1);
    expect(await engine.setAudioRoute(SyAudioRoute.speaker), 0);
    expect(await engine.getAudioRoute(), SyAudioRoute.speaker);
    expect(await engine.sendSei(1, Uint8List.fromList([1, 2])), -2);

    await engine.switchQualityTier(tier: SyQualityTier.hd, token: 'next');
    expect(
      calls.map((call) => call.method),
      containsAll(<String>[
        'muteLocalAudio',
        'isLocalAudioMuted',
        'renewToken',
        'setVideoEncoderConfiguration',
        'setQualityTier',
      ]),
    );
    final renew = calls.lastWhere((call) => call.method == 'renewToken');
    expect((renew.arguments as Map)['token'], 'next');
    final encoder =
        calls.lastWhere((call) => call.method == 'setVideoEncoderConfiguration');
    expect((encoder.arguments as Map)['height'], 720);
  });

  test('channel meta uses user JWT and the meta path', () async {
    final room = SyRoomService(
      apiBaseUrl: 'https://api.example',
      appId: 'app',
    );
    room.setAuthToken('user-jwt');
    await room.setChannelMeta(
      channelId: 'room-1',
      key: 'title',
      value: '演示',
    );
    final call = calls.singleWhere((item) => item.method == 'httpRequest');
    final args = Map<String, dynamic>.from(call.arguments as Map);
    expect(args['url'], 'https://api.example/api/rtc/channel/meta/set');
    expect(args['method'], 'POST');
    final headers = Map<String, dynamic>.from(args['headers'] as Map);
    expect(headers['Authorization'], 'Bearer user-jwt');
    expect(jsonDecode(args['body'] as String), {
      'channelId': 'room-1',
      'key': 'title',
      'value': '演示',
    });
  });

  test('channel meta without JWT fails before the request', () async {
    final room = SyRoomService(
      apiBaseUrl: 'https://api.example',
      appId: 'app',
    );
    await expectLater(
      room.getChannelMeta(channelId: 'room-1'),
      throwsA(isA<StateError>()),
    );
    expect(calls.where((call) => call.method == 'httpRequest'), isEmpty);
  });

  test('fetchToken maps 4033 to SyTokenException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, dynamic>{
        'code': 4033,
        'msg': '访问凭证已过期',
      };
    });
    final room = SyRoomService(
      apiBaseUrl: 'https://api.example',
      appId: 'app',
    );
    room.setAuthToken('user-jwt');
    await expectLater(
      room.fetchToken(channelId: 'room-1', uid: 'u1', tier: SyQualityTier.fhd),
      throwsA(
        isA<SyTokenException>().having(
          (error) => error.businessCode,
          'businessCode',
          4033,
        ),
      ),
    );
  });
}
