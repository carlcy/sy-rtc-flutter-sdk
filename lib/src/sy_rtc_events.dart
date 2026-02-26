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

/// 频道消息事件（原始消息）
class SyChannelMessageEvent extends SyRtcEvent {
  final String uid;
  final String message;

  SyChannelMessageEvent({
    required this.uid,
    required this.message,
  }) : super('channelMessage');
}

// ============================================================
// 房间管理事件
// ============================================================

/// 房间信息更新事件
class SyRoomInfoUpdatedEvent extends SyRtcEvent {
  final String operatorUid;
  final Map<String, dynamic> roomInfo;

  SyRoomInfoUpdatedEvent({required this.operatorUid, required this.roomInfo})
      : super('roomInfoUpdated');
}

/// 房间公告更新事件
class SyRoomNoticeUpdatedEvent extends SyRtcEvent {
  final String operatorUid;
  final String notice;

  SyRoomNoticeUpdatedEvent({required this.operatorUid, required this.notice})
      : super('roomNoticeUpdated');
}

/// 房间管理员变更事件
class SyRoomManagerUpdatedEvent extends SyRtcEvent {
  final String uid;
  final bool isManager;
  final String operatorUid;

  SyRoomManagerUpdatedEvent({
    required this.uid,
    required this.isManager,
    required this.operatorUid,
  }) : super('roomManagerUpdated');
}

// ============================================================
// 座位管理事件
// ============================================================

/// 座位信息
class SySeatInfo {
  final int index;
  final String? uid;
  final bool isMuted;
  final bool isLocked;

  SySeatInfo({
    required this.index,
    this.uid,
    this.isMuted = false,
    this.isLocked = false,
  });

  factory SySeatInfo.fromMap(Map<String, dynamic> map) {
    return SySeatInfo(
      index: (map['index'] as num).toInt(),
      uid: map['uid'] as String?,
      isMuted: map['isMuted'] as bool? ?? false,
      isLocked: map['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'index': index,
        'uid': uid,
        'isMuted': isMuted,
        'isLocked': isLocked,
      };
}

/// 座位列表更新事件
class SySeatListUpdatedEvent extends SyRtcEvent {
  final List<SySeatInfo> seats;

  SySeatListUpdatedEvent({required this.seats}) : super('seatListUpdated');
}

/// 某个座位变更事件
class SySeatUpdatedEvent extends SyRtcEvent {
  final SySeatInfo seat;
  final String operatorUid;
  final SySeatAction action;

  SySeatUpdatedEvent({
    required this.seat,
    required this.operatorUid,
    required this.action,
  }) : super('seatUpdated');
}

/// 座位操作类型
enum SySeatAction {
  take,       // 上麦
  leave,      // 下麦
  mute,       // 静音
  unmute,     // 取消静音
  lock,       // 锁定
  unlock,     // 解锁
  kick,       // 被踢下麦
}

/// 麦位申请事件（房主/管理员收到）
class SySeatRequestReceivedEvent extends SyRtcEvent {
  final String uid;
  final int? seatIndex;

  SySeatRequestReceivedEvent({required this.uid, this.seatIndex})
      : super('seatRequestReceived');
}

/// 麦位申请被处理事件（申请者收到）
class SySeatRequestHandledEvent extends SyRtcEvent {
  final String operatorUid;
  final bool approved;
  final int? seatIndex;

  SySeatRequestHandledEvent({
    required this.operatorUid,
    required this.approved,
    this.seatIndex,
  }) : super('seatRequestHandled');
}

/// 麦位邀请事件（被邀请者收到）
class SySeatInvitationReceivedEvent extends SyRtcEvent {
  final String operatorUid;
  final int seatIndex;

  SySeatInvitationReceivedEvent({
    required this.operatorUid,
    required this.seatIndex,
  }) : super('seatInvitationReceived');
}

/// 麦位邀请被处理事件（邀请者收到）
class SySeatInvitationHandledEvent extends SyRtcEvent {
  final String uid;
  final bool accepted;
  final int seatIndex;

  SySeatInvitationHandledEvent({
    required this.uid,
    required this.accepted,
    required this.seatIndex,
  }) : super('seatInvitationHandled');
}

// ============================================================
// 用户管理事件
// ============================================================

/// 用户被踢出房间事件
class SyUserKickedEvent extends SyRtcEvent {
  final String uid;
  final String operatorUid;

  SyUserKickedEvent({required this.uid, required this.operatorUid})
      : super('userKicked');
}

/// 用户被禁言事件
class SyUserMutedEvent extends SyRtcEvent {
  final String uid;
  final bool isMuted;
  final String operatorUid;

  SyUserMutedEvent({
    required this.uid,
    required this.isMuted,
    required this.operatorUid,
  }) : super('userMuted');
}

/// 用户被禁止进入事件
class SyUserBannedEvent extends SyRtcEvent {
  final String uid;
  final bool isBanned;
  final String operatorUid;

  SyUserBannedEvent({
    required this.uid,
    required this.isBanned,
    required this.operatorUid,
  }) : super('userBanned');
}

// ============================================================
// 房间聊天 & 礼物事件
// ============================================================

/// 房间聊天消息类型
enum SyRoomMessageType {
  text,    // 文本消息
  emoji,   // 表情
  image,   // 图片
  system,  // 系统消息
  custom,  // 自定义
}

/// 房间聊天消息事件
class SyRoomMessageEvent extends SyRtcEvent {
  final String uid;
  final SyRoomMessageType messageType;
  final String content;
  final Map<String, dynamic>? extra;

  SyRoomMessageEvent({
    required this.uid,
    required this.messageType,
    required this.content,
    this.extra,
  }) : super('roomMessage');
}

/// 礼物消息事件
class SyGiftReceivedEvent extends SyRtcEvent {
  final String fromUid;
  final String toUid;
  final String giftId;
  final int count;
  final Map<String, dynamic>? extra;

  SyGiftReceivedEvent({
    required this.fromUid,
    required this.toUid,
    required this.giftId,
    required this.count,
    this.extra,
  }) : super('giftReceived');
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
