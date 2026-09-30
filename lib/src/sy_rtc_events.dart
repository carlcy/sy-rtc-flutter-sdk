import 'package:flutter/foundation.dart';

/// SY RTC事件基类
abstract class SyRtcEvent {
  final String type;
  SyRtcEvent(this.type);
}

/// 用户加入事件
class SyUserJoinedEvent extends SyRtcEvent {
  final String uid;
  final int elapsed;

  SyUserJoinedEvent({required this.uid, required this.elapsed})
      : super('userJoined');
}

/// 用户离开事件
class SyUserOfflineEvent extends SyRtcEvent {
  final String uid;
  final String reason;

  SyUserOfflineEvent({required this.uid, required this.reason})
      : super('userOffline');
}

/// 音量指示事件
class SyVolumeIndicationEvent extends SyRtcEvent {
  final List<Map<String, dynamic>> speakers;

  SyVolumeIndicationEvent({required this.speakers}) : super('volumeIndication');
}

/// Token 即将过期事件（30秒前）
class SyTokenPrivilegeWillExpireEvent extends SyRtcEvent {
  SyTokenPrivilegeWillExpireEvent() : super('tokenPrivilegeWillExpire');
}

/// Token 已过期事件
class SyRequestTokenEvent extends SyRtcEvent {
  SyRequestTokenEvent() : super('requestToken');
}

/// 连接状态变化事件
class SyConnectionStateChangedEvent extends SyRtcEvent {
  final SyConnectionState state;
  final SyConnectionChangedReason reason;

  /// 原生原文字符串。3.2.0 起两端相同：`joining`、`join_success`、`signaling`、`ice`、
  /// `rejoin_success`、`leaving`、`leave`。[reason] 由 [syConnectionReasonFromNative] 映射。
  final String nativeReason;

  SyConnectionStateChangedEvent({
    required this.state,
    required this.reason,
    this.nativeReason = '',
  }) : super('connectionStateChanged');
}

/// 网络质量事件
///
/// 推荐读 [txLevel] / [rxLevel]：两端统一的 [SyNetworkQualityLevel]。
///
/// [txQuality] / [rxQuality] 是按原生名字映射的旧枚举 [SyNetworkQuality]，两端名字不同，
/// 仅为兼容保留。原生原文在 [txQualityRaw] / [rxQualityRaw]。
/// 网络质量。两端每 2 秒一轮：先本端 uid（[isLocal] 为 true，质量为所有对端链路最差一档），
/// 再逐个对端。房间里没有对端时只有本端 `unknown`。
class SyNetworkQualityEvent extends SyRtcEvent {
  final String uid;

  /// uid 等于本端 [SyRtcEngine.localUid]。
  final bool isLocal;
  final SyNetworkQuality txQuality;
  final SyNetworkQuality rxQuality;
  final String txQualityRaw;
  final String rxQualityRaw;

  /// 两端统一的上行质量档位。
  final SyNetworkQualityLevel txLevel;

  /// 两端统一的下行质量档位。
  final SyNetworkQualityLevel rxLevel;

  SyNetworkQualityEvent({
    required this.uid,
    this.isLocal = false,
    required this.txQuality,
    required this.rxQuality,
    this.txQualityRaw = '',
    this.rxQualityRaw = '',
    SyNetworkQualityLevel? txLevel,
    SyNetworkQualityLevel? rxLevel,
  })  : txLevel = txLevel ?? SyNetworkQualityLevel.fromNative(txQualityRaw),
        rxLevel = rxLevel ?? SyNetworkQualityLevel.fromNative(rxQualityRaw),
        super('networkQuality');
}

/// 远端音频状态变化事件
class SyRemoteAudioStateChangedEvent extends SyRtcEvent {
  final String uid;
  final SyRemoteAudioState state;
  final SyRemoteAudioStateReason reason;
  final int elapsed;

  SyRemoteAudioStateChangedEvent({
    required this.uid,
    required this.state,
    required this.reason,
    required this.elapsed,
  }) : super('remoteAudioStateChanged');
}

/// 远端视频状态变化事件
class SyRemoteVideoStateChangedEvent extends SyRtcEvent {
  final String uid;
  final SyRemoteVideoState state;
  final SyRemoteVideoStateReason reason;
  final int elapsed;

  SyRemoteVideoStateChangedEvent({
    required this.uid,
    required this.state,
    required this.reason,
    required this.elapsed,
  }) : super('remoteVideoStateChanged');
}

/// 本地音频状态变化事件
class SyLocalAudioStateChangedEvent extends SyRtcEvent {
  final SyLocalAudioStreamState state;
  final SyLocalAudioStreamError error;

  SyLocalAudioStateChangedEvent({
    required this.state,
    required this.error,
  }) : super('localAudioStateChanged');
}

/// 本地视频状态变化事件
class SyLocalVideoStateChangedEvent extends SyRtcEvent {
  final SyLocalVideoStreamState state;
  final SyLocalVideoStreamError error;

  /// 原生原始状态字符串（Android 屏幕共享为 `screen_capturing`）。
  final String nativeState;

  /// 原生原始错误字符串（iOS 屏幕共享为 `screen`，自定义采集为 `custom`）。
  final String nativeError;

  SyLocalVideoStateChangedEvent({
    required this.state,
    required this.error,
    this.nativeState = '',
    this.nativeError = '',
  }) : super('localVideoStateChanged');

  /// 两端统一：本地视频正在采集屏幕。
  bool get isScreenCapture =>
      state == SyLocalVideoStreamState.capturing &&
      (nativeState == 'screen_capturing' || nativeError == 'screen');
}

/// 音频路由变化事件
///
/// [route] 是两端归一后的 [SyAudioRoute]（Dart 层按平台翻译，见 [SyAudioRoute.fromNative]）。
/// [routing] 仍是原生原始整数，两端含义不同：
/// Android 0 扬声器、1 耳机、2 蓝牙、3 听筒；
/// iOS 0 耳机、1 听筒、3 扬声器、5 蓝牙、-1 未知。
class SyAudioRoutingChangedEvent extends SyRtcEvent {
  final int routing;
  final SyAudioRoute route;

  SyAudioRoutingChangedEvent({
    required this.routing,
    this.route = SyAudioRoute.unknown,
  }) : super('audioRoutingChanged');
}

/// 播放路由。两端不同的原生整数在 Dart 层翻译成同一个枚举。
enum SyAudioRoute {
  speaker,
  earpiece,
  headset,
  bluetooth,
  unknown;

  static SyAudioRoute parse(String? name) {
    for (final value in SyAudioRoute.values) {
      if (value.name == name) return value;
    }
    return SyAudioRoute.unknown;
  }

  /// 把原生上报的路由翻译成统一枚举。
  ///
  /// 优先用原生附带的名字 [name]；没有或无法识别时按 [platform] 解释原始整数 [routing]：
  /// Android 0 扬声器、1 耳机、2 蓝牙、3 听筒；
  /// iOS 0 耳机、1 听筒、3 扬声器、5 蓝牙、-1 未知。
  static SyAudioRoute fromNative({
    String? name,
    int? routing,
    TargetPlatform? platform,
  }) {
    final byName = parse(name);
    if (byName != SyAudioRoute.unknown || routing == null) return byName;
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        return const {
              0: SyAudioRoute.speaker,
              1: SyAudioRoute.headset,
              2: SyAudioRoute.bluetooth,
              3: SyAudioRoute.earpiece,
            }[routing] ??
            SyAudioRoute.unknown;
      case TargetPlatform.iOS:
        return const {
              0: SyAudioRoute.headset,
              1: SyAudioRoute.earpiece,
              3: SyAudioRoute.speaker,
              5: SyAudioRoute.bluetooth,
            }[routing] ??
            SyAudioRoute.unknown;
      default:
        return SyAudioRoute.unknown;
    }
  }
}

/// 对端通过信令更新的流附加信息。同一条原文仍会先走频道消息。
class SyStreamExtraInfoEvent extends SyRtcEvent {
  final String uid;
  final String extra;

  SyStreamExtraInfoEvent({required this.uid, required this.extra})
      : super('streamExtraInfo');
}

/// Android DataChannel 上的 SEI 风格消息。不是 H.264 码流 SEI。iOS 不会发这个事件。
class SySeiMessageEvent extends SyRtcEvent {
  final String uid;
  final int streamId;
  final List<int> data;

  SySeiMessageEvent({
    required this.uid,
    required this.streamId,
    required this.data,
  }) : super('seiMessage');
}

/// 远端用户开关了自己的视频（两端互通，信令 `user-media`）。
class SyUserMuteVideoEvent extends SyRtcEvent {
  final String uid;
  final bool muted;

  SyUserMuteVideoEvent({required this.uid, required this.muted})
      : super('userMuteVideo');
}

/// 数据流消息事件
class SyStreamMessageEvent extends SyRtcEvent {
  final String uid;
  final int streamId;
  final List<int> data;

  SyStreamMessageEvent({
    required this.uid,
    required this.streamId,
    required this.data,
  }) : super('streamMessage');
}

/// 数据流消息错误事件
class SyStreamMessageErrorEvent extends SyRtcEvent {
  final String uid;
  final int streamId;
  final int code;
  final int missed;
  final int cached;

  SyStreamMessageErrorEvent({
    required this.uid,
    required this.streamId,
    required this.code,
    required this.missed,
    required this.cached,
  }) : super('streamMessageError');
}

/// 加入频道成功事件
class SyJoinChannelSuccessEvent extends SyRtcEvent {
  final String channelId;
  final String uid;
  final int elapsed;

  SyJoinChannelSuccessEvent({
    required this.channelId,
    required this.uid,
    required this.elapsed,
  }) : super('joinChannelSuccess');
}

/// 离开频道事件
class SyLeaveChannelEvent extends SyRtcEvent {
  final SyRtcStats stats;

  SyLeaveChannelEvent({required this.stats}) : super('leaveChannel');
}

/// 重新加入频道成功事件
class SyRejoinChannelSuccessEvent extends SyRtcEvent {
  final String channelId;
  final String uid;
  final int elapsed;

  SyRejoinChannelSuccessEvent({
    required this.channelId,
    required this.uid,
    required this.elapsed,
  }) : super('rejoinChannelSuccess');
}

/// 通话统计信息事件
class SyRtcStatsEvent extends SyRtcEvent {
  final SyRtcStats stats;

  SyRtcStatsEvent({required this.stats}) : super('rtcStats');
}

/// 通话统计数据
class SyRtcStats {
  final int duration;
  final int txBytes;
  final int rxBytes;
  final int txAudioBytes;
  final int rxAudioBytes;
  final int txVideoBytes;
  final int rxVideoBytes;
  final int userCount;

  /// 统计所属的远端 uid（两端都是每个对端一条）。
  final String? uid;

  /// 往返时延，毫秒。没有样本时为 null。
  final int? rttMs;

  /// 丢包率，统一为 0–1 的比例（0.05 表示 5%）。
  ///
  /// Android 原生给的是 0–100 的 `lossPercent`，iOS 给的是 0–1 的 `packetLoss`，
  /// 这里已换算。没有样本时为 null。
  final double? packetLossRate;

  /// 发送 / 接收码率，bit/s（目前只有 Android 上报）。
  final int? txBitrate;
  final int? rxBitrate;

  /// 两端统一的质量档位（[txQuality] 与 [rxQuality] 中较差的一档）。
  /// 原生没带档位时为 [SyNetworkQualityLevel.unknown]。
  final SyNetworkQualityLevel quality;

  /// 上行档位：RTT + 上行丢包（对端回报的 remote-inbound-rtp）。
  final SyNetworkQualityLevel txQuality;

  /// 下行档位：本统计周期的下行丢包 + 抖动。
  final SyNetworkQualityLevel rxQuality;

  /// 上行丢包率（0–1），来自对端回报。没有样本时为 null。
  final double? txPacketLossRate;

  /// 下行丢包率（0–1），按本统计周期的增量计算。没有新包时为 null。
  final double? rxPacketLossRate;

  /// 下行抖动，毫秒。没有样本时为 null。
  final double? jitterMs;

  /// 网络类型（目前只有 iOS 在统计里附带：wifi / cellular / ethernet / none）。
  final String? networkType;

  /// 原生原始字段，便于排查。
  final Map<String, Object?> raw;

  SyRtcStats({
    this.duration = 0,
    this.txBytes = 0,
    this.rxBytes = 0,
    this.txAudioBytes = 0,
    this.rxAudioBytes = 0,
    this.txVideoBytes = 0,
    this.rxVideoBytes = 0,
    this.userCount = 0,
    this.uid,
    this.rttMs,
    this.packetLossRate,
    this.txBitrate,
    this.rxBitrate,
    this.quality = SyNetworkQualityLevel.unknown,
    this.txQuality = SyNetworkQualityLevel.unknown,
    this.rxQuality = SyNetworkQualityLevel.unknown,
    this.txPacketLossRate,
    this.rxPacketLossRate,
    this.jitterMs,
    this.networkType,
    this.raw = const {},
  });

  /// 丢包字段换算成 0–1。`packetLossRate` 视为已是比例；
  /// `lossPercent`（Android）按百分比除以 100；`packetLoss`（iOS）是比例。
  static double? normalizePacketLoss(Map<Object?, Object?> map) {
    double? value;
    final rate = map['packetLossRate'];
    final percent = map['lossPercent'];
    final ratio = map['packetLoss'];
    if (rate is num) {
      value = rate.toDouble();
    } else if (percent is num) {
      value = percent.toDouble() / 100.0;
    } else if (ratio is num) {
      value = ratio.toDouble();
    }
    if (value == null || value.isNaN) return null;
    return value.clamp(0.0, 1.0).toDouble();
  }

  static double? _ratio(Object? v) {
    if (v is! num) return null;
    final d = v.toDouble();
    if (d.isNaN) return null;
    return d.clamp(0.0, 1.0).toDouble();
  }

  factory SyRtcStats.fromMap(Map<Object?, Object?> map) {
    final raw = <String, Object?>{
      for (final entry in map.entries) '${entry.key}': entry.value,
    };
    return SyRtcStats(
      uid: map['uid'] as String?,
      rttMs: (map['rttMs'] as num?)?.round(),
      packetLossRate: normalizePacketLoss(map),
      txBitrate: (map['txBitrate'] as num?)?.toInt(),
      rxBitrate: (map['rxBitrate'] as num?)?.toInt(),
      quality: SyNetworkQualityLevel.fromNative(map['quality'] as String?),
      txQuality: SyNetworkQualityLevel.fromNative(map['txQuality'] as String?),
      rxQuality: SyNetworkQualityLevel.fromNative(map['rxQuality'] as String?),
      txPacketLossRate: _ratio(map['txPacketLossRate']),
      rxPacketLossRate: _ratio(map['rxPacketLossRate']),
      jitterMs: (map['jitterMs'] as num?)?.toDouble(),
      networkType: map['networkType'] as String?,
      raw: raw,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      txBytes: (map['txBytes'] as num?)?.toInt() ?? 0,
      rxBytes: (map['rxBytes'] as num?)?.toInt() ?? 0,
      txAudioBytes: (map['txAudioBytes'] as num?)?.toInt() ?? 0,
      rxAudioBytes: (map['rxAudioBytes'] as num?)?.toInt() ?? 0,
      txVideoBytes: (map['txVideoBytes'] as num?)?.toInt() ?? 0,
      rxVideoBytes: (map['rxVideoBytes'] as num?)?.toInt() ?? 0,
      userCount: (map['userCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 音频发布状态变化事件
class SyAudioPublishStateChangedEvent extends SyRtcEvent {
  final String channelId;
  final SyStreamPublishState oldState;
  final SyStreamPublishState newState;
  final int elapsed;

  SyAudioPublishStateChangedEvent({
    required this.channelId,
    required this.oldState,
    required this.newState,
    required this.elapsed,
  }) : super('audioPublishStateChanged');
}

/// 音频订阅状态变化事件
class SyAudioSubscribeStateChangedEvent extends SyRtcEvent {
  final String channelId;
  final String uid;
  final SyStreamSubscribeState oldState;
  final SyStreamSubscribeState newState;
  final int elapsed;

  SyAudioSubscribeStateChangedEvent({
    required this.channelId,
    required this.uid,
    required this.oldState,
    required this.newState,
    required this.elapsed,
  }) : super('audioSubscribeStateChanged');
}

/// 远端用户静音/取消静音事件
class SyUserMuteAudioEvent extends SyRtcEvent {
  final String uid;
  final bool muted;

  SyUserMuteAudioEvent({required this.uid, required this.muted})
      : super('userMuteAudio');
}

/// 被服务端踢出房间事件（控制面信令 / poll；非 SFU 强制断流）
class SyKickedEvent extends SyRtcEvent {
  final String channelId;
  final String reason;

  SyKickedEvent({required this.channelId, required this.reason})
      : super('kicked');
}

/// 服务端静音/解静音事件（控制面 mute-audio；非 SFU ACL）
class SyServerMuteAudioEvent extends SyRtcEvent {
  final String uid;
  final bool muted;

  SyServerMuteAudioEvent({required this.uid, required this.muted})
      : super('serverMuteAudio');
}

/// 频道消息事件（原始消息）
class SyChannelMessageEvent extends SyRtcEvent {
  final String uid;
  final String message;

  SyChannelMessageEvent({
    required this.uid,
    required this.message,
  }) : super('channelMessage');
}

/// 首帧远端视频解码事件
class SyFirstRemoteVideoDecodedEvent extends SyRtcEvent {
  final String uid;
  final int width;
  final int height;
  final int elapsed;

  SyFirstRemoteVideoDecodedEvent({
    required this.uid,
    required this.width,
    required this.height,
    required this.elapsed,
  }) : super('firstRemoteVideoDecoded');
}

/// 首帧远端视频渲染事件
class SyFirstRemoteVideoFrameEvent extends SyRtcEvent {
  final String uid;
  final int width;
  final int height;
  final int elapsed;

  SyFirstRemoteVideoFrameEvent({
    required this.uid,
    required this.width,
    required this.height,
    required this.elapsed,
  }) : super('firstRemoteVideoFrame');
}

/// 视频大小变化事件
/// 本地视频轨（摄像头、自定义采集或屏幕共享）新建后的第一帧。
class SyFirstLocalVideoFrameEvent extends SyRtcEvent {
  final int width;
  final int height;

  /// 距 join 的毫秒，join 前为 0。
  final int elapsed;

  SyFirstLocalVideoFrameEvent({
    required this.width,
    required this.height,
    required this.elapsed,
  }) : super('firstLocalVideoFrame');
}

class SyVideoSizeChangedEvent extends SyRtcEvent {
  final String uid;
  final int width;
  final int height;
  final int rotation;

  SyVideoSizeChangedEvent({
    required this.uid,
    required this.width,
    required this.height,
    required this.rotation,
  }) : super('videoSizeChanged');
}

/// 错误事件
class SyErrorEvent extends SyRtcEvent {
  final int errCode;
  final String errMsg;

  SyErrorEvent({required this.errCode, required this.errMsg}) : super('error');
}

/// `onError(code, message)` 的错误码。与 Android `RtcErrorCode`、iOS `SyRtcErrorCode` 取值相同。
///
/// 10xx 是原生 SDK 本地错误；[forbidden] 和 4031 / 4032 / 4033 与服务端 REST 业务码相同，
/// 来自信令 `kicked` / `error` 帧的 `data.code`（需要 2026-09-30 之后的服务端）。
class SyRtcErrorCode {
  SyRtcErrorCode._();

  /// 参数无效或调用时机不对（空 Token、重复 join、未知画质档位、附加信息超过 1024 字节）。
  static const int invalidArgument = 1000;

  /// 信令服务端返回的错误；message 为服务端原文。
  static const int signaling = 1002;

  /// 重连 5 次都失败，需要 leave 后重新 join。
  static const int reconnectFailed = 1003;

  /// 被房间管理踢出（同时有 `onKicked`）。凭证停用时改报 4031 / 4032 / 4033。
  static const int kicked = 1004;

  /// 摄像头打开 / 切换失败，或没有可用视频源。
  static const int camera = 1005;

  /// 屏幕共享失败。
  static const int screenShare = 1006;

  /// 自定义视频采集用法错误或视频源未就绪。
  static const int customCapture = 1007;

  /// 音频路由切换失败或不支持（目前只有 iOS 会报）。
  static const int audioRoute = 1009;

  /// 服务端拒绝入房：在踢出名单、房间锁定、不在白名单。
  static const int forbidden = 403;

  /// AppId 的访问凭证已暂停。
  static const int credentialSuspended = 4031;

  /// AppId 的访问凭证已吊销。
  static const int credentialRevoked = 4032;

  /// AppId 的访问凭证已过期。
  static const int credentialExpired = 4033;

  static bool isCredentialBlocked(int code) =>
      code == credentialSuspended ||
      code == credentialRevoked ||
      code == credentialExpired;
}

/// 访问凭证业务码（服务端 `errcode.Credential*`）。
///
/// 出现在 `POST /api/rtc/token`、`/api/rtc/token/renew` 的 `code`，以及凭证被停用时
/// 信令断开后的 `onError`。展示给用户时优先用服务端 `msg`。
enum SyTokenBusinessCode {
  /// 4031 访问凭证已暂停（管理员可恢复）。
  suspended(4031),

  /// 4032 访问凭证已吊销（不可恢复）。
  revoked(4032),

  /// 4033 访问凭证已过期。
  expired(4033);

  final int value;

  const SyTokenBusinessCode(this.value);

  /// 旧名字。4031 的真实含义是凭证已暂停。
  @Deprecated('Use SyTokenBusinessCode.suspended (4031 = credential suspended)')
  static const SyTokenBusinessCode invalid = suspended;

  /// 旧名字。4033 的真实含义是凭证已过期。
  @Deprecated('Use SyTokenBusinessCode.expired (4033 = credential expired)')
  static const SyTokenBusinessCode privilegeDenied = expired;

  static SyTokenBusinessCode? tryParse(int? code) {
    switch (code) {
      case 4031:
        return SyTokenBusinessCode.suspended;
      case 4032:
        return SyTokenBusinessCode.revoked;
      case 4033:
        return SyTokenBusinessCode.expired;
      default:
        return null;
    }
  }
}

/// Token 业务错误。仍然是 [Exception]，旧的 `on Exception` 可以接住。
class SyTokenException implements Exception {
  SyTokenException(this.code, this.message);

  final SyTokenBusinessCode code;
  final String message;

  int get businessCode => code.value;

  static SyTokenException? tryFromCode(int? code, String? message) {
    final parsed = SyTokenBusinessCode.tryParse(code);
    if (parsed == null) return null;
    final msg = (message == null || message.isEmpty) ? parsed.name : message;
    return SyTokenException(parsed, msg);
  }

  @override
  String toString() => 'SyTokenException($businessCode): $message';
}

/// Token 业务错误事件。在通用 [SyErrorEvent] 之外再发一次，方便按码分支。
class SyTokenErrorEvent extends SyRtcEvent {
  SyTokenErrorEvent({required this.code, required this.message})
      : super('tokenError');

  final SyTokenBusinessCode code;
  final String message;
}

/// 连接状态枚举
enum SyConnectionState {
  disconnected, // 断开连接
  connecting, // 正在连接
  connected, // 已连接
  reconnecting, // 正在重连
  failed, // 连接失败
}

/// 连接状态变化原因
enum SyConnectionChangedReason {
  connecting, // 正在连接
  joinSuccess, // 加入成功
  interrupt, // 连接中断
  bannedByServer, // 被服务器禁止
  joinFailed, // 加入失败
  leaveChannel, // 离开频道
  invalidAppId, // 无效的 AppId
  invalidChannelName, // 无效的频道名
  invalidToken, // 无效的 Token
  tokenExpired, // Token 过期
  rejectedByServer, // 被服务器拒绝
  settingProxyServer, // 设置代理服务器
  renewingToken, // 更新 Token
  clientIpAddressChanged, // 客户端 IP 地址变化
  keepAliveTimeout, // 保活超时
  rejoinSuccess, // 断线后重连成功（原生 `rejoin_success`）
}

/// 把原生 reason 映射到 [SyConnectionChangedReason]。两端 3.2.0 起用同一组字符串：
/// `joining` / `join_success` / `signaling` / `ice` / `rejoin_success` / `leaving` / `leave`。
SyConnectionChangedReason syConnectionReasonFromNative(String raw) {
  final base = raw.split(':').first;
  switch (base) {
    case 'joining':
    case 'join':
      return SyConnectionChangedReason.connecting;
    case 'join_success':
    case 'user-list':
      return SyConnectionChangedReason.joinSuccess;
    case 'rejoin_success':
    case 'rejoined':
      return SyConnectionChangedReason.rejoinSuccess;
    case 'signaling':
    case 'ice':
    case 'signaling_give_up':
      return SyConnectionChangedReason.interrupt;
    case 'leaving':
    case 'leave':
      return SyConnectionChangedReason.leaveChannel;
  }
  for (final value in SyConnectionChangedReason.values) {
    if (value.name == base) return value;
  }
  return SyConnectionChangedReason.connecting;
}

/// 重连策略，与 Android `ReconnectPolicy`、iOS `SyRtcReconnectPolicy` 相同（原生执行，这里只是常量）。
///
/// 信令或 ICE 断开后最多重试 [maxAttempts] 次，第 n 次等待 `2^(n-1)` 秒。
class SyReconnectPolicy {
  SyReconnectPolicy._();
  static const int maxAttempts = 5;
  static const List<int> delaysMs = [1000, 2000, 4000, 8000, 16000];
}

/// 开始第 [attempt] 次重连。[reason] 为 `signaling` 或 `ice`。
class SyReconnectingEvent extends SyRtcEvent {
  final String reason;
  final int attempt;
  final int maxAttempts;
  final int delayMs;

  SyReconnectingEvent({
    required this.reason,
    required this.attempt,
    required this.maxAttempts,
    required this.delayMs,
  }) : super('reconnecting');
}

/// 重连成功（同时也会有 `onRejoinChannelSuccess`）。
class SyReconnectedEvent extends SyRtcEvent {
  final String reason;
  SyReconnectedEvent({required this.reason}) : super('reconnected');
}

/// 重连次数用完。之后还会有 `onError(1003)`，需要 leave 后重新 join。
class SyReconnectFailedEvent extends SyRtcEvent {
  final String reason;
  SyReconnectFailedEvent({required this.reason}) : super('reconnectFailed');
}

/// 两端统一的网络质量档位（语义对齐 ZEGO `ZegoStreamQualityLevel`）。
///
/// 3.2.0 起 Android 与 iOS 原生用同一套名字和阈值（参考即构 Express 分级），
/// RTT 与丢包各自落档，取较差的一档：
///
/// | 档位 | RTT (ms) | 丢包 |
/// |---|---|---|
/// | [excellent] | < 100 | < 1% |
/// | [good] | < 200 | < 3% |
/// | [poor] | < 400 | < 8% |
/// | [bad] | < 800 | < 20% |
/// | [down] | ≥ 800 | ≥ 20% |
///
/// 没有样本时为 [unknown]。旧版 Android 的 `medium` / `die` 仍映射为 [poor] / [down]。
enum SyNetworkQualityLevel {
  unknown,
  excellent,
  good,
  poor,
  bad,
  down;

  /// 原生质量字符串 → 统一档位。无法识别时为 [unknown]。
  static SyNetworkQualityLevel fromNative(String? raw) {
    switch (raw) {
      case 'excellent':
        return SyNetworkQualityLevel.excellent;
      case 'good':
        return SyNetworkQualityLevel.good;
      case 'medium':
      case 'poor':
        return SyNetworkQualityLevel.poor;
      case 'bad':
      case 'veryBad':
        return SyNetworkQualityLevel.bad;
      case 'die':
      case 'down':
        return SyNetworkQualityLevel.down;
      default:
        return SyNetworkQualityLevel.unknown;
    }
  }
}

/// 旧的网络质量枚举，名字与原生字符串一致。新代码请用 [SyNetworkQualityLevel]。
///
/// 3.2.0 起两端原生都发 `excellent` / `good` / `poor` / `bad` / `down` / `unknown`，
/// 阈值见 [SyNetworkQualityLevel]。`medium` / `die` 只会来自旧版 Android。
///
/// 上下行目前用的是同一组统计，所以一次回调里的 tx 与 rx 相同。
/// `veryBad` 保留给旧的枚举名，当前两端原生都不会发出这个字符串。
enum SyNetworkQuality {
  unknown,
  excellent,
  good,
  medium,
  poor,
  bad,
  veryBad,
  down,
  die,
}

/// 把原生质量字符串映射成枚举。无法识别时返回 [SyNetworkQuality.unknown]。
SyNetworkQuality syNetworkQualityFromNative(String raw) {
  for (final value in SyNetworkQuality.values) {
    if (value.name == raw) return value;
  }
  return SyNetworkQuality.unknown;
}

/// 远端音频状态
enum SyRemoteAudioState {
  stopped, // 停止
  starting, // 开始
  decoding, // 解码中
  failed, // 失败
  frozen, // 冻结
}

/// 远端音频状态原因
enum SyRemoteAudioStateReason {
  internal, // 内部原因
  networkCongestion, // 网络拥塞
  networkRecovery, // 网络恢复
  localMuted, // 本地静音
  localUnmuted, // 本地取消静音
  remoteMuted, // 远端静音
  remoteUnmuted, // 远端取消静音
  remoteOffline, // 远端离线
}

/// 远端视频状态
enum SyRemoteVideoState {
  stopped, // 停止
  starting, // 开始
  decoding, // 解码中
  failed, // 失败
  frozen, // 冻结
}

/// 远端视频状态原因
enum SyRemoteVideoStateReason {
  internal, // 内部原因
  networkCongestion, // 网络拥塞
  networkRecovery, // 网络恢复
  localMuted, // 本地静音
  localUnmuted, // 本地取消静音
  remoteMuted, // 远端静音
  remoteUnmuted, // 远端取消静音
  remoteOffline, // 远端离线
}

/// 本地音频流状态
enum SyLocalAudioStreamState {
  stopped, // 停止
  recording, // 录制中
  encoding, // 编码中
  failed, // 失败
}

/// 本地音频流错误
enum SyLocalAudioStreamError {
  ok, // 正常
  failure, // 失败
  deviceNoPermission, // 设备无权限
  deviceBusy, // 设备忙碌
  recordFailure, // 录制失败
  encodeFailure, // 编码失败
}

/// 本地视频流状态
enum SyLocalVideoStreamState {
  stopped, // 停止
  capturing, // 采集中
  encoding, // 编码中
  failed, // 失败
}

/// 本地视频流错误
enum SyLocalVideoStreamError {
  ok, // 正常
  failure, // 失败
  deviceNoPermission, // 设备无权限
  deviceBusy, // 设备忙碌
  captureFailure, // 采集失败
  encodeFailure, // 编码失败
}

/// 流发布状态
enum SyStreamPublishState {
  idle, // 未发布
  noPublished, // 未发布
  publishing, // 发布中
  published, // 已发布
}

/// 流订阅状态
enum SyStreamSubscribeState {
  idle, // 未订阅
  noSubscribed, // 未订阅
  subscribing, // 订阅中
  subscribed, // 已订阅
}
