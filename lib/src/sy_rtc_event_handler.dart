import 'sy_rtc_events.dart';

/// SY RTC事件处理器
///
/// 参照声网/即构标准 RTC SDK 设计，包含频道、音视频、网络等核心回调。
class SyRtcEventHandler {
  /// 成功加入频道回调
  final void Function(String channelId, String uid, int elapsed)?
      onJoinChannelSuccess;

  /// 离开频道回调
  final void Function(SyRtcStats stats)? onLeaveChannel;

  /// 重新加入频道成功回调
  final void Function(String channelId, String uid, int elapsed)?
      onRejoinChannelSuccess;

  /// 远端用户加入回调
  final void Function(String uid, int elapsed)? onUserJoined;

  /// 远端用户离开回调
  final void Function(String uid, String reason)? onUserOffline;

  /// 网络连接状态变化回调
  final void Function(SyConnectionState state, SyConnectionChangedReason reason)?
      onConnectionStateChanged;

  /// 网络质量回调。
  ///
  /// 每 2 秒一轮：先本端 uid（所有对端链路最差一档），再逐个对端。两端相同。
  /// 音量无关。质量由本机 WebRTC 统计里的 RTT 和丢包算出，没有样本时为
  /// [SyNetworkQuality.unknown]。两端名字和阈值相同，见 [SyNetworkQualityLevel]。
  final void Function(String uid, SyNetworkQuality txQuality,
      SyNetworkQuality rxQuality)? onNetworkQuality;

  /// 网络质量回调（推荐）。档位两端统一，见 [SyNetworkQualityLevel]。
  ///
  /// 与 [onNetworkQuality] 同一次原生回调触发。
  final void Function(String uid, SyNetworkQualityLevel txLevel,
      SyNetworkQualityLevel rxLevel)? onNetworkQualityLevel;

  /// 通话统计信息回调。RTT、丢包（0–1）、码率与统一档位见 [SyRtcStats]。
  final void Function(SyRtcStats stats)? onRtcStats;

  /// Token 即将过期回调（30秒前）
  final void Function()? onTokenPrivilegeWillExpire;

  /// Token 已过期回调
  final void Function()? onRequestToken;

  /// 业务码 4031 / 4032 / 4033。
  ///
  /// 与 [onError] 同时触发，不替换它。
  final void Function(SyTokenBusinessCode code, String message)? onTokenError;

  /// 音量指示回调。
  ///
  /// 每个 map 含 `uid`、`volume`（0–255）、`vad`。
  /// Android 本地 uid 为 `local`，音量是 PCM RMS；`reportVad` 不产生人声标记，`vad` 恒为 0。
  /// iOS 本地 uid 是进房 uid，音量是 WebRTC `audioLevel`（0–1）乘 255；
  /// `reportVad` 为 true 且能量大于 0.02 时 `vad` 为 1，否则为 0。
  final void Function(List<Map<String, dynamic>> speakers)? onVolumeIndication;

  /// 远端用户静音/取消静音回调
  final void Function(String uid, bool muted)? onUserMuteAudio;

  /// iOS 远端视频静音。Android 不回调这个方法。
  final void Function(String uid, bool muted)? onUserMuteVideo;

  /// 本地音频状态变化回调
  final void Function(SyLocalAudioStreamState state, SyLocalAudioStreamError error)?
      onLocalAudioStateChanged;

  /// 远端音频状态变化回调
  final void Function(
          String uid, SyRemoteAudioState state, SyRemoteAudioStateReason reason, int elapsed)?
      onRemoteAudioStateChanged;

  /// 本地视频状态变化回调
  final void Function(SyLocalVideoStreamState state, SyLocalVideoStreamError error)?
      onLocalVideoStateChanged;

  /// 远端视频状态变化回调
  final void Function(
          String uid, SyRemoteVideoState state, SyRemoteVideoStateReason reason, int elapsed)?
      onRemoteVideoStateChanged;

  /// 首帧远端视频解码回调
  final void Function(String uid, int width, int height, int elapsed)?
      onFirstRemoteVideoDecoded;

  /// 首帧远端视频渲染回调
  final void Function(String uid, int width, int height, int elapsed)?
      onFirstRemoteVideoFrame;

  /// 远端视频宽、高或旋转变化（首帧也回调一次）。两端相同。
  final void Function(String uid, int width, int height, int rotation)?
      onVideoSizeChanged;

  /// 本地视频轨新建后的第一帧。两端相同。
  final void Function(int width, int height, int elapsed)?
      onFirstLocalVideoFrame;

  /// 音频路由变化回调。参数是原生原始整数，两端数值不同，见 [SyAudioRoutingChangedEvent]。
  final void Function(int routing)? onAudioRoutingChanged;

  /// 归一后的播放路由。iOS 只能主动切到扬声器或听筒。
  final void Function(SyAudioRoute route)? onAudioRoute;

  /// 音频发布状态变化回调
  final void Function(String channelId, SyStreamPublishState oldState,
      SyStreamPublishState newState, int elapsed)? onAudioPublishStateChanged;

  /// 音频订阅状态变化回调
  final void Function(String channelId, String uid,
      SyStreamSubscribeState oldState, SyStreamSubscribeState newState,
      int elapsed)? onAudioSubscribeStateChanged;

  /// 数据流消息回调
  final void Function(String uid, int streamId, List<int> data)?
      onStreamMessage;

  /// 数据流消息错误回调
  final void Function(
          String uid, int streamId, int code, int missed, int cached)?
      onStreamMessageError;

  /// 频道消息回调（底层信令通道，用于应用层自定义消息）
  final void Function(String uid, String message)? onChannelMessage;

  /// 流附加信息。同一条原文仍会先走 [onChannelMessage]。
  final void Function(String uid, String extra)? onStreamExtraInfoUpdated;

  /// `sendSei` 发来的 DataChannel 消息（已去掉 `SYSEI` 前缀），不是码流 SEI。两端都会回调。
  /// 原始字节（Android 含 `SYSEI` 前缀）仍会通过 [onStreamMessage] 给出。
  final void Function(String uid, int streamId, List<int> data)? onSeiMessage;

  /// 被服务端踢出房间（信令 type=kicked，或 poll；非 SFU 强制断流）
  final void Function(String channelId, String reason)? onKicked;

  /// 服务端静音/解静音本端或远端（mute-audio 信令 / poll）
  final void Function(String uid, bool muted)? onServerMuteAudio;

  /// 错误回调。`code` 取值见 [SyRtcErrorCode]，两端相同。
  final void Function(int code, String message)? onError;

  /// 开始重连（两端同一策略，见 [SyReconnectPolicy]）。
  final void Function(SyReconnectingEvent event)? onReconnecting;

  /// 重连成功。[reason] 为 `signaling` 或 `ice`。
  final void Function(String reason)? onReconnected;

  /// 重连次数用完，之后 `onError(1003)`。
  final void Function(String reason)? onReconnectFailed;

  SyRtcEventHandler({
    this.onJoinChannelSuccess,
    this.onLeaveChannel,
    this.onRejoinChannelSuccess,
    this.onReconnecting,
    this.onReconnected,
    this.onReconnectFailed,
    this.onUserJoined,
    this.onUserOffline,
    this.onConnectionStateChanged,
    this.onNetworkQuality,
    this.onNetworkQualityLevel,
    this.onRtcStats,
    this.onTokenPrivilegeWillExpire,
    this.onRequestToken,
    this.onTokenError,
    this.onVolumeIndication,
    this.onUserMuteAudio,
    this.onUserMuteVideo,
    this.onLocalAudioStateChanged,
    this.onRemoteAudioStateChanged,
    this.onLocalVideoStateChanged,
    this.onRemoteVideoStateChanged,
    this.onFirstRemoteVideoDecoded,
    this.onFirstRemoteVideoFrame,
    this.onVideoSizeChanged,
    this.onFirstLocalVideoFrame,
    this.onAudioRoutingChanged,
    this.onAudioRoute,
    this.onAudioPublishStateChanged,
    this.onAudioSubscribeStateChanged,
    this.onStreamMessage,
    this.onStreamMessageError,
    this.onChannelMessage,
    this.onStreamExtraInfoUpdated,
    this.onSeiMessage,
    this.onKicked,
    this.onServerMuteAudio,
    this.onError,
  });
}
