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

  SyVolumeIndicationEvent({required this.speakers})
      : super('volumeIndication');
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

  /// 原生原文字符串。Android 例如 `signaling`、`ice`、`rejoined`；
  /// iOS 例如 `signaling`、`signaling_give_up`、`rejoin_success`、`ice_checking:<uid>`。
  /// [reason] 只覆盖能对上枚举名的情况，对不上时保持 [SyConnectionChangedReason.connecting]。
  final String nativeReason;

  SyConnectionStateChangedEvent({
    required this.state,
    required this.reason,
    this.nativeReason = '',
  }) : super('connectionStateChanged');
}

/// 网络质量事件
///
/// [txQuality] / [rxQuality] 由原生字符串按名字映射。两端档位和阈值不同，见 [SyNetworkQuality]。
/// 对不上的字符串记为 [SyNetworkQuality.unknown]，原文留在 [txQualityRaw] / [rxQualityRaw]。
class SyNetworkQualityEvent extends SyRtcEvent {
  final String uid;
  final SyNetworkQuality txQuality;
  final SyNetworkQuality rxQuality;
  final String txQualityRaw;
  final String rxQualityRaw;

  SyNetworkQualityEvent({
    required this.uid,
    required this.txQuality,
    required this.rxQuality,
    this.txQualityRaw = '',
    this.rxQualityRaw = '',
  }) : super('networkQuality');
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

  SyLocalVideoStateChangedEvent({
    required this.state,
    required this.error,
  }) : super('localVideoStateChanged');
}

/// 音频路由变化事件
///
/// [route] 是两端归一后的名字。[routing] 仍是原生原始整数，两端含义不同：
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

/// 播放路由。由插件把两端不同的整数翻译成同一个枚举。
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

/// iOS 远端视频静音。Android 没有这个回调，视频静音走远端视频状态。
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

  SyRtcStats({
    this.duration = 0,
    this.txBytes = 0,
    this.rxBytes = 0,
    this.txAudioBytes = 0,
    this.rxAudioBytes = 0,
    this.txVideoBytes = 0,
    this.rxVideoBytes = 0,
    this.userCount = 0,
  });

  factory SyRtcStats.fromMap(Map<String, dynamic> map) {
    return SyRtcStats(
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

  SyErrorEvent({required this.errCode, required this.errMsg})
      : super('error');
}

/// 业务后端约定的 Token 错误码。
///
/// 出现在 `POST /api/rtc/token` 的 `code`，以及信令/引擎 `onError` 的错误码。
/// 展示给用户时优先用服务端 `msg`；下面的说明只用于客户端分支。
enum SyTokenBusinessCode {
  /// 4031 Token 无效（签名错误或格式不对）。
  invalid(4031),

  /// 4032 Token 已过期。
  expired(4032),

  /// 4033 Token 权限不足（角色或画质档位不被允许）。
  privilegeDenied(4033);

  final int value;

  const SyTokenBusinessCode(this.value);

  static SyTokenBusinessCode? tryParse(int? code) {
    switch (code) {
      case 4031:
        return SyTokenBusinessCode.invalid;
      case 4032:
        return SyTokenBusinessCode.expired;
      case 4033:
        return SyTokenBusinessCode.privilegeDenied;
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
  disconnected,  // 断开连接
  connecting,    // 正在连接
  connected,     // 已连接
  reconnecting,  // 正在重连
  failed,        // 连接失败
}

/// 连接状态变化原因
enum SyConnectionChangedReason {
  connecting,      // 正在连接
  joinSuccess,     // 加入成功
  interrupt,       // 连接中断
  bannedByServer,  // 被服务器禁止
  joinFailed,      // 加入失败
  leaveChannel,    // 离开频道
  invalidAppId,    // 无效的 AppId
  invalidChannelName, // 无效的频道名
  invalidToken,    // 无效的 Token
  tokenExpired,    // Token 过期
  rejectedByServer, // 被服务器拒绝
  settingProxyServer, // 设置代理服务器
  renewingToken,   // 更新 Token
  clientIpAddressChanged, // 客户端 IP 地址变化
  keepAliveTimeout, // 保活超时
}

/// 网络质量枚举。名字与原生字符串一致，插件不把一端的档位改写成另一端。
///
/// 没有 RTT 也没有丢包样本时，两端都回调 `unknown`。
///
/// Android（丢包为 0–100 的百分比，RTT 为毫秒）：
/// `die` 丢包 ≥ 30 或 RTT ≥ 1000；`bad` ≥ 15 或 ≥ 500；
/// `medium` ≥ 8 或 ≥ 300；`good` ≥ 3 或 ≥ 150；否则 `excellent`。
///
/// iOS（丢包为 0–1 的比例，RTT 为毫秒）：
/// `down` 丢包 ≥ 0.5 或 RTT ≥ 2000；`bad` ≥ 0.2 或 ≥ 600；
/// `poor` ≥ 0.08 或 ≥ 250；`good` ≥ 0.02 或 ≥ 100；否则 `excellent`。
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
  stopped,    // 停止
  starting,   // 开始
  decoding,   // 解码中
  failed,     // 失败
  frozen,     // 冻结
}

/// 远端音频状态原因
enum SyRemoteAudioStateReason {
  internal,   // 内部原因
  networkCongestion, // 网络拥塞
  networkRecovery,    // 网络恢复
  localMuted,        // 本地静音
  localUnmuted,     // 本地取消静音
  remoteMuted,      // 远端静音
  remoteUnmuted,    // 远端取消静音
  remoteOffline,    // 远端离线
}

/// 远端视频状态
enum SyRemoteVideoState {
  stopped,    // 停止
  starting,   // 开始
  decoding,   // 解码中
  failed,     // 失败
  frozen,     // 冻结
}

/// 远端视频状态原因
enum SyRemoteVideoStateReason {
  internal,   // 内部原因
  networkCongestion, // 网络拥塞
  networkRecovery,    // 网络恢复
  localMuted,        // 本地静音
  localUnmuted,     // 本地取消静音
  remoteMuted,       // 远端静音
  remoteUnmuted,    // 远端取消静音
  remoteOffline,    // 远端离线
}

/// 本地音频流状态
enum SyLocalAudioStreamState {
  stopped,    // 停止
  recording,  // 录制中
  encoding,   // 编码中
  failed,     // 失败
}

/// 本地音频流错误
enum SyLocalAudioStreamError {
  ok,                    // 正常
  failure,               // 失败
  deviceNoPermission,    // 设备无权限
  deviceBusy,            // 设备忙碌
  recordFailure,         // 录制失败
  encodeFailure,         // 编码失败
}

/// 本地视频流状态
enum SyLocalVideoStreamState {
  stopped,    // 停止
  capturing,  // 采集中
  encoding,   // 编码中
  failed,     // 失败
}

/// 本地视频流错误
enum SyLocalVideoStreamError {
  ok,                    // 正常
  failure,               // 失败
  deviceNoPermission,    // 设备无权限
  deviceBusy,            // 设备忙碌
  captureFailure,        // 采集失败
  encodeFailure,         // 编码失败
}

/// 流发布状态
enum SyStreamPublishState {
  idle,         // 未发布
  noPublished,  // 未发布
  publishing,   // 发布中
  published,    // 已发布
}

/// 流订阅状态
enum SyStreamSubscribeState {
  idle,          // 未订阅
  noSubscribed,  // 未订阅
  subscribing,   // 订阅中
  subscribed,    // 已订阅
}
