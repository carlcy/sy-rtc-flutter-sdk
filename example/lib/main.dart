import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
import 'package:sy_rtc_flutter_sdk/src/sy_rtc_config_extended.dart';
import 'package:sy_rtc_flutter_sdk/src/sy_rtc_video_quality.dart';
import 'app_config.dart';
import 'live_control_page.dart';
import 'token_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SY RTC Flutter 示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RtcDemoPage(),
    );
  }
}

class RtcDemoPage extends StatefulWidget {
  const RtcDemoPage({super.key});

  @override
  State<RtcDemoPage> createState() => _RtcDemoPageState();
}

class _RtcDemoPageState extends State<RtcDemoPage> {
  final _engine = SyRtcEngine();
  AppConfig? _config;
  TokenService? _tokenService;

  // 部署后默认连 Demo 后端（可改为你的服务器 IP）
  final _apiBaseController = TextEditingController(
    text: 'http://47.105.48.196/demo-api',
  );
  final _signalingController = TextEditingController(
    text: 'ws://47.105.48.196/ws/signaling',
  );
  final _appIdController = TextEditingController(text: 'your_app_id');
  final _jwtController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _channelIdController = TextEditingController(text: 'channel_001');
  final _uidController = TextEditingController(text: 'user_001');
  final _tokenController = TextEditingController(text: '');
  final _remoteUidController = TextEditingController(text: 'remote_user');
  final _audioMixingPathController = TextEditingController(text: '');
  final _audioEffectPathController = TextEditingController(text: '');
  final _recordingPathController = TextEditingController(text: '');
  final _streamMessageController = TextEditingController(text: 'hello');

  String _status = '未初始化';
  bool _initialized = false;
  bool _inChannel = false;
  bool _muted = false;
  bool _speakerphone = false;
  String _role = 'host';
  SyAudioProfile _audioProfile = SyAudioProfile.defaultProfile;
  SyAudioScenario _audioScenario = SyAudioScenario.defaultScenario;
  SyAudioQualityLevel _audioQuality = SyAudioQualityLevel.medium;
  int _playbackVolume = 100;
  int _recordingVolume = 100;
  int _dataStreamId = 0;
  int _effectId = 1;
  final List<String> _logs = [];

  StreamSubscription<SyUserJoinedEvent>? _userJoinedSub;
  StreamSubscription<SyUserOfflineEvent>? _userOfflineSub;
  StreamSubscription<SyVolumeIndicationEvent>? _volumeSub;
  StreamSubscription<SyErrorEvent>? _errorSub;
  StreamSubscription<SyStreamMessageEvent>? _streamMessageSub;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _userJoinedSub = _engine.onUserJoined.listen((e) {
      _addLog('用户加入: ${e.uid}');
      if (mounted) setState(() => _status = '用户加入: ${e.uid}');
    });
    _userOfflineSub = _engine.onUserOffline.listen((e) {
      _addLog('用户离开: ${e.uid}');
      if (mounted) setState(() => _status = '用户离开: ${e.uid}');
    });
    _volumeSub = _engine.onVolumeIndication.listen((e) {
      if (mounted && e.speakers.isNotEmpty) {
        setState(() => _status = '音量: ${e.speakers.length} 人');
      }
    });
    _errorSub = _engine.onError.listen((e) {
      _addLog('错误: ${e.errCode} ${e.errMsg}');
      if (mounted) setState(() => _status = '错误: ${e.errCode} ${e.errMsg}');
    });
    _streamMessageSub = _engine.onStreamMessage.listen((e) {
      _addLog('数据流消息: uid=${e.uid}, streamId=${e.streamId}, size=${e.data.length}');
    });
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()} $message');
      if (_logs.length > 200) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _saveAndInit() async {
    final apiBase = _apiBaseController.text.trim();
    final signaling = _signalingController.text.trim();
    final appId = _appIdController.text.trim();
    if (apiBase.isEmpty || signaling.isEmpty || appId.isEmpty) {
      setState(() => _status = '请填写 API 地址、信令地址和 AppId');
      return;
    }
    setState(() => _status = '正在初始化...');
    try {
      _config = AppConfig(
        apiBaseUrl: apiBase,
        signalingUrl: signaling,
        appId: appId,
        jwt: _jwtController.text.trim().isEmpty ? null : _jwtController.text.trim(),
        appSecret: _appSecretController.text.trim().isEmpty ? null : _appSecretController.text.trim(),
      );
      _tokenService = TokenService(_config!);

      await _engine.init(
        _config!.appId,
        apiBaseUrl: _config!.apiBaseUrl,
        signalingUrl: _config!.signalingUrl,
      );
      if (_config!.jwt != null && _config!.jwt!.isNotEmpty) {
        await _engine.setApiAuthToken(_config!.jwt!);
      }

      final hasVoice = await _engine.hasVoiceFeature();
      final hasLive = await _engine.hasLiveFeature();
      setState(() {
        _initialized = true;
        _status = '初始化成功 | 语聊=$hasVoice, 直播=$hasLive';
      });
    } catch (e) {
      setState(() => _status = '初始化失败: $e');
    }
  }

  Future<void> _fetchToken() async {
    if (_tokenService == null) {
      setState(() => _status = '请先保存并初始化');
      return;
    }
    final channelId = _channelIdController.text.trim();
    final uid = _uidController.text.trim();
    if (channelId.isEmpty || uid.isEmpty) {
      setState(() => _status = '请填写频道 ID 和用户 ID');
      return;
    }
    setState(() => _status = '正在拉取 Token...');
    try {
      final token = await _tokenService!.fetchRtcToken(
        channelId: channelId,
        uid: uid,
      );
      _tokenController.text = token;
      setState(() => _status = 'Token 已拉取');
    } catch (e) {
      setState(() => _status = '拉取 Token 失败: $e');
    }
  }

  Future<void> _joinChannel() async {
    if (!_initialized) {
      setState(() => _status = '请先保存并初始化');
      return;
    }
    final channelId = _channelIdController.text.trim();
    final uid = _uidController.text.trim();
    final token = _tokenController.text.trim();
    if (channelId.isEmpty || uid.isEmpty || token.isEmpty) {
      setState(() => _status = '请填写频道 ID、用户 ID 和 Token（可点击拉取 Token）');
      return;
    }
    setState(() => _status = '正在加入...');
    try {
      await _engine.join(channelId, uid, token);
      setState(() {
        _inChannel = true;
        _status = '已加入 $channelId';
      });
    } catch (e) {
      setState(() => _status = '加入失败: $e');
    }
  }

  Future<void> _leaveChannel() async {
    if (!_inChannel) return;
    setState(() => _status = '正在离开...');
    try {
      await _engine.leave();
      setState(() {
        _inChannel = false;
        _status = '已离开频道';
      });
    } catch (e) {
      setState(() => _status = '离开失败: $e');
    }
  }

  Future<void> _toggleMute() async {
    if (!_inChannel) return;
    try {
      _muted = !_muted;
      await _engine.muteLocalAudio(_muted);
      setState(() => _status = _muted ? '已静音' : '已取消静音');
    } catch (e) {
      _muted = !_muted;
      setState(() => _status = '静音操作失败: $e');
    }
  }

  Future<void> _toggleSpeakerphone() async {
    if (!_inChannel) return;
    try {
      _speakerphone = !_speakerphone;
      await _engine.setEnableSpeakerphone(_speakerphone);
      setState(() => _status = _speakerphone ? '已切换扬声器' : '已切换听筒');
    } catch (e) {
      _speakerphone = !_speakerphone;
      setState(() => _status = '扬声器切换失败: $e');
    }
  }

  Future<void> _applyClientRole(String role) async {
    if (!_inChannel) return;
    try {
      await _engine.setClientRole(role);
      setState(() {
        _role = role;
        _status = '角色已切换: $role';
      });
    } catch (e) {
      setState(() => _status = '切换角色失败: $e');
    }
  }

  Future<void> _applyAudioProfile() async {
    try {
      await _engine.setAudioProfile(_audioProfile, _audioScenario);
      setState(() => _status = '音频配置已应用');
    } catch (e) {
      setState(() => _status = '音频配置失败: $e');
    }
  }

  Future<void> _applyAudioQuality() async {
    try {
      await _engine.setAudioQuality(_audioQuality);
      setState(() => _status = '音频质量已设置');
    } catch (e) {
      setState(() => _status = '音频质量设置失败: $e');
    }
  }

  Future<void> _applyPlaybackVolume() async {
    try {
      await _engine.adjustPlaybackSignalVolume(_playbackVolume);
      setState(() => _status = '播放音量已设置: $_playbackVolume');
    } catch (e) {
      setState(() => _status = '播放音量设置失败: $e');
    }
  }

  Future<void> _applyRecordingVolume() async {
    try {
      await _engine.adjustRecordingSignalVolume(_recordingVolume);
      setState(() => _status = '采集音量已设置: $_recordingVolume');
    } catch (e) {
      setState(() => _status = '采集音量设置失败: $e');
    }
  }

  Future<void> _createDataStream() async {
    if (!_inChannel) return;
    try {
      final id = await _engine.createDataStream();
      setState(() {
        _dataStreamId = id;
        _status = '数据流已创建: $id';
      });
    } catch (e) {
      setState(() => _status = '创建数据流失败: $e');
    }
  }

  Future<void> _sendStreamMessage() async {
    if (!_inChannel || _dataStreamId <= 0) {
      setState(() => _status = '请先创建数据流');
      return;
    }
    try {
      final text = _streamMessageController.text;
      await _engine.sendStreamMessage(_dataStreamId, Uint8List.fromList(text.codeUnits));
      setState(() => _status = '数据流消息已发送');
    } catch (e) {
      setState(() => _status = '发送数据流消息失败: $e');
    }
  }

  Future<void> _startAudioMixing() async {
    final path = _audioMixingPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = '请填写音频文件路径');
      return;
    }
    try {
      await _engine.startAudioMixing(SyAudioMixingConfiguration(filePath: path));
      setState(() => _status = '开始音频混音');
    } catch (e) {
      setState(() => _status = '音频混音失败: $e');
    }
  }

  Future<void> _stopAudioMixing() async {
    try {
      await _engine.stopAudioMixing();
      setState(() => _status = '已停止音频混音');
    } catch (e) {
      setState(() => _status = '停止混音失败: $e');
    }
  }

  Future<void> _playEffect() async {
    final path = _audioEffectPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = '请填写音效文件路径');
      return;
    }
    try {
      await _engine.playEffect(_effectId, SyAudioEffectConfiguration(filePath: path));
      setState(() => _status = '音效已播放');
    } catch (e) {
      setState(() => _status = '播放音效失败: $e');
    }
  }

  Future<void> _stopEffect() async {
    try {
      await _engine.stopEffect(_effectId);
      setState(() => _status = '音效已停止');
    } catch (e) {
      setState(() => _status = '停止音效失败: $e');
    }
  }

  Future<void> _startRecording() async {
    final path = _recordingPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _status = '请填写录音文件路径');
      return;
    }
    try {
      await _engine.startAudioRecording(SyAudioRecordingConfiguration(filePath: path));
      setState(() => _status = '录音已开始');
    } catch (e) {
      setState(() => _status = '开始录音失败: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _engine.stopAudioRecording();
      setState(() => _status = '录音已停止');
    } catch (e) {
      setState(() => _status = '停止录音失败: $e');
    }
  }

  Future<void> _openLiveControl() async {
    if (!_initialized || _config == null) {
      setState(() => _status = '请先保存并初始化');
      return;
    }
    final hasLive = await _engine.hasLiveFeature();
    if (!hasLive) {
      setState(() => _status = '当前 AppId 未开通直播功能');
      return;
    }
    final channelId = _channelIdController.text.trim();
    final uid = _uidController.text.trim();
    final token = _tokenController.text.trim();
    if (channelId.isEmpty || uid.isEmpty || token.isEmpty) {
      setState(() => _status = '请填写频道 ID、用户 ID 和 Token 后再打开直播控制');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveControlPage(
          engine: _engine,
          channelId: channelId,
          uid: uid,
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SY RTC Flutter 示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('配置', [
              _field('API 基础 URL', _apiBaseController, hint: 'https://api.example.com'),
              _field('信令 URL', _signalingController, hint: 'wss://api.example.com/ws/signaling'),
              _field('AppId', _appIdController),
              _field('JWT（可选，用于后端认证/直播）', _jwtController, obscure: true),
              _field('AppSecret（仅demo）', _appSecretController, obscure: true),
              ElevatedButton(
                onPressed: _saveAndInit,
                child: const Text('保存并初始化'),
              ),
            ]),
            const SizedBox(height: 16),
            _section('状态', [
              Text(_status, style: const TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 16),
            _section('频道与 Token', [
              _field('频道 ID', _channelIdController),
              _field('用户 ID', _uidController),
              _field('RTC Token', _tokenController, obscure: true),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _fetchToken,
                    child: const Text('拉取 Token'),
                  ),
                  const SizedBox(width: 8),
                  Text('需先填 JWT 或 AppSecret 并初始化', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('频道操作', [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel ? null : _joinChannel,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('加入频道'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel ? _leaveChannel : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('离开频道'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _inChannel ? _toggleMute : null,
                child: Text(_muted ? '取消静音' : '静音'),
              ),
            ]),
            const SizedBox(height: 16),
            _section('语音控制', [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel ? _toggleSpeakerphone : null,
                      child: Text(_speakerphone ? '切换听筒' : '切换扬声器'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel ? () => _applyClientRole(_role == 'host' ? 'audience' : 'host') : null,
                      child: Text(_role == 'host' ? '切观众' : '切主播'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field('远端 UID（用于远端静音）', _remoteUidController),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel
                          ? () => _engine.muteRemoteAudioStream(_remoteUidController.text.trim(), true)
                          : null,
                      child: const Text('静音远端'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel
                          ? () => _engine.muteRemoteAudioStream(_remoteUidController.text.trim(), false)
                          : null,
                      child: const Text('取消静音远端'),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('音频配置', [
              DropdownButtonFormField<SyAudioProfile>(
                value: _audioProfile,
                decoration: const InputDecoration(labelText: '音频 Profile', border: OutlineInputBorder(), isDense: true),
                items: SyAudioProfile.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toString().split('.').last)))
                    .toList(),
                onChanged: (v) => setState(() => _audioProfile = v ?? _audioProfile),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SyAudioScenario>(
                value: _audioScenario,
                decoration: const InputDecoration(labelText: '音频 Scenario', border: OutlineInputBorder(), isDense: true),
                items: SyAudioScenario.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toString().split('.').last)))
                    .toList(),
                onChanged: (v) => setState(() => _audioScenario = v ?? _audioScenario),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SyAudioQualityLevel>(
                value: _audioQuality,
                decoration: const InputDecoration(labelText: '音频质量', border: OutlineInputBorder(), isDense: true),
                items: SyAudioQualityLevel.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toString().split('.').last)))
                    .toList(),
                onChanged: (v) => setState(() => _audioQuality = v ?? _audioQuality),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _applyAudioProfile,
                child: const Text('应用 Profile/Scenario'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _applyAudioQuality,
                child: const Text('应用音频质量'),
              ),
            ]),
            const SizedBox(height: 16),
            _section('音量设置', [
              Text('播放音量: $_playbackVolume'),
              Slider(
                value: _playbackVolume.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setState(() => _playbackVolume = v.toInt()),
                onChangeEnd: (_) => _applyPlaybackVolume(),
              ),
              Text('采集音量: $_recordingVolume'),
              Slider(
                value: _recordingVolume.toDouble(),
                min: 0,
                max: 400,
                divisions: 40,
                onChanged: (v) => setState(() => _recordingVolume = v.toInt()),
                onChangeEnd: (_) => _applyRecordingVolume(),
              ),
            ]),
            const SizedBox(height: 16),
            _section('音频文件', [
              _field('混音文件路径', _audioMixingPathController, hint: '/path/to/music.mp3'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startAudioMixing,
                      child: const Text('开始混音'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stopAudioMixing,
                      child: const Text('停止混音'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field('音效文件路径', _audioEffectPathController, hint: '/path/to/effect.wav'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playEffect,
                      child: const Text('播放音效'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stopEffect,
                      child: const Text('停止音效'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field('录音文件路径', _recordingPathController, hint: '/path/to/record.aac'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startRecording,
                      child: const Text('开始录音'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stopRecording,
                      child: const Text('停止录音'),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _section('数据流', [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _inChannel ? _createDataStream : null,
                      child: Text(_dataStreamId > 0 ? '重建数据流' : '创建数据流'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('streamId: $_dataStreamId'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field('消息内容', _streamMessageController),
              ElevatedButton(
                onPressed: _inChannel ? _sendStreamMessage : null,
                child: const Text('发送数据流消息'),
              ),
            ]),
            const SizedBox(height: 16),
            _section('直播', [
              ElevatedButton.icon(
                onPressed: _openLiveControl,
                icon: const Icon(Icons.live_tv),
                label: const Text('直播控制面板'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _section('事件日志', [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Text(
                    _logs[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        obscureText: obscure,
      ),
    );
  }

  @override
  void dispose() {
    _userJoinedSub?.cancel();
    _userOfflineSub?.cancel();
    _volumeSub?.cancel();
    _errorSub?.cancel();
    _streamMessageSub?.cancel();
    _apiBaseController.dispose();
    _signalingController.dispose();
    _appIdController.dispose();
    _jwtController.dispose();
    _appSecretController.dispose();
    _channelIdController.dispose();
    _uidController.dispose();
    _tokenController.dispose();
    _remoteUidController.dispose();
    _audioMixingPathController.dispose();
    _audioEffectPathController.dispose();
    _recordingPathController.dispose();
    _streamMessageController.dispose();
    _engine.dispose();
    super.dispose();
  }
}
