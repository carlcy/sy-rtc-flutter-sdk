/// SY RTC事件处理器
class SyRtcEventHandler {
  /// 用户加入回调
  final void Function(String uid, int elapsed)? onUserJoined;

  /// 用户离开回调
  final void Function(String uid, String reason)? onUserOffline;

  /// 音量指示回调
  final void Function(List<Map<String, dynamic>> speakers)? onVolumeIndication;

  SyRtcEventHandler({
    this.onUserJoined,
    this.onUserOffline,
    this.onVolumeIndication,
  });
}

