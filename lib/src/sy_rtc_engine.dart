import 'dart:async';
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
  static const MethodChannel _eventsChannel =
      MethodChannel('sy_rtc_flutter_sdk/events');
  static final SyRtcEngine _instance = SyRtcEngine._internal();
  static bool _methodHandlerRegistered = false;

  SyRtcEventHandler? _eventHandler;
  final StreamController<SyRtcEvent> _eventController =
      StreamController<SyRtcEvent>.broadcast();

  final Map<String, bool> _remoteAudioMuted = {};
  final Map<String, bool> _serverAudioMuted = {};

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
  /// - wss://syrtcapi.shengyuchenyao.cn/ws/signaling
  /// - wss://your-domain.com/ws/signaling
  Future<void> init(String appId,
      {String? apiBaseUrl, String? signalingUrl}) async {
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
  /// 用于调用需要登录认证的后端业务接口。
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
      // 返回格式: {"features": ["rtc"]}
      await _invoke<void>('checkFeatures', {
        'appId': appId,
        'apiBaseUrl': apiBaseUrl,
      });
    } catch (e) {
      // 权限检查失败不影响初始化，默认只有语聊功能
      debugPrint('功能权限检查失败: $e');
    }
  }

  /// 检查是否开通了指定功能
  Future<bool> hasFeature(String feature) async {
    final result =
        await _channel.invokeMethod('hasFeature', {'feature': feature});
    return result as bool? ?? false;
  }

  /// 检查是否开通了 RTC 产品（音视频一体）
  Future<bool> hasRtcFeature() async {
    return hasFeature('rtc');
  }

  /// 兼容旧名：等同于 [hasRtcFeature]
  Future<bool> hasVoiceFeature() async {
    return hasRtcFeature();
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

  /// 本端音频是否已静音。读原生轨道状态，不是上次调用的缓存。
  ///
  /// 服务端静音不一定改这个值，请同时听 [onServerMuteAudio]。
  Future<bool> isLocalAudioMuted() async {
    final value = await _channel.invokeMethod<bool>('isLocalAudioMuted');
    return value ?? false;
  }

  /// 指定远端的音频是否被本端静音。
  ///
  /// Android 查询原生记录。iOS 没有这个查询，返回 null。
  /// 最近一次 [onUserMuteAudio] 仍可从 [remoteAudioMuted] 读取。
  Future<bool?> isRemoteAudioMuted(String uid) async {
    return _channel.invokeMethod<bool>('isRemoteAudioMuted', {'uid': uid});
  }

  /// 最近一次 [onUserMuteAudio] 里该用户的静音标志。尚未回调时为 null。
  bool? remoteAudioMuted(String uid) => _remoteAudioMuted[uid];

  /// 最近一次 [onServerMuteAudio] 里该用户的静音标志。原生尚未回调时为 null。
  bool? serverAudioMuted(String uid) => _serverAudioMuted[uid];

  /// 发送频道消息（广播给频道内所有用户）
  ///
  /// [message] 消息内容（通常为JSON字符串）
  Future<void> sendChannelMessage(String message) async {
    await _channel.invokeMethod('sendChannelMessage', {'message': message});
  }

  /// 设置客户端角色
  ///
  /// [role] host|audience|publisher|subscriber（audience/subscriber 本地不推流）
  Future<void> setClientRole(String role) async {
    await _channel.invokeMethod('setClientRole', {'role': role});
  }

  /// 设置频道场景
  ///
  /// [profile] 场景：'communication'（通信）或 'liveBroadcasting'（直播）
  /// 必须在 join 之前调用。
  Future<void> setChannelProfile(String profile) async {
    await _channel.invokeMethod('setChannelProfile', {'profile': profile});
  }

  /// 启用用户音量提示
  ///
  /// 启用后，SDK 会按设定间隔触发 onVolumeIndication 回调。
  /// [interval] 回调间隔（毫秒），建议 200ms。设为 0 禁用。
  /// [smooth] 平滑系数，建议 3
  /// [reportVad] iOS 会在能量大于 0.02 时把 `vad` 置 1。Android 接受该参数，
  /// 但回调里没有人声检测，插件把 `vad` 填 0。
  ///
  /// `volume` 两端都是 0–255。Android 来自本地/远端 PCM 的 RMS。
  /// iOS 来自 WebRTC `audioLevel`（0–1）乘 255。没有统计样本时音量为 0，不是占位常数。
  Future<void> enableAudioVolumeIndication({
    int interval = 200,
    int smooth = 3,
    bool reportVad = false,
  }) async {
    await _channel.invokeMethod('enableAudioVolumeIndication', {
      'interval': interval,
      'smooth': smooth,
      'reportVad': reportVad,
    });
  }

  /// 设置事件处理器
  void setEventHandler(SyRtcEventHandler handler) {
    _eventHandler = handler;
  }

  /// 全部事件的广播流（可用于自定义事件分发）
  Stream<SyRtcEvent> get events => _eventController.stream;

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

  /// 被踢出房间事件流
  Stream<SyKickedEvent> get onKicked {
    return _eventController.stream
        .where((event) => event is SyKickedEvent)
        .cast<SyKickedEvent>();
  }

  /// 服务端静音事件流
  Stream<SyServerMuteAudioEvent> get onServerMuteAudio {
    return _eventController.stream
        .where((event) => event is SyServerMuteAudioEvent)
        .cast<SyServerMuteAudioEvent>();
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

  /// 连接状态变化事件流。
  ///
  /// 重连策略两端不同，插件不统一次数：
  /// Android 信令失败最多再试 3 次（间隔 1 秒乘已尝试次数），用尽后 `state=failed`，
  /// `onError` 码 1003。ICE 断开会 `restartIce`，恢复后回调 `onRejoinChannelSuccess`。
  /// iOS 信令按 1、2、4、8、16 秒退避，最多 5 次，用尽后 `nativeReason=signaling_give_up`，
  /// `onError` 码 1005。信令重新连上后也会回调 `onRejoinChannelSuccess`。
  /// 看原生原因请用 [SyConnectionStateChangedEvent.nativeReason]，不要只看枚举。
  Stream<SyConnectionStateChangedEvent> get onConnectionStateChanged {
    return _eventController.stream
        .where((event) => event is SyConnectionStateChangedEvent)
        .cast<SyConnectionStateChangedEvent>();
  }

  /// 网络质量事件流。
  ///
  /// 由本机 RTT 和丢包算出。请读事件里的 [SyNetworkQualityEvent.txLevel] /
  /// [SyNetworkQualityEvent.rxLevel]（两端统一的 [SyNetworkQualityLevel]）。
  /// 没有样本时为 unknown。旧字段 txQuality / rxQuality 保留原生名字。
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

  /// 流附加信息事件流。同一条原文仍会先出现在 [onChannelMessage]。
  Stream<SyStreamExtraInfoEvent> get onStreamExtraInfoUpdated {
    return _eventController.stream
        .where((event) => event is SyStreamExtraInfoEvent)
        .cast<SyStreamExtraInfoEvent>();
  }

  /// Android DataChannel SEI 风格消息。iOS 不会产生这个流。
  Stream<SySeiMessageEvent> get onSeiMessage {
    return _eventController.stream
        .where((event) => event is SySeiMessageEvent)
        .cast<SySeiMessageEvent>();
  }

  /// iOS 远端视频静音。Android 没有这个事件。
  Stream<SyUserMuteVideoEvent> get onUserMuteVideo {
    return _eventController.stream
        .where((event) => event is SyUserMuteVideoEvent)
        .cast<SyUserMuteVideoEvent>();
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

  // ==================== 音频路由控制 ====================

  /// 开启/关闭扬声器
  Future<void> setEnableSpeakerphone(bool enabled) async {
    await _channel.invokeMethod('setEnableSpeakerphone', {'enabled': enabled});
  }

  /// 设置默认音频路由
  Future<void> setDefaultAudioRouteToSpeakerphone(bool enabled) async {
    await _channel.invokeMethod(
        'setDefaultAudioRouteToSpeakerphone', {'enabled': enabled});
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
    await _channel
        .invokeMethod('adjustPlaybackSignalVolume', {'volume': volume});
  }

  // ==================== Token 刷新 ====================

  /// 更新 Token
  Future<void> renewToken(String token) async {
    await _channel.invokeMethod('renewToken', {'token': token});
  }

  // ==================== 音频参数配置 ====================

  /// 设置音频配置
  Future<void> setAudioProfile(
      SyAudioProfile profile, SyAudioScenario scenario) async {
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

  /// 获取音频采集设备列表。
  ///
  /// Android 来自 `AudioManager` 的输入设备。
  /// iOS 来自 `AVAudioSession.availableInputs`。会话还没配成可录音、或系统没有输入口时为空列表，
  /// 不再返回写死的「默认麦克风」。
  Future<List<SyAudioDeviceInfo>> enumerateRecordingDevices() async {
    final result = await _channel.invokeMethod('enumerateRecordingDevices');
    final List<dynamic> devices = result as List<dynamic>? ?? [];
    return devices
        .map((d) => SyAudioDeviceInfo(
              deviceId: d['deviceId'] as String,
              deviceName: d['deviceName'] as String,
            ))
        .toList();
  }

  /// 获取音频播放设备列表。
  ///
  /// Android 来自 `AudioManager` 的输出设备。
  /// iOS 只返回能真正切换的两项：`speaker`、`earpiece`。蓝牙和有线耳机只通过 [onAudioRoutingChanged] 上报。
  Future<List<SyAudioDeviceInfo>> enumeratePlaybackDevices() async {
    final result = await _channel.invokeMethod('enumeratePlaybackDevices');
    final List<dynamic> devices = result as List<dynamic>? ?? [];
    return devices
        .map((d) => SyAudioDeviceInfo(
              deviceId: d['deviceId'] as String,
              deviceName: d['deviceName'] as String,
            ))
        .toList();
  }

  /// 设置音频采集设备。
  ///
  /// iOS 用 `setPreferredInput`，找不到该 uid 时返回 -1。Android 返回原生结果。
  Future<int> setRecordingDevice(String deviceId) async {
    final value = await _channel.invokeMethod<int>('setRecordingDevice', {
      'deviceId': deviceId,
    });
    return value ?? -1;
  }

  /// 设置音频播放设备。
  ///
  /// iOS 只接受 `speaker` 和 `earpiece`，其它 id 返回 -1。
  Future<int> setPlaybackDevice(String deviceId) async {
    final value = await _channel.invokeMethod<int>('setPlaybackDevice', {
      'deviceId': deviceId,
    });
    return value ?? -1;
  }

  /// 获取采集设备音量。
  ///
  /// 这是系统设备音量，不是 [enableAudioVolumeIndication] 的 0–255 说话音量。
  /// iOS 不提供输入音量读取，原生固定返回 0。
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

  /// 获取网络类型。
  ///
  /// iOS 用 `NWPathMonitor`，可能是 `wifi`、`cellular`、`ethernet`、`none`、`unknown`。
  /// 监视器在进房后才启动，在那之前是 `unknown`。
  /// Android 3.2.0 的 `getNetworkType()` 固定返回 `unknown`，插件不另外猜测 Wi-Fi 或蜂窝。
  Future<String> getNetworkType() async {
    final result = await _channel.invokeMethod('getNetworkType');
    return result as String? ?? 'unknown';
  }

  // ==================== 音频采集控制 ====================

  /// 调节采集音量（0-400，100为原始音量）
  Future<void> adjustRecordingSignalVolume(int volume) async {
    await _channel
        .invokeMethod('adjustRecordingSignalVolume', {'volume': volume});
  }

  /// 静音采集信号
  Future<void> muteRecordingSignal(bool muted) async {
    await _channel.invokeMethod('muteRecordingSignal', {'muted': muted});
  }

  // ==================== 视频基础功能 ====================

  /// 启用视频模块（需要 rtc 产品权限）
  ///
  /// [quality] 视频画质预设（可选，默认标准画质）
  Future<void> enableVideo({SyVideoQualityPreset? quality}) async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频功能');
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
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频功能');
    }

    final configMap = preset.toEncoderConfigMap();
    await _channel.invokeMethod('setVideoEncoderConfiguration', configMap);
  }

  /// 按后端画质档位切换本地编码。
  ///
  /// 档位与 `POST /api/rtc/token?qualityTier=` 一致：`audio`、`sd`、`hd`、`fhd`。
  /// 只改本地编码；`audio` 会关闭视频模块。不会向业务服务器申请新 Token。
  /// 若服务端按 Token 里的 qualityTier 限流，请先用 `SyRoomService.fetchToken`
  /// 传入同一档位，再调用 [renewToken]。
  Future<void> setQualityTier(SyQualityTier tier) async {
    switch (tier) {
      case SyQualityTier.audio:
        await setAudioQuality(SyAudioQualityLevel.medium);
        await disableVideo();
      case SyQualityTier.sd:
      case SyQualityTier.hd:
      case SyQualityTier.fhd:
        final preset = tier.videoPreset;
        if (preset != null) {
          await setVideoQuality(preset);
        }
    }
    await _channel.invokeMethod('setQualityTier', {'tier': tier.wireValue});
  }

  /// 切换画质档位：先保存新 Token，再改本地编码。
  ///
  /// [token] 必须由业务服务器按同一个 [tier] 重新签发
  /// （`POST /api/rtc/token?qualityTier=`）。本方法不会自己请求服务器。
  Future<void> switchQualityTier({
    required SyQualityTier tier,
    required String token,
  }) async {
    await renewToken(token);
    await setQualityTier(tier);
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

  /// 启用/禁用本地视频采集（需要 rtc 产品权限）
  Future<void> enableLocalVideo(bool enabled) async {
    if (enabled) {
      final hasRtc = await hasRtcFeature();
      if (!hasRtc) {
        throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频功能');
      }
    }
    await _channel.invokeMethod('enableLocalVideo', {'enabled': enabled});
  }

  /// 设置视频编码配置
  Future<void> setVideoEncoderConfiguration(
      SyVideoEncoderConfiguration config) async {
    await _channel.invokeMethod('setVideoEncoderConfiguration', {
      'width': config.width,
      'height': config.height,
      'frameRate': config.frameRate,
      'minFrameRate': config.minFrameRate,
      'bitrate': config.bitrate,
      'minBitrate': config.minBitrate,
      'orientationMode': config.orientationMode.toString().split('.').last,
      'degradationPreference':
          config.degradationPreference.toString().split('.').last,
      'mirrorMode': config.mirrorMode.toString().split('.').last,
    });
  }

  /// 开启视频预览（需要 rtc 产品权限）
  Future<void> startPreview() async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频预览');
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

  /// 本端视频是否已静音。读原生轨道状态。
  Future<bool> isLocalVideoMuted() async {
    final value = await _channel.invokeMethod<bool>('isLocalVideoMuted');
    return value ?? false;
  }

  /// 指定远端的视频是否被本端静音。
  ///
  /// Android 查询原生记录。iOS 没有这个查询，返回 null。
  Future<bool?> isRemoteVideoMuted(String uid) async {
    return _channel.invokeMethod<bool>('isRemoteVideoMuted', {'uid': uid});
  }

  /// 在前后摄像头之间切换。
  ///
  /// Android：0 已发起切换，-1 当前没有摄像头采集器（屏幕共享或自定义采集）。
  /// iOS：有引擎时返回 0。原生方法没有失败码，切换失败时走 `onError`。
  Future<int> switchCamera() async {
    final value = await _channel.invokeMethod<int>('switchCamera');
    return value ?? -1;
  }

  /// 指定使用前置或后置摄像头。
  ///
  /// iOS 调用 `useFrontCamera`，有引擎时返回 0。
  /// Android 没有这个方法，返回 -2。请改用 [switchCamera]。
  Future<int> useFrontCamera(bool front) async {
    final value = await _channel.invokeMethod<int>('useFrontCamera', {
      'front': front,
    });
    return value ?? -1;
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

  /// 设置本地视频视图（需要 rtc 产品权限）
  Future<void> setupLocalVideo(int viewId) async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频渲染');
    }
    await _channel.invokeMethod('setupLocalVideo', {'viewId': viewId});
  }

  /// 设置远端视频视图（需要 rtc 产品权限）
  Future<void> setupRemoteVideo(String uid, int viewId) async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频渲染');
    }
    await _channel.invokeMethod('setupRemoteVideo', {
      'uid': uid,
      'viewId': viewId,
    });
  }

  // ==================== 屏幕共享 ====================

  /// 开始屏幕共享（需要 rtc 产品权限）。
  ///
  /// Android 会先弹出 MediaProjection 授权。用户同意后，插件把 Intent 交给
  /// `startScreenCapture(intent, config)`，帧进入本地视频轨。返回 0 表示采集已启动，
  /// -1 表示没有 Activity、用户拒绝或创建失败。本 SDK 没有 mediaProjection 前台服务；
  /// Android 10 及以上系统可能因此拒绝采集，需要宿主自行声明该服务。
  ///
  /// iOS 使用应用内 ReplayKit，帧进入 WebRTC。返回 0 只表示调用已发出，
  /// 用户拒绝或启动失败时走 `onError`（1008），不会把返回值改成失败。
  /// 这是应用内采集，不是 Broadcast Upload Extension 的跨进程共享。
  Future<int> startScreenCapture(SyScreenCaptureConfiguration config) async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用屏幕共享');
    }
    final value = await _channel.invokeMethod<int>('startScreenCapture', {
      'captureMouseCursor': config.captureMouseCursor,
      'captureWindow': config.captureWindow,
      'frameRate': config.frameRate,
      'bitrate': config.bitrate,
      'width': config.width,
      'height': config.height,
    });
    return value ?? -1;
  }

  /// 停止屏幕共享
  Future<void> stopScreenCapture() async {
    await _channel.invokeMethod('stopScreenCapture');
  }

  /// 更新屏幕共享配置
  Future<void> updateScreenCaptureConfiguration(
      SyScreenCaptureConfiguration config) async {
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

  /// 停掉摄像头，改由原生侧喂帧。
  ///
  /// Android 返回 0 表示已切换，-1 表示引擎未就绪。之后要调用
  /// `pushExternalVideoFrame(org.webrtc.VideoFrame)`，方法通道传不过这种帧。
  /// iOS 调用 `enableCustomVideoCapture`，有引擎时返回 0；帧要通过
  /// `sendCustomVideoFrame(CVPixelBuffer)` 送入，同样不能从 Dart 传像素。
  /// 插件不提供字节数组推帧，避免假装已经送进编码器。
  Future<int> enableCustomVideoCapture(bool enabled) async {
    final value = await _channel.invokeMethod<int>('enableCustomVideoCapture', {
      'enabled': enabled,
    });
    return value ?? -1;
  }

  /// 当前播放路由。名字已按平台翻译，见 [SyAudioRoute]。
  ///
  /// iOS 只能用 [setAudioRoute] 切到扬声器或听筒；蓝牙和有线耳机只在回调里出现。
  /// Android 能上报扬声器、听筒、耳机、蓝牙；主动切换同样只有扬声器和听筒。
  Future<SyAudioRoute> getAudioRoute() async {
    final value = await _channel.invokeMethod<Map<Object?, Object?>>('getAudioRoute');
    return SyAudioRoute.fromNative(
      name: value?['route'] as String?,
      routing: (value?['routing'] as num?)?.toInt(),
    );
  }

  /// 切换播放路由。
  ///
  /// 返回 0 表示已交给原生。扬声器和听筒两端都可以切。
  /// 耳机、蓝牙在两端都返回 -1：Android 只检测这些设备，iOS 会额外回调 `onError` 1004。
  Future<int> setAudioRoute(SyAudioRoute route) async {
    final value = await _channel.invokeMethod<int>('setAudioRoute', {
      'route': route.name,
    });
    return value ?? -1;
  }

  /// 设置美颜选项（需要 rtc 产品权限）。
  ///
  /// 打开后原生在编码前做提亮。自定义帧处理器是原生钩子
  /// （Android `VideoFrameProcessor`，iOS `SyRtcVideoFrameProcessor`），
  /// 会替换内置提亮。插件没有把视频帧回调到 Dart。
  Future<void> setBeautyEffectOptions(SyBeautyOptions options) async {
    if (options.enabled) {
      final hasRtc = await hasRtcFeature();
      if (!hasRtc) {
        throw Exception('当前 AppId 未开通 RTC 产品，无法使用美颜功能');
      }
    }
    await _channel.invokeMethod('setBeautyEffectOptions', {
      'enabled': options.enabled,
      'lighteningLevel': options.lighteningLevel,
      'rednessLevel': options.rednessLevel,
      'smoothnessLevel': options.smoothnessLevel,
    });
  }

  /// 视频截图（需要 rtc 产品权限）
  Future<void> takeSnapshot(String uid, String filePath) async {
    final hasRtc = await hasRtcFeature();
    if (!hasRtc) {
      throw Exception('当前 AppId 未开通 RTC 产品，无法使用视频截图');
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
    await _channel
        .invokeMethod('setAudioMixingPosition', {'position': position});
  }

  // ==================== 音效文件播放 ====================

  /// 播放音效
  Future<void> playEffect(
      int soundId, SyAudioEffectConfiguration config) async {
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
  Future<int> createDataStream(
      {bool reliable = true, bool ordered = true}) async {
    final result = await _channel.invokeMethod('createDataStream', {
      'reliable': reliable,
      'ordered': ordered,
    });
    return result as int? ?? 0;
  }

  /// 发送数据流消息。两端都走 DataChannel。
  Future<void> sendStreamMessage(int streamId, Uint8List data) async {
    await _channel.invokeMethod('sendStreamMessage', {
      'streamId': streamId,
      'data': data,
    });
  }

  /// 经 DataChannel 发送带 `SYSEI` 前缀的二进制。不是 H.264 码流 SEI。
  ///
  /// Android：0 已写入打开的通道，-1 流不存在或通道未打开。
  /// iOS 没有 `sendSei`，返回 -2。请改用 [sendStreamMessage]。
  Future<int> sendSei(int streamId, Uint8List data) async {
    final value = await _channel.invokeMethod<int>('sendSei', {
      'streamId': streamId,
      'data': data,
    });
    return value ?? -1;
  }

  /// 通过频道信令广播本端流附加信息。
  ///
  /// Android：未进房返回 -1，已发送返回 0。
  /// iOS 的原生方法没有返回值；引擎存在时插件返回 0，不表示对端已经收到。
  Future<int> setStreamExtraInfo(String extra) async {
    final value = await _channel.invokeMethod<int>('setStreamExtraInfo', {
      'extra': extra,
    });
    return value ?? -1;
  }

  /// 读取本端最近一次流附加信息。
  ///
  /// iOS 返回原生保存的字符串。Android 没有这个查询，返回 null。
  Future<String?> getStreamExtraInfo() {
    return _channel.invokeMethod<String>('getStreamExtraInfo');
  }


  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onJoinChannelSuccess':
          final channelId = call.arguments['channelId'] as String? ?? '';
          final uid = call.arguments['uid'] as String? ?? '';
          final elapsed = call.arguments['elapsed'] as int? ?? 0;
          final event = SyJoinChannelSuccessEvent(
              channelId: channelId, uid: uid, elapsed: elapsed);
          _eventController.add(event);
          _eventHandler?.onJoinChannelSuccess?.call(channelId, uid, elapsed);
          break;
        case 'onLeaveChannel':
          final statsMap =
              (call.arguments['stats'] as Map?)?.cast<Object?, Object?>() ??
                  const <Object?, Object?>{};
          final stats = SyRtcStats.fromMap(statsMap);
          final event = SyLeaveChannelEvent(stats: stats);
          _eventController.add(event);
          _eventHandler?.onLeaveChannel?.call(stats);
          break;
        case 'onRejoinChannelSuccess':
          final channelId = call.arguments['channelId'] as String? ?? '';
          final uid = call.arguments['uid'] as String? ?? '';
          final elapsed = call.arguments['elapsed'] as int? ?? 0;
          final event = SyRejoinChannelSuccessEvent(
              channelId: channelId, uid: uid, elapsed: elapsed);
          _eventController.add(event);
          _eventHandler?.onRejoinChannelSuccess?.call(channelId, uid, elapsed);
          break;
        case 'onRtcStats':
          final statsMap =
              (call.arguments['stats'] as Map?)?.cast<Object?, Object?>() ??
                  const <Object?, Object?>{};
          final stats = SyRtcStats.fromMap(statsMap);
          final event = SyRtcStatsEvent(stats: stats);
          _eventController.add(event);
          _eventHandler?.onRtcStats?.call(stats);
          break;
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
        case 'onUserMuteAudio':
          final uid = call.arguments['uid'] as String? ?? '';
          final muted = call.arguments['muted'] as bool? ?? false;
          if (uid.isNotEmpty) _remoteAudioMuted[uid] = muted;
          final event = SyUserMuteAudioEvent(uid: uid, muted: muted);
          _eventController.add(event);
          _eventHandler?.onUserMuteAudio?.call(uid, muted);
          break;
        case 'onKicked':
          final channelId = call.arguments['channelId'] as String? ?? '';
          final reason = call.arguments['reason'] as String? ?? '';
          final event = SyKickedEvent(channelId: channelId, reason: reason);
          _eventController.add(event);
          _eventHandler?.onKicked?.call(channelId, reason);
          break;
        case 'onServerMuteAudio':
          final uid = call.arguments['uid'] as String? ?? '';
          final muted = call.arguments['muted'] as bool? ?? false;
          if (uid.isNotEmpty) _serverAudioMuted[uid] = muted;
          final event = SyServerMuteAudioEvent(uid: uid, muted: muted);
          _eventController.add(event);
          _eventHandler?.onServerMuteAudio?.call(uid, muted);
          break;
        case 'onVolumeIndication':
          final event = SyVolumeIndicationEvent(
            speakers: List<Map<String, dynamic>>.from(
                call.arguments['speakers'] ?? []),
          );
          _eventController.add(event);
          _eventHandler?.onVolumeIndication?.call(event.speakers);
          break;
        case 'onTokenPrivilegeWillExpire':
          final event = SyTokenPrivilegeWillExpireEvent();
          _eventController.add(event);
          _eventHandler?.onTokenPrivilegeWillExpire?.call();
          break;
        case 'onRequestToken':
          final event = SyRequestTokenEvent();
          _eventController.add(event);
          _eventHandler?.onRequestToken?.call();
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
          final event = SyConnectionStateChangedEvent(
            state: state,
            reason: reason,
            nativeReason: reasonStr,
          );
          _eventController.add(event);
          _eventHandler?.onConnectionStateChanged?.call(state, reason);
          break;
        case 'onNetworkQuality':
          final uid = call.arguments['uid'] as String? ?? '0';
          final txStr = call.arguments['txQuality'] as String? ?? 'unknown';
          final rxStr = call.arguments['rxQuality'] as String? ?? 'unknown';
          final txQuality = syNetworkQualityFromNative(txStr);
          final rxQuality = syNetworkQualityFromNative(rxStr);
          final event = SyNetworkQualityEvent(
            uid: uid,
            txQuality: txQuality,
            rxQuality: rxQuality,
            txQualityRaw: txStr,
            rxQualityRaw: rxStr,
          );
          _eventController.add(event);
          _eventHandler?.onNetworkQuality?.call(uid, txQuality, rxQuality);
          _eventHandler?.onNetworkQualityLevel
              ?.call(uid, event.txLevel, event.rxLevel);
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
          _eventHandler?.onRemoteAudioStateChanged
              ?.call(uid, state, reason, elapsed);
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
          _eventHandler?.onRemoteVideoStateChanged
              ?.call(uid, state, reason, elapsed);
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
          final event =
              SyLocalAudioStateChangedEvent(state: state, error: error);
          _eventController.add(event);
          _eventHandler?.onLocalAudioStateChanged?.call(state, error);
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
          final event =
              SyLocalVideoStateChangedEvent(state: state, error: error);
          _eventController.add(event);
          _eventHandler?.onLocalVideoStateChanged?.call(state, error);
          break;
        case 'onAudioRoutingChanged':
          final routing = call.arguments['routing'] as int? ?? -1;
          final route = SyAudioRoute.fromNative(
            name: call.arguments['route'] as String?,
            routing: routing,
          );
          final event =
              SyAudioRoutingChangedEvent(routing: routing, route: route);
          _eventController.add(event);
          _eventHandler?.onAudioRoutingChanged?.call(routing);
          _eventHandler?.onAudioRoute?.call(route);
          break;
        case 'onStreamExtraInfoUpdated':
          final uid = call.arguments['uid'] as String? ?? '';
          final extra = call.arguments['extra'] as String? ?? '';
          final event = SyStreamExtraInfoEvent(uid: uid, extra: extra);
          _eventController.add(event);
          _eventHandler?.onStreamExtraInfoUpdated?.call(uid, extra);
          break;
        case 'onSeiMessage':
          final uid = call.arguments['uid'] as String? ?? '';
          final streamId = call.arguments['streamId'] as int? ?? 0;
          final data = List<int>.from(call.arguments['data'] ?? []);
          final event =
              SySeiMessageEvent(uid: uid, streamId: streamId, data: data);
          _eventController.add(event);
          _eventHandler?.onSeiMessage?.call(uid, streamId, data);
          break;
        case 'onUserMuteVideo':
          final uid = call.arguments['uid'] as String? ?? '';
          final muted = call.arguments['muted'] as bool? ?? false;
          final event = SyUserMuteVideoEvent(uid: uid, muted: muted);
          _eventController.add(event);
          _eventHandler?.onUserMuteVideo?.call(uid, muted);
          break;
        case 'onStreamMessage':
          final uid = call.arguments['uid'] as String;
          final streamId = call.arguments['streamId'] as int;
          final data = List<int>.from(call.arguments['data'] ?? []);
          final event =
              SyStreamMessageEvent(uid: uid, streamId: streamId, data: data);
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
          _eventHandler?.onStreamMessageError
              ?.call(uid, streamId, code, missed, cached);
          break;
        case 'onChannelMessage':
          final uid = call.arguments['uid'] as String? ?? '';
          final message = call.arguments['message'] as String? ?? '';
          final rawEvent = SyChannelMessageEvent(uid: uid, message: message);
          _eventController.add(rawEvent);
          _eventHandler?.onChannelMessage?.call(uid, message);
          break;
        case 'onFirstRemoteVideoDecoded':
          final uid = call.arguments['uid'] as String;
          final width = call.arguments['width'] as int? ?? 0;
          final height = call.arguments['height'] as int? ?? 0;
          final elapsed = call.arguments['elapsed'] as int? ?? 0;
          final event = SyFirstRemoteVideoDecodedEvent(
              uid: uid, width: width, height: height, elapsed: elapsed);
          _eventController.add(event);
          _eventHandler?.onFirstRemoteVideoDecoded
              ?.call(uid, width, height, elapsed);
          break;
        case 'onFirstRemoteVideoFrame':
          final uid = call.arguments['uid'] as String;
          final width = call.arguments['width'] as int? ?? 0;
          final height = call.arguments['height'] as int? ?? 0;
          final elapsed = call.arguments['elapsed'] as int? ?? 0;
          final event = SyFirstRemoteVideoFrameEvent(
              uid: uid, width: width, height: height, elapsed: elapsed);
          _eventController.add(event);
          _eventHandler?.onFirstRemoteVideoFrame
              ?.call(uid, width, height, elapsed);
          break;
        case 'onVideoSizeChanged':
          final uid = call.arguments['uid'] as String;
          final width = call.arguments['width'] as int? ?? 0;
          final height = call.arguments['height'] as int? ?? 0;
          final rotation = call.arguments['rotation'] as int? ?? 0;
          final event = SyVideoSizeChangedEvent(
              uid: uid, width: width, height: height, rotation: rotation);
          _eventController.add(event);
          _eventHandler?.onVideoSizeChanged?.call(uid, width, height, rotation);
          break;
        case 'onError':
          final errCode = call.arguments['errCode'] as int? ?? 0;
          final errMsg = call.arguments['errMsg'] as String? ?? 'Unknown error';
          final tokenCode = SyTokenBusinessCode.tryParse(errCode);
          if (tokenCode != null) {
            final tokenEvent =
                SyTokenErrorEvent(code: tokenCode, message: errMsg);
            _eventController.add(tokenEvent);
            _eventHandler?.onTokenError?.call(tokenCode, errMsg);
          }
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

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}
