import 'sy_rtc_events.dart';

/// SY RTC事件处理器
class SyRtcEventHandler {
  // ============ 核心事件 ============

  /// 用户加入回调
  final void Function(String uid, int elapsed)? onUserJoined;

  /// 用户离开回调
  final void Function(String uid, String reason)? onUserOffline;

  /// 音量指示回调
  final void Function(List<Map<String, dynamic>> speakers)? onVolumeIndication;

  /// 错误回调
  final void Function(int code, String message)? onError;

  /// 数据流消息回调
  final void Function(String uid, int streamId, List<int> data)?
      onStreamMessage;

  /// 数据流消息错误回调
  final void Function(
          String uid, int streamId, int code, int missed, int cached)?
      onStreamMessageError;

  /// 原始频道消息回调
  final void Function(String uid, String message)? onChannelMessage;

  // ============ 房间管理事件 ============

  /// 房间信息更新
  final void Function(String operatorUid, Map<String, dynamic> roomInfo)?
      onRoomInfoUpdated;

  /// 房间公告更新
  final void Function(String operatorUid, String notice)? onRoomNoticeUpdated;

  /// 房间管理员变更
  final void Function(String uid, bool isManager, String operatorUid)?
      onRoomManagerUpdated;

  // ============ 座位管理事件 ============

  /// 座位列表更新（全量）
  final void Function(List<SySeatInfo> seats)? onSeatListUpdated;

  /// 单个座位变更
  final void Function(SySeatInfo seat, String operatorUid, SySeatAction action)?
      onSeatUpdated;

  /// 麦位申请（房主/管理员收到）
  final void Function(String uid, int? seatIndex)? onSeatRequestReceived;

  /// 麦位申请被处理（申请者收到）
  final void Function(String operatorUid, bool approved, int? seatIndex)?
      onSeatRequestHandled;

  /// 麦位邀请（被邀请者收到）
  final void Function(String operatorUid, int seatIndex)?
      onSeatInvitationReceived;

  /// 麦位邀请被处理（邀请者收到）
  final void Function(String uid, bool accepted, int seatIndex)?
      onSeatInvitationHandled;

  // ============ 用户管理事件 ============

  /// 用户被踢出房间
  final void Function(String uid, String operatorUid)? onUserKicked;

  /// 用户被禁言/解除禁言
  final void Function(String uid, bool isMuted, String operatorUid)?
      onUserMuted;

  /// 用户被封禁/解除封禁
  final void Function(String uid, bool isBanned, String operatorUid)?
      onUserBanned;

  // ============ 聊天 & 礼物 ============

  /// 房间消息
  final void Function(
          String uid, SyRoomMessageType type, String content, Map<String, dynamic>? extra)?
      onRoomMessage;

  /// 收到礼物
  final void Function(
          String fromUid, String toUid, String giftId, int count, Map<String, dynamic>? extra)?
      onGiftReceived;

  SyRtcEventHandler({
    this.onUserJoined,
    this.onUserOffline,
    this.onVolumeIndication,
    this.onError,
    this.onStreamMessage,
    this.onStreamMessageError,
    this.onChannelMessage,
    this.onRoomInfoUpdated,
    this.onRoomNoticeUpdated,
    this.onRoomManagerUpdated,
    this.onSeatListUpdated,
    this.onSeatUpdated,
    this.onSeatRequestReceived,
    this.onSeatRequestHandled,
    this.onSeatInvitationReceived,
    this.onSeatInvitationHandled,
    this.onUserKicked,
    this.onUserMuted,
    this.onUserBanned,
    this.onRoomMessage,
    this.onGiftReceived,
  });
}
