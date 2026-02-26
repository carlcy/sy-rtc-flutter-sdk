import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sy_rtc_event_handler.dart';
import 'sy_rtc_events.dart';
import 'sy_rtc_config_extended.dart';
import 'sy_rtc_video_quality.dart';

/// SY RTC引擎主类
/// 
/// SY RTC 引擎主类，提供实时音视频通信功能
/// 
/// 示例：
/// ```dart
/// final engine = SyRtcEngine();
/// await engine.init(appId);
/// await engine.join(channelId, uid, token);
/// ```
class SyRtcEngine {
  static const MethodChannel _channel = MethodChannel('sy_rtc_flutter_sdk');
  // 兼容：部分原生实现会把事件发送到单独的 MethodChannel
  static const MethodChannel _eventsChannel = MethodChannel('sy_rtc_flutter_sdk/events');
  static final SyRtcEngine _instance = SyRtcEngine._internal();
  static bool _methodHandlerRegistered = false;
  
  SyRtcEventHandler? _eventHandler;
  final StreamController<SyRtcEvent> _eventController = StreamController<SyRtcEvent>.broadcast();

  factory SyRtcEngine() => _instance;
  
  SyRtcEngine._internal() {
    // 注意：不要在构造期注册 setMethodCallHandler（单测/纯 Dart VM 下 BinaryMessenger 可能未初始化）
  }

  void _ensureMethodHandlerRegistered() {
    if (_methodHandlerRegistered) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _eventsChannel.setMethodCallHandler(_handleMethodCall);
    _methodHandlerRegistered = true;
  }

  Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    _ensureMethodHandlerRegistered();
    return _channel.invokeMethod<T>(method, arguments);
  }

  /// 初始化引擎
  /// 
  /// [appId] 应用ID
  /// [apiBaseUrl] API基础URL（可选，用于查询功能权限）
  /// [signalingUrl] 信令 WebSocket 地址（可选），例如：
  /// - ws://47.105.48.196/ws/signaling
  /// - wss://your-domain.com/ws/signaling
  Future<void> init(String appId, {String? apiBaseUrl, String? signalingUrl}) async {
    await _invoke<void>('init', {
      'appId': appId,
      'apiBaseUrl': apiBaseUrl,
      'signalingUrl': signalingUrl,
    });
    
    // 如果提供了API URL，查询功能权限
    if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
      await _checkFeatures(appId, apiBaseUrl);
    }
  }

  /// 设置后端 API 认证 Token（JWT）
  ///
  /// 用于调用 /api/rtc/live/* 等需要登录认证的接口。
  /// 注意：join() 的 token 是 RTC Token，与该 JWT 不同。
  Future<void> setApiAuthToken(String token) async {
    await _channel.invokeMethod('setApiAuthToken', {'token': token});
  }
  
  /// 检查功能权限
  /// 
  /// 通过MethodChannel调用原生层，原生层会通过HTTP请求查询功能权限
  /// 查询结果会缓存在原生层，后续通过hasFeature方法查询
  Future<void> _checkFeatures(String appId, String apiBaseUrl) async {
    try {
      // 通过MethodChannel让原生层处理HTTP请求
      // 原生层会调用后端API: GET {apiBaseUrl}/api/rtc/feature/{appId}
      // 返回格式: {"features": ["voice", "live"]}
      await _invoke<void>('checkFeatures', {
        'appId': appId,
        'apiBaseUrl': apiBaseUrl,
      });
    } catch (e) {
      // 权限检查失败不影响初始化，默认只有语聊功能
      print('功能权限检查失败: $e');
    }
  }
  
  /// 检查是否开通了指定功能
  Future<bool> hasFeature(String feature) async {
    final result = await _channel.invokeMethod('hasFeature', {'feature': feature});
    return result as bool? ?? false;
  }
  
  /// 检查是否开通了语聊功能
  Future<bool> hasVoiceFeature() async {
    return hasFeature('voice');
  }
  
  /// 检查是否开通了直播功能
  Future<bool> hasLiveFeature() async {
    return hasFeature('live');
  }

  /// 加入频道
  /// 
  /// [channelId] 频道ID
  /// [uid] 用户ID
  /// [token] 鉴权Token
  Future<void> join(String channelId, String uid, String token) async {
    await _channel.invokeMethod('join', {
      'channelId': channelId,
      'uid': uid,
      'token': token,
    });
  }

  /// 离开频道
  Future<void> leave() async {
    await _channel.invokeMethod('leave');
  }

  /// 启用/禁用本地音频
  /// 
  /// [enabled] true为启用，false为禁用
  Future<void> enableLocalAudio(bool enabled) async {
    await _channel.invokeMethod('enableLocalAudio', {'enabled': enabled});
  }

  /// 静音本地音频
  /// 
  /// [muted] true为静音，false为取消静音
  Future<void> muteLocalAudio(bool muted) async {
    await _channel.invokeMethod('muteLocalAudio', {'muted': muted});
  }

  /// 发送频道消息（广播给频道内所有用户）
  ///
  /// [message] 消息内容（通常为JSON字符串）
  Future<void> sendChannelMessage(String message) async {
    await _channel.invokeMethod('sendChannelMessage', {'message': message});
  }

  void _sendRoomAction(String action, Map<String, dynamic> data) {
    final msg = jsonEncode({'_sy_type': 'room-msg', 'action': action, 'data': data});
    sendChannelMessage(msg);
  }

  // ==================== 房间管理 ====================

  /// 更新房间信息
  ///
  /// [roomInfo] 房间信息键值对，如 {'name': '新房名', 'coverUrl': '...'}
  Future<void> updateRoomInfo(Map<String, dynamic> roomInfo) async {
    _sendRoomAction('room-info-update', {'roomInfo': roomInfo});
  }

  /// 设置房间公告
  Future<void> setRoomNotice(String notice) async {
    _sendRoomAction('room-notice-update', {'notice': notice});
  }

  /// 设置/取消房间管理员
  ///
  /// [uid] 目标用户ID
  /// [isManager] true为设置管理员，false为取消
  Future<void> setRoomManager(String uid, bool isManager) async {
    _sendRoomAction('manager-update', {'uid': uid, 'isManager': isManager});
  }

  // ==================== 座位管理 ====================

  /// 上麦（占座）
  ///
  /// [seatIndex] 座位索引（0-based）
  Future<void> takeSeat(int seatIndex) async {
    _sendRoomAction('seat-take', {'seatIndex': seatIndex});
  }

  /// 下麦
  Future<void> leaveSeat() async {
    _sendRoomAction('seat-leave', {});
  }

  /// 申请上麦（观众向房主/管理员发申请）
  ///
  /// [seatIndex] 期望的座位索引（可选）
  Future<void> requestSeat({int? seatIndex}) async {
    _sendRoomAction('seat-request', {'seatIndex': seatIndex});
  }

  /// 取消申请上麦
  Future<void> cancelSeatRequest() async {
    _sendRoomAction('seat-request-cancel', {});
  }

  /// 处理上麦申请（房主/管理员调用）
  ///
  /// [uid] 申请者UID
  /// [approved] 是否同意
  /// [seatIndex] 分配的座位索引（同意时需要）
  Future<void> handleSeatRequest(String uid, bool approved, {int? seatIndex}) async {
    _sendRoomAction('seat-request-handle', {
      'uid': uid,
      'approved': approved,
      'seatIndex': seatIndex,
    });
  }

  /// 邀请用户上麦（房主/管理员调用）
  ///
  /// [uid] 被邀请者UID
  /// [seatIndex] 座位索引
  Future<void> inviteToSeat(String uid, int seatIndex) async {
    _sendRoomAction('seat-invite', {'uid': uid, 'seatIndex': seatIndex});
  }

  /// 处理上麦邀请（被邀请者调用）
  ///
  /// [accepted] 是否接受
  /// [seatIndex] 座位索引
  Future<void> handleSeatInvitation(bool accepted, int seatIndex) async {
    _sendRoomAction('seat-invite-handle', {
      'accepted': accepted,
      'seatIndex': seatIndex,
    });
  }

  /// 踢下麦（房主/管理员调用）
  ///
  /// [uid] 被踢者UID
  Future<void> kickFromSeat(String uid) async {
    _sendRoomAction('seat-kick', {'uid': uid});
  }

  /// 锁定座位（房主/管理员调用）
  Future<void> lockSeat(int seatIndex) async {
    _sendRoomAction('seat-lock', {'seatIndex': seatIndex, 'locked': true});
  }

  /// 解锁座位
  Future<void> unlockSeat(int seatIndex) async {
    _sendRoomAction('seat-lock', {'seatIndex': seatIndex, 'locked': false});
  }

  /// 静音座位（房主/管理员对某座位静音）
  Future<void> muteSeat(int seatIndex) async {
    _sendRoomAction('seat-mute', {'seatIndex': seatIndex, 'muted': true});
  }

  /// 取消静音座位
  Future<void> unmuteSeat(int seatIndex) async {
    _sendRoomAction('seat-mute', {'seatIndex': seatIndex, 'muted': false});
  }

  // ==================== 用户管理 ====================

  /// 踢出用户（房主/管理员调用）
  Future<void> kickUser(String uid) async {
    _sendRoomAction('user-kick', {'uid': uid});
  }

  /// 禁言/解除禁言用户（房主/管理员调用）
  Future<void> muteUser(String uid, bool muted) async {
    _sendRoomAction('user-mute', {'uid': uid, 'muted': muted});
  }

  /// 封禁/解封用户（房主调用）
  Future<void> banUser(String uid, bool banned) async {
    _sendRoomAction('user-ban', {'uid': uid, 'banned': banned});
  }

  // ==================== 房间聊天 ====================

  /// 发送房间文本消息
  Future<void> sendRoomMessage(String content, {SyRoomMessageType type = SyRoomMessageType.text, Map<String, dynamic>? extra}) async {
    _sendRoomAction('room-chat', {
      'messageType': type.name,
      'content': content,
      'extra': extra,
    });
  }

  /// 发送礼物
  ///
  /// [giftId] 礼物ID
  /// [toUid] 接收者UID
  /// [count] 数量
  /// [extra] 附加信息（如礼物名称、动画等）
  Future<void> sendGift(String giftId, String toUid, int count, {Map<String, dynamic>? extra}) async {
    _sendRoomAction('gift', {
      'giftId': giftId,
      'toUid': toUid,
      'count': count,
      'extra': extra,
    });
  }

  /// 设置客户端角色
  /// 
  /// [role] 角色：'host' 或 'audience'
  Future<void> setClientRole(String role) async {
    await _channel.invokeMethod('setClientRole', {'role': role});
  }

  /// 设置事件处理器
  void setEventHandler(SyRtcEventHandler handler) {
    _eventHandler = handler;
  }

  /// 用户加入事件流
  Stream<SyUserJoinedEvent> get onUserJoined {
    return _eventController.stream
        .where((event) => event is SyUserJoinedEvent)
        .cast<SyUserJoinedEvent>();
  }

  /// 用户离开事件流
  Stream<SyUserOfflineEvent> get onUserOffline {
    return _eventController.stream
        .where((event) => event is SyUserOfflineEvent)
        .cast<SyUserOfflineEvent>();
  }

  /// 音量指示事件流
  Stream<SyVolumeIndicationEvent> get onVolumeIndication {
    return _eventController.stream
        .where((event) => event is SyVolumeIndicationEvent)
        .cast<SyVolumeIndicationEvent>();
  }

  // ==================== 新增事件流 ====================

  /// Token 即将过期事件流（30秒前）
  Stream<SyTokenPrivilegeWillExpireEvent> get onTokenPrivilegeWillExpire {
    return _eventController.stream
        .where((event) => event is SyTokenPrivilegeWillExpireEvent)
        .cast<SyTokenPrivilegeWillExpireEvent>();
  }

  /// Token 已过期事件流
  Stream<SyRequestTokenEvent> get onRequestToken {
    return _eventController.stream
        .where((event) => event is SyRequestTokenEvent)
        .cast<SyRequestTokenEvent>();
  }

  /// 连接状态变化事件流
  Stream<SyConnectionStateChangedEvent> get onConnectionStateChanged {
    return _eventController.stream
        .where((event) => event is SyConnectionStateChangedEvent)
        .cast<SyConnectionStateChangedEvent>();
  }

  /// 网络质量事件流
  Stream<SyNetworkQualityEvent> get onNetworkQuality {
    return _eventController.stream
        .where((event) => event is SyNetworkQualityEvent)
        .cast<SyNetworkQualityEvent>();
  }

  /// 远端音频状态变化事件流
  Stream<SyRemoteAudioStateChangedEvent> get onRemoteAudioStateChanged {
    return _eventController.stream
        .where((event) => event is SyRemoteAudioStateChangedEvent)
        .cast<SyRemoteAudioStateChangedEvent>();
  }

  /// 远端视频状态变化事件流
  Stream<SyRemoteVideoStateChangedEvent> get onRemoteVideoStateChanged {
    return _eventController.stream
        .where((event) => event is SyRemoteVideoStateChangedEvent)
        .cast<SyRemoteVideoStateChangedEvent>();
  }

  /// 本地音频状态变化事件流
  Stream<SyLocalAudioStateChangedEvent> get onLocalAudioStateChanged {
    return _eventController.stream
        .where((event) => event is SyLocalAudioStateChangedEvent)
        .cast<SyLocalAudioStateChangedEvent>();
  }

  /// 本地视频状态变化事件流
  Stream<SyLocalVideoStateChangedEvent> get onLocalVideoStateChanged {
    return _eventController.stream
        .where((event) => event is SyLocalVideoStateChangedEvent)
        .cast<SyLocalVideoStateChangedEvent>();
  }

  /// 音频路由变化事件流
  Stream<SyAudioRoutingChangedEvent> get onAudioRoutingChanged {
    return _eventController.stream
        .where((event) => event is SyAudioRoutingChangedEvent)
        .cast<SyAudioRoutingChangedEvent>();
  }

  /// 数据流消息事件流
  Stream<SyStreamMessageEvent> get onStreamMessage {
    return _eventController.stream
        .where((event) => event is SyStreamMessageEvent)
        .cast<SyStreamMessageEvent>();
  }

  /// 数据流消息错误事件流
  Stream<SyStreamMessageErrorEvent> get onStreamMessageError {
    return _eventController.stream
        .where((event) => event is SyStreamMessageErrorEvent)
        .cast<SyStreamMessageErrorEvent>();
  }

  /// 频道消息事件流
  Stream<SyChannelMessageEvent> get onChannelMessage {
    return _eventController.stream
        .where((event) => event is SyChannelMessageEvent)
        .cast<SyChannelMessageEvent>();
  }

  /// 首帧远端视频解码事件流
  Stream<SyFirstRemoteVideoDecodedEvent> get onFirstRemoteVideoDecoded {
    return _eventController.stream
        .where((event) => event is SyFirstRemoteVideoDecodedEvent)
        .cast<SyFirstRemoteVideoDecodedEvent>();
  }

  /// 首帧远端视频渲染事件流
  Stream<SyFirstRemoteVideoFrameEvent> get onFirstRemoteVideoFrame {
    return _eventController.stream
        .where((event) => event is SyFirstRemoteVideoFrameEvent)
        .cast<SyFirstRemoteVideoFrameEvent>();
  }

  /// 视频大小变化事件流
  Stream<SyVideoSizeChangedEvent> get onVideoSizeChanged {
    return _eventController.stream
        .where((event) => event is SyVideoSizeChangedEvent)
        .cast<SyVideoSizeChangedEvent>();
  }

  /// 错误事件流
  Stream<SyErrorEvent> get onError {
    return _eventController.stream
        .where((event) => event is SyErrorEvent)
        .cast<SyErrorEvent>();
  }

  // ==================== 房间管理事件流 ====================

  /// 房间信息更新事件流
  Stream<SyRoomInfoUpdatedEvent> get onRoomInfoUpdated =>
      _eventController.stream.whereType<SyRoomInfoUpdatedEvent>();

  /// 房间公告更新事件流
  Stream<SyRoomNoticeUpdatedEvent> get onRoomNoticeUpdated =>
      _eventController.stream.whereType<SyRoomNoticeUpdatedEvent>();

  /// 房间管理员变更事件流
  Stream<SyRoomManagerUpdatedEvent> get onRoomManagerUpdated =>
      _eventController.stream.whereType<SyRoomManagerUpdatedEvent>();

  // ==================== 座位管理事件流 ====================

  /// 座位列表更新事件流（全量）
  Stream<SySeatListUpdatedEvent> get onSeatListUpdated =>
      _eventController.stream.whereType<SySeatListUpdatedEvent>();

  /// 单个座位变更事件流
  Stream<SySeatUpdatedEvent> get onSeatUpdated =>
      _eventController.stream.whereType<SySeatUpdatedEvent>();

  /// 麦位申请事件流（房主/管理员收到）
  Stream<SySeatRequestReceivedEvent> get onSeatRequestReceived =>
      _eventController.stream.whereType<SySeatRequestReceivedEvent>();

  /// 麦位申请被处理事件流（申请者收到）
  Stream<SySeatRequestHandledEvent> get onSeatRequestHandled =>
      _eventController.stream.whereType<SySeatRequestHandledEvent>();

  /// 麦位邀请事件流（被邀请者收到）
  Stream<SySeatInvitationReceivedEvent> get onSeatInvitationReceived =>
      _eventController.stream.whereType<SySeatInvitationReceivedEvent>();

  /// 麦位邀请被处理事件流（邀请者收到）
  Stream<SySeatInvitationHandledEvent> get onSeatInvitationHandled =>
      _eventController.stream.whereType<SySeatInvitationHandledEvent>();

  // ==================== 用户管理事件流 ====================

  /// 用户被踢出房间事件流
  Stream<SyUserKickedEvent> get onUserKicked =>
      _eventController.stream.whereType<SyUserKickedEvent>();

  /// 用户被禁言事件流
  Stream<SyUserMutedEvent> get onUserMuted =>
      _eventController.stream.whereType<SyUserMutedEvent>();

  /// 用户被封禁事件流
  Stream<SyUserBannedEvent> get onUserBanned =>
      _eventController.stream.whereType<SyUserBannedEvent>();

  // ==================== 聊天 & 礼物事件流 ====================

  /// 房间消息事件流
  Stream<SyRoomMessageEvent> get onRoomMessage =>
      _eventController.stream.whereType<SyRoomMessageEvent>();

  /// 礼物事件流
  Stream<SyGiftReceivedEvent> get onGiftReceived =>
      _eventController.stream.whereType<SyGiftReceivedEvent>();

  // ==================== 音频路由控制 ====================

  /// 开启/关闭扬声器
  Future<void> setEnableSpeakerphone(bool enabled) async {
    await _channel.invokeMethod('setEnableSpeakerphone', {'enabled': enabled});
  }

  /// 设置默认音频路由
  Future<void> setDefaultAudioRouteToSpeakerphone(bool enabled) async {
    await _channel.invokeMethod('setDefaultAudioRouteToSpeakerphone', {'enabled': enabled});
  }

  /// 检查扬声器状态
  Future<bool> isSpeakerphoneEnabled() async {
    final result = await _channel.invokeMethod('isSpeakerphoneEnabled');
    return result as bool? ?? false;
  }

  // ==================== 远端音频控制 ====================

  /// 静音指定远端用户
  Future<void> muteRemoteAudioStream(String uid, bool muted) async {
    await _channel.invokeMethod('muteRemoteAudioStream', {
      'uid': uid,
      'muted': muted,
    });
  }

  /// 静音所有远端用户
  Future<void> muteAllRemoteAudioStreams(bool muted) async {
    await _channel.invokeMethod('muteAllRemoteAudioStreams', {'muted': muted});
  }

  /// 调节指定用户音量（0-100）
  Future<void> adjustUserPlaybackSignalVolume(String uid, int volume) async {
    await _channel.invokeMethod('adjustUserPlaybackSignalVolume', {
      'uid': uid,
      'volume': volume,
    });
  }

  /// 调节所有远端用户音量（0-100）
  Future<void> adjustPlaybackSignalVolume(int volume) async {
    await _channel.invokeMethod('adjustPlaybackSignalVolume', {'volume': volume});
  }

  // ==================== Token 刷新 ====================

  /// 更新 Token
  Future<void> renewToken(String token) async {
    await _channel.invokeMethod('renewToken', {'token': token});
  }

  // ==================== 音频参数配置 ====================

  /// 设置音频配置
  Future<void> setAudioProfile(SyAudioProfile profile, SyAudioScenario scenario) async {
    await _channel.invokeMethod('setAudioProfile', {
      'profile': profile.toString().split('.').last,
      'scenario': scenario.toString().split('.').last,
    });
  }

  /// 启用/禁用音频模块
  Future<void> enableAudio() async {
    await _channel.invokeMethod('enableAudio');
  }

  /// 禁用音频模块
  Future<void> disableAudio() async {
    await _channel.invokeMethod('disableAudio');
  }

  // ==================== 音频设备管理 ====================

  /// 获取音频采集设备列表
  Future<List<SyAudioDeviceInfo>> enumerateRecordingDevices() async {
    final result = await _channel.invokeMethod('enumerateRecordingDevices');
    final List<dynamic> devices = result as List<dynamic>? ?? [];
    return devices.map((d) => SyAudioDeviceInfo(
      deviceId: d['deviceId'] as String,
      deviceName: d['deviceName'] as String,
    )).toList();
  }

  /// 获取音频播放设备列表
  Future<List<SyAudioDeviceInfo>> enumeratePlaybackDevices() async {
    final result = await _channel.invokeMethod('enumeratePlaybackDevices');
    final List<dynamic> devices = result as List<dynamic>? ?? [];
    return devices.map((d) => SyAudioDeviceInfo(
      deviceId: d['deviceId'] as String,
      deviceName: d['deviceName'] as String,
    )).toList();
  }

  /// 设置音频采集设备
  Future<void> setRecordingDevice(String deviceId) async {
    await _channel.invokeMethod('setRecordingDevice', {'deviceId': deviceId});
  }

  /// 设置音频播放设备
  Future<void> setPlaybackDevice(String deviceId) async {
    await _channel.invokeMethod('setPlaybackDevice', {'deviceId': deviceId});
  }

  /// 获取采集音量（0-255）
  Future<int> getRecordingDeviceVolume() async {
    final result = await _channel.invokeMethod('getRecordingDeviceVolume');
    return result as int? ?? 0;
  }

  /// 设置采集音量（0-255）
  Future<void> setRecordingDeviceVolume(int volume) async {
    await _channel.invokeMethod('setRecordingDeviceVolume', {'volume': volume});
  }

  /// 获取播放音量（0-255）
  Future<int> getPlaybackDeviceVolume() async {
    final result = await _channel.invokeMethod('getPlaybackDeviceVolume');
    return result as int? ?? 0;
  }

  /// 设置播放音量（0-255）
  Future<void> setPlaybackDeviceVolume(int volume) async {
    await _channel.invokeMethod('setPlaybackDeviceVolume', {'volume': volume});
  }

  // ==================== 网络质量监控 ====================

  /// 获取连接状态
  Future<SyConnectionState> getConnectionState() async {
    final result = await _channel.invokeMethod('getConnectionState');
    final String stateStr = result as String? ?? 'disconnected';
    return SyConnectionState.values.firstWhere(
      (e) => e.toString().split('.').last == stateStr,
      orElse: () => SyConnectionState.disconnected,
    );
  }

  /// 获取网络类型
  Future<String> getNetworkType() async {
    final result = await _channel.invokeMethod('getNetworkType');
    return result as String? ?? 'unknown';
  }

  // ==================== 音频采集控制 ====================

  /// 调节采集音量（0-400，100为原始音量）
  Future<void> adjustRecordingSignalVolume(int volume) async {
    await _channel.invokeMethod('adjustRecordingSignalVolume', {'volume': volume});
  }

  /// 静音采集信号
  Future<void> muteRecordingSignal(bool muted) async {
    await _channel.invokeMethod('muteRecordingSignal', {'muted': muted});
  }

  // ==================== 视频基础功能 ====================

  /// 启用视频模块（需要live权限）
  /// 
  /// [quality] 视频画质预设（可选，默认标准画质）
  Future<void> enableVideo({SyVideoQualityPreset? quality}) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频功能');
    }
    
    // 如果指定了画质，先设置编码配置
    if (quality != null) {
      await setVideoQuality(quality);
    }
    
    await _channel.invokeMethod('enableVideo');
  }
  
  /// 设置视频画质预设
  /// 
  /// [preset] 画质预设（流畅/标准/高清/超清/4K）
  Future<void> setVideoQuality(SyVideoQualityPreset preset) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频功能');
    }
    
    final configMap = preset.toEncoderConfigMap();
    await _channel.invokeMethod('setVideoEncoderConfiguration', configMap);
  }
  
  /// 设置音频质量等级
  /// 
  /// [quality] 音频质量等级（低/中/高/超高）
  Future<void> setAudioQuality(SyAudioQualityLevel quality) async {
    await _channel.invokeMethod('setAudioQuality', {
      'quality': quality.toString().split('.').last,
    });
  }

  /// 禁用视频模块
  Future<void> disableVideo() async {
    await _channel.invokeMethod('disableVideo');
  }

  /// 启用/禁用本地视频采集（需要live权限）
  Future<void> enableLocalVideo(bool enabled) async {
    if (enabled) {
      final hasLive = await hasLiveFeature();
      if (!hasLive) {
        throw Exception('当前AppId未开通直播功能，无法使用视频功能');
      }
    }
    await _channel.invokeMethod('enableLocalVideo', {'enabled': enabled});
  }

  /// 设置视频编码配置
  Future<void> setVideoEncoderConfiguration(SyVideoEncoderConfiguration config) async {
    await _channel.invokeMethod('setVideoEncoderConfiguration', {
      'width': config.width,
      'height': config.height,
      'frameRate': config.frameRate,
      'minFrameRate': config.minFrameRate,
      'bitrate': config.bitrate,
      'minBitrate': config.minBitrate,
      'orientationMode': config.orientationMode.toString().split('.').last,
      'degradationPreference': config.degradationPreference.toString().split('.').last,
      'mirrorMode': config.mirrorMode.toString().split('.').last,
    });
  }

  /// 开启视频预览（需要live权限）
  Future<void> startPreview() async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频预览');
    }
    await _channel.invokeMethod('startPreview');
  }

  /// 停止视频预览
  Future<void> stopPreview() async {
    await _channel.invokeMethod('stopPreview');
  }

  /// 静音本地视频
  Future<void> muteLocalVideoStream(bool muted) async {
    await _channel.invokeMethod('muteLocalVideoStream', {'muted': muted});
  }

  /// 静音远端视频
  Future<void> muteRemoteVideoStream(String uid, bool muted) async {
    await _channel.invokeMethod('muteRemoteVideoStream', {
      'uid': uid,
      'muted': muted,
    });
  }

  /// 静音所有远端视频
  Future<void> muteAllRemoteVideoStreams(bool muted) async {
    await _channel.invokeMethod('muteAllRemoteVideoStreams', {'muted': muted});
  }

  // ==================== 视频渲染 ====================

  /// 设置本地视频视图（需要live权限）
  Future<void> setupLocalVideo(int viewId) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频渲染');
    }
    await _channel.invokeMethod('setupLocalVideo', {'viewId': viewId});
  }

  /// 设置远端视频视图（需要live权限）
  Future<void> setupRemoteVideo(String uid, int viewId) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频渲染');
    }
    await _channel.invokeMethod('setupRemoteVideo', {
      'uid': uid,
      'viewId': viewId,
    });
  }

  // ==================== 屏幕共享 ====================

  /// 开始屏幕共享（需要live权限）
  Future<void> startScreenCapture(SyScreenCaptureConfiguration config) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用屏幕共享');
    }
    await _channel.invokeMethod('startScreenCapture', {
      'captureMouseCursor': config.captureMouseCursor,
      'captureWindow': config.captureWindow,
      'frameRate': config.frameRate,
      'bitrate': config.bitrate,
      'width': config.width,
      'height': config.height,
    });
  }

  /// 停止屏幕共享
  Future<void> stopScreenCapture() async {
    await _channel.invokeMethod('stopScreenCapture');
  }

  /// 更新屏幕共享配置
  Future<void> updateScreenCaptureConfiguration(SyScreenCaptureConfiguration config) async {
    await _channel.invokeMethod('updateScreenCaptureConfiguration', {
      'captureMouseCursor': config.captureMouseCursor,
      'captureWindow': config.captureWindow,
      'frameRate': config.frameRate,
      'bitrate': config.bitrate,
      'width': config.width,
      'height': config.height,
    });
  }

  // ==================== 视频增强 ====================

  /// 设置美颜选项（需要live权限）
  Future<void> setBeautyEffectOptions(SyBeautyOptions options) async {
    if (options.enabled) {
      final hasLive = await hasLiveFeature();
      if (!hasLive) {
        throw Exception('当前AppId未开通直播功能，无法使用美颜功能');
      }
    }
    await _channel.invokeMethod('setBeautyEffectOptions', {
      'enabled': options.enabled,
      'lighteningLevel': options.lighteningLevel,
      'rednessLevel': options.rednessLevel,
      'smoothnessLevel': options.smoothnessLevel,
    });
  }

  /// 视频截图（需要live权限）
  Future<void> takeSnapshot(String uid, String filePath) async {
    final hasLive = await hasLiveFeature();
    if (!hasLive) {
      throw Exception('当前AppId未开通直播功能，无法使用视频截图');
    }
    await _channel.invokeMethod('takeSnapshot', {
      'uid': uid,
      'filePath': filePath,
    });
  }

  // ==================== 音乐文件播放 ====================

  /// 开始播放音乐文件
  Future<void> startAudioMixing(SyAudioMixingConfiguration config) async {
    await _channel.invokeMethod('startAudioMixing', {
      'filePath': config.filePath,
      'loopback': config.loopback,
      'replace': config.replace,
      'cycle': config.cycle,
      'startPos': config.startPos,
    });
  }

  /// 停止播放音乐文件
  Future<void> stopAudioMixing() async {
    await _channel.invokeMethod('stopAudioMixing');
  }

  /// 暂停播放音乐文件
  Future<void> pauseAudioMixing() async {
    await _channel.invokeMethod('pauseAudioMixing');
  }

  /// 恢复播放音乐文件
  Future<void> resumeAudioMixing() async {
    await _channel.invokeMethod('resumeAudioMixing');
  }

  /// 调节音乐文件音量（0-100）
  Future<void> adjustAudioMixingVolume(int volume) async {
    await _channel.invokeMethod('adjustAudioMixingVolume', {'volume': volume});
  }

  /// 获取音乐文件播放进度（毫秒）
  Future<int> getAudioMixingCurrentPosition() async {
    final result = await _channel.invokeMethod('getAudioMixingCurrentPosition');
    return result as int? ?? 0;
  }

  /// 设置音乐文件播放位置（毫秒）
  Future<void> setAudioMixingPosition(int position) async {
    await _channel.invokeMethod('setAudioMixingPosition', {'position': position});
  }

  // ==================== 音效文件播放 ====================

  /// 播放音效
  Future<void> playEffect(int soundId, SyAudioEffectConfiguration config) async {
    await _channel.invokeMethod('playEffect', {
      'soundId': soundId,
      'filePath': config.filePath,
      'loopCount': config.loopCount,
      'publish': config.publish,
      'startPos': config.startPos,
    });
  }

  /// 停止音效
  Future<void> stopEffect(int soundId) async {
    await _channel.invokeMethod('stopEffect', {'soundId': soundId});
  }

  /// 停止所有音效
  Future<void> stopAllEffects() async {
    await _channel.invokeMethod('stopAllEffects');
  }

  /// 设置音效音量（0-100）
  Future<void> setEffectsVolume(int volume) async {
    await _channel.invokeMethod('setEffectsVolume', {'volume': volume});
  }

  /// 预加载音效
  Future<void> preloadEffect(int soundId, String filePath) async {
    await _channel.invokeMethod('preloadEffect', {
      'soundId': soundId,
      'filePath': filePath,
    });
  }

  /// 卸载音效
  Future<void> unloadEffect(int soundId) async {
    await _channel.invokeMethod('unloadEffect', {'soundId': soundId});
  }

  // ==================== 音频录制 ====================

  /// 开始客户端录音
  Future<void> startAudioRecording(SyAudioRecordingConfiguration config) async {
    await _channel.invokeMethod('startAudioRecording', {
      'filePath': config.filePath,
      'sampleRate': config.sampleRate,
      'channels': config.channels,
      'codecType': config.codecType.toString().split('.').last,
      'quality': config.quality.toString().split('.').last,
    });
  }

  /// 停止客户端录音
  Future<void> stopAudioRecording() async {
    await _channel.invokeMethod('stopAudioRecording');
  }

  // ==================== 数据流 ====================

  /// 创建数据流
  Future<int> createDataStream({bool reliable = true, bool ordered = true}) async {
    final result = await _channel.invokeMethod('createDataStream', {
      'reliable': reliable,
      'ordered': ordered,
    });
    return result as int? ?? 0;
  }

  /// 发送数据流消息
  Future<void> sendStreamMessage(int streamId, Uint8List data) async {
    await _channel.invokeMethod('sendStreamMessage', {
      'streamId': streamId,
      'data': data,
    });
  }

  // ==================== 旁路推流 ====================

  /// 开始旁路推流
  /// 
  /// [url] 推流地址。如果为空字符串，后端会自动生成我们服务器的RTMP地址
  /// 格式：rtmp://server-ip:1935/live/{appId}_{channelId}
  /// 
  /// 也可以传入第三方CDN的推流地址（如抖音、快手等）
  Future<void> startRtmpStreamWithTranscoding(String url, SyLiveTranscoding transcoding) async {
    await _channel.invokeMethod('startRtmpStreamWithTranscoding', {
      'url': url, // 如果为空，后端会自动生成我们服务器的RTMP地址
      'width': transcoding.width,
      'height': transcoding.height,
      'videoBitrate': transcoding.videoBitrate,
      'videoFramerate': transcoding.videoFramerate,
      'lowLatency': transcoding.lowLatency,
      'videoGop': transcoding.videoGop,
      'backgroundColor': transcoding.backgroundColor,
      'watermarkUrl': transcoding.watermarkUrl,
      'transcodingUsers': transcoding.transcodingUsers?.map((u) => {
        'uid': u.uid,
        'x': u.x,
        'y': u.y,
        'width': u.width,
        'height': u.height,
        'zOrder': u.zOrder,
        'alpha': u.alpha,
      }).toList(),
    });
  }

  /// 停止旁路推流
  Future<void> stopRtmpStream(String url) async {
    await _channel.invokeMethod('stopRtmpStream', {'url': url});
  }

  /// 更新旁路推流转码配置
  Future<void> updateRtmpTranscoding(SyLiveTranscoding transcoding) async {
    await _channel.invokeMethod('updateRtmpTranscoding', {
      'width': transcoding.width,
      'height': transcoding.height,
      'videoBitrate': transcoding.videoBitrate,
      'videoFramerate': transcoding.videoFramerate,
      'lowLatency': transcoding.lowLatency,
      'videoGop': transcoding.videoGop,
      'backgroundColor': transcoding.backgroundColor,
      'watermarkUrl': transcoding.watermarkUrl,
      'transcodingUsers': transcoding.transcodingUsers?.map((u) => {
        'uid': u.uid,
        'x': u.x,
        'y': u.y,
        'width': u.width,
        'height': u.height,
        'zOrder': u.zOrder,
        'alpha': u.alpha,
      }).toList(),
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onUserJoined':
        final event = SyUserJoinedEvent(
          uid: call.arguments['uid'] as String,
          elapsed: call.arguments['elapsed'] as int? ?? 0,
        );
        _eventController.add(event);
        _eventHandler?.onUserJoined?.call(event.uid, event.elapsed);
        break;
      case 'onUserOffline':
        final event = SyUserOfflineEvent(
          uid: call.arguments['uid'] as String,
          reason: call.arguments['reason'] as String? ?? 'quit',
        );
        _eventController.add(event);
        _eventHandler?.onUserOffline?.call(event.uid, event.reason);
        break;
      case 'onVolumeIndication':
        final event = SyVolumeIndicationEvent(
          speakers: List<Map<String, dynamic>>.from(call.arguments['speakers'] ?? []),
        );
        _eventController.add(event);
        _eventHandler?.onVolumeIndication?.call(event.speakers);
        break;
      case 'onTokenPrivilegeWillExpire':
        final event = SyTokenPrivilegeWillExpireEvent();
        _eventController.add(event);
        break;
      case 'onRequestToken':
        final event = SyRequestTokenEvent();
        _eventController.add(event);
        break;
      case 'onConnectionStateChanged':
        final stateStr = call.arguments['state'] as String? ?? 'disconnected';
        final reasonStr = call.arguments['reason'] as String? ?? 'connecting';
        final state = SyConnectionState.values.firstWhere(
          (e) => e.toString().split('.').last == stateStr,
          orElse: () => SyConnectionState.disconnected,
        );
        final reason = SyConnectionChangedReason.values.firstWhere(
          (e) => e.toString().split('.').last == reasonStr,
          orElse: () => SyConnectionChangedReason.connecting,
        );
        final event = SyConnectionStateChangedEvent(state: state, reason: reason);
        _eventController.add(event);
        break;
      case 'onNetworkQuality':
        final uid = call.arguments['uid'] as String? ?? '0';
        final txStr = call.arguments['txQuality'] as String? ?? 'unknown';
        final rxStr = call.arguments['rxQuality'] as String? ?? 'unknown';
        final txQuality = SyNetworkQuality.values.firstWhere(
          (e) => e.toString().split('.').last == txStr,
          orElse: () => SyNetworkQuality.unknown,
        );
        final rxQuality = SyNetworkQuality.values.firstWhere(
          (e) => e.toString().split('.').last == rxStr,
          orElse: () => SyNetworkQuality.unknown,
        );
        final event = SyNetworkQualityEvent(uid: uid, txQuality: txQuality, rxQuality: rxQuality);
        _eventController.add(event);
        break;
      case 'onRemoteAudioStateChanged':
        final uid = call.arguments['uid'] as String;
        final stateStr = call.arguments['state'] as String? ?? 'stopped';
        final reasonStr = call.arguments['reason'] as String? ?? 'internal';
        final elapsed = call.arguments['elapsed'] as int? ?? 0;
        final state = SyRemoteAudioState.values.firstWhere(
          (e) => e.toString().split('.').last == stateStr,
          orElse: () => SyRemoteAudioState.stopped,
        );
        final reason = SyRemoteAudioStateReason.values.firstWhere(
          (e) => e.toString().split('.').last == reasonStr,
          orElse: () => SyRemoteAudioStateReason.internal,
        );
        final event = SyRemoteAudioStateChangedEvent(
          uid: uid,
          state: state,
          reason: reason,
          elapsed: elapsed,
        );
        _eventController.add(event);
        break;
      case 'onRemoteVideoStateChanged':
        final uid = call.arguments['uid'] as String;
        final stateStr = call.arguments['state'] as String? ?? 'stopped';
        final reasonStr = call.arguments['reason'] as String? ?? 'internal';
        final elapsed = call.arguments['elapsed'] as int? ?? 0;
        final state = SyRemoteVideoState.values.firstWhere(
          (e) => e.toString().split('.').last == stateStr,
          orElse: () => SyRemoteVideoState.stopped,
        );
        final reason = SyRemoteVideoStateReason.values.firstWhere(
          (e) => e.toString().split('.').last == reasonStr,
          orElse: () => SyRemoteVideoStateReason.internal,
        );
        final event = SyRemoteVideoStateChangedEvent(
          uid: uid,
          state: state,
          reason: reason,
          elapsed: elapsed,
        );
        _eventController.add(event);
        break;
      case 'onLocalAudioStateChanged':
        final stateStr = call.arguments['state'] as String? ?? 'stopped';
        final errorStr = call.arguments['error'] as String? ?? 'ok';
        final state = SyLocalAudioStreamState.values.firstWhere(
          (e) => e.toString().split('.').last == stateStr,
          orElse: () => SyLocalAudioStreamState.stopped,
        );
        final error = SyLocalAudioStreamError.values.firstWhere(
          (e) => e.toString().split('.').last == errorStr,
          orElse: () => SyLocalAudioStreamError.ok,
        );
        final event = SyLocalAudioStateChangedEvent(state: state, error: error);
        _eventController.add(event);
        break;
      case 'onLocalVideoStateChanged':
        final stateStr = call.arguments['state'] as String? ?? 'stopped';
        final errorStr = call.arguments['error'] as String? ?? 'ok';
        final state = SyLocalVideoStreamState.values.firstWhere(
          (e) => e.toString().split('.').last == stateStr,
          orElse: () => SyLocalVideoStreamState.stopped,
        );
        final error = SyLocalVideoStreamError.values.firstWhere(
          (e) => e.toString().split('.').last == errorStr,
          orElse: () => SyLocalVideoStreamError.ok,
        );
        final event = SyLocalVideoStateChangedEvent(state: state, error: error);
        _eventController.add(event);
        break;
      case 'onAudioRoutingChanged':
        final routing = call.arguments['routing'] as int? ?? 0;
        final event = SyAudioRoutingChangedEvent(routing: routing);
        _eventController.add(event);
        break;
      case 'onStreamMessage':
        final uid = call.arguments['uid'] as String;
        final streamId = call.arguments['streamId'] as int;
        final data = List<int>.from(call.arguments['data'] ?? []);
        final event = SyStreamMessageEvent(uid: uid, streamId: streamId, data: data);
        _eventController.add(event);
        _eventHandler?.onStreamMessage?.call(uid, streamId, data);
        break;
      case 'onStreamMessageError':
        final uid = call.arguments['uid'] as String;
        final streamId = call.arguments['streamId'] as int;
        final code = call.arguments['code'] as int? ?? 0;
        final missed = call.arguments['missed'] as int? ?? 0;
        final cached = call.arguments['cached'] as int? ?? 0;
        final event = SyStreamMessageErrorEvent(
          uid: uid,
          streamId: streamId,
          code: code,
          missed: missed,
          cached: cached,
        );
        _eventController.add(event);
        _eventHandler?.onStreamMessageError?.call(uid, streamId, code, missed, cached);
        break;
      case 'onChannelMessage':
        final uid = call.arguments['uid'] as String? ?? '';
        final message = call.arguments['message'] as String? ?? '';
        final rawEvent = SyChannelMessageEvent(uid: uid, message: message);
        _eventController.add(rawEvent);
        _eventHandler?.onChannelMessage?.call(uid, message);
        _dispatchRoomMessage(uid, message);
        break;
      case 'onFirstRemoteVideoDecoded':
        final uid = call.arguments['uid'] as String;
        final width = call.arguments['width'] as int? ?? 0;
        final height = call.arguments['height'] as int? ?? 0;
        final elapsed = call.arguments['elapsed'] as int? ?? 0;
        final event = SyFirstRemoteVideoDecodedEvent(
          uid: uid,
          width: width,
          height: height,
          elapsed: elapsed,
        );
        _eventController.add(event);
        break;
      case 'onFirstRemoteVideoFrame':
        final uid = call.arguments['uid'] as String;
        final width = call.arguments['width'] as int? ?? 0;
        final height = call.arguments['height'] as int? ?? 0;
        final elapsed = call.arguments['elapsed'] as int? ?? 0;
        final event = SyFirstRemoteVideoFrameEvent(
          uid: uid,
          width: width,
          height: height,
          elapsed: elapsed,
        );
        _eventController.add(event);
        break;
      case 'onVideoSizeChanged':
        final uid = call.arguments['uid'] as String;
        final width = call.arguments['width'] as int? ?? 0;
        final height = call.arguments['height'] as int? ?? 0;
        final rotation = call.arguments['rotation'] as int? ?? 0;
        final event = SyVideoSizeChangedEvent(
          uid: uid,
          width: width,
          height: height,
          rotation: rotation,
        );
        _eventController.add(event);
        break;
      case 'onError':
        final errCode = call.arguments['errCode'] as int? ?? 0;
        final errMsg = call.arguments['errMsg'] as String? ?? 'Unknown error';
        final event = SyErrorEvent(errCode: errCode, errMsg: errMsg);
        _eventController.add(event);
        _eventHandler?.onError?.call(errCode, errMsg);
        break;
        default:
          break;
      }
    } catch (e, st) {
      debugPrint('SyRtcEngine event error: ${call.method} $e $st');
      final errMsg = e.toString();
      _eventController.add(SyErrorEvent(errCode: -1, errMsg: errMsg));
      _eventHandler?.onError?.call(-1, errMsg);
    }
    return null;
  }

  void _dispatchRoomMessage(String uid, String rawMessage) {
    try {
      final map = jsonDecode(rawMessage) as Map<String, dynamic>;
      if (map['_sy_type'] != 'room-msg') return;
      final action = map['action'] as String?;
      final data = map['data'] as Map<String, dynamic>? ?? {};

      switch (action) {
        case 'room-info-update':
          final info = data['roomInfo'] as Map<String, dynamic>? ?? {};
          final e = SyRoomInfoUpdatedEvent(operatorUid: uid, roomInfo: info);
          _eventController.add(e);
          _eventHandler?.onRoomInfoUpdated?.call(uid, info);
          break;

        case 'room-notice-update':
          final notice = data['notice'] as String? ?? '';
          final e = SyRoomNoticeUpdatedEvent(operatorUid: uid, notice: notice);
          _eventController.add(e);
          _eventHandler?.onRoomNoticeUpdated?.call(uid, notice);
          break;

        case 'manager-update':
          final targetUid = data['uid'] as String? ?? '';
          final isManager = data['isManager'] as bool? ?? false;
          final e = SyRoomManagerUpdatedEvent(uid: targetUid, isManager: isManager, operatorUid: uid);
          _eventController.add(e);
          _eventHandler?.onRoomManagerUpdated?.call(targetUid, isManager, uid);
          break;

        case 'seat-take':
          final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
          final muted = data['muted'] as bool? ?? false;
          final seat = SySeatInfo(index: seatIndex, uid: uid, isMuted: muted);
          final e = SySeatUpdatedEvent(seat: seat, operatorUid: uid, action: SySeatAction.take);
          _eventController.add(e);
          _eventHandler?.onSeatUpdated?.call(seat, uid, SySeatAction.take);
          break;

        case 'seat-leave':
          final seatIndex = (data['seatIndex'] as num?)?.toInt();
          final seat = SySeatInfo(index: seatIndex ?? -1, uid: null);
          final e = SySeatUpdatedEvent(seat: seat, operatorUid: uid, action: SySeatAction.leave);
          _eventController.add(e);
          _eventHandler?.onSeatUpdated?.call(seat, uid, SySeatAction.leave);
          break;

        case 'seat-kick':
          final targetUid = data['uid'] as String? ?? '';
          final seat = SySeatInfo(index: -1, uid: null);
          final e = SySeatUpdatedEvent(seat: seat, operatorUid: uid, action: SySeatAction.kick);
          _eventController.add(e);
          _eventHandler?.onSeatUpdated?.call(seat, uid, SySeatAction.kick);
          break;

        case 'seat-lock':
          final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
          final locked = data['locked'] as bool? ?? true;
          final seat = SySeatInfo(index: seatIndex, isLocked: locked);
          final seatAction = locked ? SySeatAction.lock : SySeatAction.unlock;
          final e = SySeatUpdatedEvent(seat: seat, operatorUid: uid, action: seatAction);
          _eventController.add(e);
          _eventHandler?.onSeatUpdated?.call(seat, uid, seatAction);
          break;

        case 'seat-mute':
          final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
          final muted = data['muted'] as bool? ?? true;
          final seat = SySeatInfo(index: seatIndex, isMuted: muted);
          final seatAction = muted ? SySeatAction.mute : SySeatAction.unmute;
          final e = SySeatUpdatedEvent(seat: seat, operatorUid: uid, action: seatAction);
          _eventController.add(e);
          _eventHandler?.onSeatUpdated?.call(seat, uid, seatAction);
          break;

        case 'seat-request':
          final seatIndex = (data['seatIndex'] as num?)?.toInt();
          final e = SySeatRequestReceivedEvent(uid: uid, seatIndex: seatIndex);
          _eventController.add(e);
          _eventHandler?.onSeatRequestReceived?.call(uid, seatIndex);
          break;

        case 'seat-request-cancel':
          break;

        case 'seat-request-handle':
          final approved = data['approved'] as bool? ?? false;
          final seatIndex = (data['seatIndex'] as num?)?.toInt();
          final e = SySeatRequestHandledEvent(operatorUid: uid, approved: approved, seatIndex: seatIndex);
          _eventController.add(e);
          _eventHandler?.onSeatRequestHandled?.call(uid, approved, seatIndex);
          break;

        case 'seat-invite':
          final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
          final e = SySeatInvitationReceivedEvent(operatorUid: uid, seatIndex: seatIndex);
          _eventController.add(e);
          _eventHandler?.onSeatInvitationReceived?.call(uid, seatIndex);
          break;

        case 'seat-invite-handle':
          final accepted = data['accepted'] as bool? ?? false;
          final seatIndex = (data['seatIndex'] as num?)?.toInt() ?? 0;
          final e = SySeatInvitationHandledEvent(uid: uid, accepted: accepted, seatIndex: seatIndex);
          _eventController.add(e);
          _eventHandler?.onSeatInvitationHandled?.call(uid, accepted, seatIndex);
          break;

        case 'user-kick':
          final targetUid = data['uid'] as String? ?? '';
          final e = SyUserKickedEvent(uid: targetUid, operatorUid: uid);
          _eventController.add(e);
          _eventHandler?.onUserKicked?.call(targetUid, uid);
          break;

        case 'user-mute':
          final targetUid = data['uid'] as String? ?? '';
          final muted = data['muted'] as bool? ?? true;
          final e = SyUserMutedEvent(uid: targetUid, isMuted: muted, operatorUid: uid);
          _eventController.add(e);
          _eventHandler?.onUserMuted?.call(targetUid, muted, uid);
          break;

        case 'user-ban':
          final targetUid = data['uid'] as String? ?? '';
          final banned = data['banned'] as bool? ?? true;
          final e = SyUserBannedEvent(uid: targetUid, isBanned: banned, operatorUid: uid);
          _eventController.add(e);
          _eventHandler?.onUserBanned?.call(targetUid, banned, uid);
          break;

        case 'room-chat':
          final msgTypeStr = data['messageType'] as String? ?? 'text';
          final content = data['content'] as String? ?? '';
          final extra = data['extra'] as Map<String, dynamic>?;
          final msgType = SyRoomMessageType.values.firstWhere(
            (t) => t.name == msgTypeStr, orElse: () => SyRoomMessageType.text);
          final e = SyRoomMessageEvent(uid: uid, messageType: msgType, content: content, extra: extra);
          _eventController.add(e);
          _eventHandler?.onRoomMessage?.call(uid, msgType, content, extra);
          break;

        case 'gift':
          final giftId = data['giftId'] as String? ?? '';
          final toUid = data['toUid'] as String? ?? '';
          final count = (data['count'] as num?)?.toInt() ?? 1;
          final extra = data['extra'] as Map<String, dynamic>?;
          final e = SyGiftReceivedEvent(fromUid: uid, toUid: toUid, giftId: giftId, count: count, extra: extra);
          _eventController.add(e);
          _eventHandler?.onGiftReceived?.call(uid, toUid, giftId, count, extra);
          break;
      }
    } catch (_) {}
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}
