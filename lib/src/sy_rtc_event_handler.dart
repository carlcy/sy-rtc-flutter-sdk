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

  /// 网络质量回调
  final void Function(String uid, SyNetworkQuality txQuality,
      SyNetworkQuality rxQuality)? onNetworkQuality;

  /// 通话统计信息回调（每 2 秒触发一次）
  final void Function(SyRtcStats stats)? onRtcStats;

  /// Token 即将过期回调（30秒前）
  final void Function()? onTokenPrivilegeWillExpire;

  /// Token 已过期回调
  final void Function()? onRequestToken;

  /// 音量指示回调
  final void Function(List<Map<String, dynamic>> speakers)? onVolumeIndication;

  /// 远端用户静音/取消静音回调
  final void Function(String uid, bool muted)? onUserMuteAudio;

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

  /// 视频尺寸变化回调
  final void Function(String uid, int width, int height, int rotation)?
      onVideoSizeChanged;

  /// 音频路由变化回调
  final void Function(int routing)? onAudioRoutingChanged;

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

  /// 错误回调
  final void Function(int code, String message)? onError;

  SyRtcEventHandler({
    this.onJoinChannelSuccess,
    this.onLeaveChannel,
    this.onRejoinChannelSuccess,
    this.onUserJoined,
    this.onUserOffline,
    this.onConnectionStateChanged,
    this.onNetworkQuality,
    this.onRtcStats,
    this.onTokenPrivilegeWillExpire,
    this.onRequestToken,
    this.onVolumeIndication,
    this.onUserMuteAudio,
    this.onLocalAudioStateChanged,
    this.onRemoteAudioStateChanged,
    this.onLocalVideoStateChanged,
    this.onRemoteVideoStateChanged,
    this.onFirstRemoteVideoDecoded,
    this.onFirstRemoteVideoFrame,
    this.onVideoSizeChanged,
    this.onAudioRoutingChanged,
    this.onAudioPublishStateChanged,
    this.onAudioSubscribeStateChanged,
    this.onStreamMessage,
    this.onStreamMessageError,
    this.onChannelMessage,
    this.onError,
  });
}
