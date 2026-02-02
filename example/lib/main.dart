import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
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

  final _apiBaseController = TextEditingController(
    text: 'https://your-rtc-server.com',
  );
  final _signalingController = TextEditingController(
    text: 'wss://your-rtc-server.com/ws/signaling',
  );
  final _appIdController = TextEditingController(text: 'your_app_id');
  final _jwtController = TextEditingController();
  final _channelIdController = TextEditingController(text: 'channel_001');
  final _uidController = TextEditingController(text: 'user_001');
  final _tokenController = TextEditingController(text: '');

  String _status = '未初始化';
  bool _initialized = false;
  bool _inChannel = false;
  bool _muted = false;

  StreamSubscription<SyUserJoinedEvent>? _userJoinedSub;
  StreamSubscription<SyUserOfflineEvent>? _userOfflineSub;
  StreamSubscription<SyVolumeIndicationEvent>? _volumeSub;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _userJoinedSub = _engine.onUserJoined.listen((e) {
      if (mounted) setState(() => _status = '用户加入: ${e.uid}');
    });
    _userOfflineSub = _engine.onUserOffline.listen((e) {
      if (mounted) setState(() => _status = '用户离开: ${e.uid}');
    });
    _volumeSub = _engine.onVolumeIndication.listen((e) {
      if (mounted && e.speakers.isNotEmpty) {
        setState(() => _status = '音量: ${e.speakers.length} 人');
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
      );
      _tokenService = TokenService(_config!);

      await _engine.init(
        _config!.appId,
        apiBaseUrl: _config!.apiBaseUrl,
        signalingUrl: _config!.signalingUrl,
      );

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
              _field('JWT（可选，用于拉取 Token）', _jwtController, obscure: true),
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
                  Text('需先填 JWT 并初始化', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
    _apiBaseController.dispose();
    _signalingController.dispose();
    _appIdController.dispose();
    _jwtController.dispose();
    _channelIdController.dispose();
    _uidController.dispose();
    _tokenController.dispose();
    _engine.dispose();
    super.dispose();
  }
}
