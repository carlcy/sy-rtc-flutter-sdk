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

  SyConnectionStateChangedEvent({
    required this.state,
    required this.reason,
  }) : super('connectionStateChanged');
}

/// 网络质量事件
class SyNetworkQualityEvent extends SyRtcEvent {
  final String uid;
  final SyNetworkQuality txQuality;
  final SyNetworkQuality rxQuality;

  SyNetworkQualityEvent({
    required this.uid,
    required this.txQuality,
    required this.rxQuality,
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
class SyAudioRoutingChangedEvent extends SyRtcEvent {
  final int routing;

  SyAudioRoutingChangedEvent({required this.routing})
      : super('audioRoutingChanged');
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

/// 网络质量枚举
enum SyNetworkQuality {
  unknown,   // 未知
  excellent, // 优秀
  good,      // 良好
  poor,      // 较差
  bad,       // 差
  veryBad,   // 很差
  down,      // 无法连接
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
