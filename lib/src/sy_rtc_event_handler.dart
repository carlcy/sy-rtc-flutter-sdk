/// SY RTC事件处理器
class SyRtcEventHandler {
  /// 用户加入回调
  final void Function(String uid, int elapsed)? onUserJoined;

  /// 用户离开回调
  final void Function(String uid, String reason)? onUserOffline;

  /// 音量指示回调
  final void Function(List<Map<String, dynamic>> speakers)? onVolumeIndication;

  /// 错误回调
  final void Function(int code, String message)? onError;

  /// 数据流消息回调
  final void Function(String uid, int streamId, List<int> data)? onStreamMessage;

  /// 数据流消息错误回调
  final void Function(String uid, int streamId, int code, int missed, int cached)? onStreamMessageError;

  SyRtcEventHandler({
    this.onUserJoined,
    this.onUserOffline,
    this.onVolumeIndication,
    this.onError,
    this.onStreamMessage,
    this.onStreamMessageError,
  });
}
