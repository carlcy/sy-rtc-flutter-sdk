import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

import 'app_config.dart';
import 'token_service.dart';

/// Single switch for all samples:
///   --dart-define=SY_API_BASE=https://47.105.48.196
///   --dart-define=SY_API_BASE=http://47.105.48.196
///   --dart-define=SY_API_BASE=https://syrtcapi.shengyuchenyao.cn  (only when LE/public CA works)
String defaultApiBase() {
  const override = String.fromEnvironment('SY_API_BASE', defaultValue: '');
  if (override.isNotEmpty) return override;
  return 'https://47.105.48.196';
}

String defaultSignaling() {
  const override = String.fromEnvironment('SY_SIGNALING_URL', defaultValue: '');
  if (override.isNotEmpty) return override;
  final base = defaultApiBase();
  if (base.startsWith('https://')) {
    return 'wss://${base.substring('https://'.length)}/ws/signaling';
  }
  if (base.startsWith('http://')) {
    return 'ws://${base.substring('http://'.length)}/ws/signaling';
  }
  return 'wss://47.105.48.196/ws/signaling';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SY RTC Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RtcVerifyPage(),
    );
  }
}

/// Verification UI: config, permissions, join/leave, mute, video.
class RtcVerifyPage extends StatefulWidget {
  const RtcVerifyPage({super.key});

  @override
  State<RtcVerifyPage> createState() => _RtcVerifyPageState();
}

class _RtcVerifyPageState extends State<RtcVerifyPage> {
  final _engine = SyRtcEngine();
  final _logs = <String>[];

  late final TextEditingController _apiBase;
  late final TextEditingController _signaling;
  final _appId = TextEditingController(text: 'your_app_id');
  final _appSecret = TextEditingController();
  final _channel = TextEditingController(text: 'channel_001');
  final _uid = TextEditingController(text: 'user_flutter');

  bool _initialized = false;
  bool _joined = false;
  bool _muted = false;
  bool _videoOn = false;
  bool _busy = false;
  String _status = '未初始化';
  String _micPerm = '未知';
  String _camPerm = '未知';
  String? _remoteUid;

  @override
  void initState() {
    super.initState();
    _apiBase = TextEditingController(text: defaultApiBase());
    _signaling = TextEditingController(text: defaultSignaling());
    _engine.setEventHandler(SyRtcEventHandler(
      onJoinChannelSuccess: (channelId, uid, elapsed) {
        _log('加入成功 $channelId uid=$uid (${elapsed}ms)');
        setState(() => _status = '已加入 $channelId');
      },
      onLeaveChannel: (stats) {
        _log('已离开频道');
        setState(() {
          _status = '已离开';
          _remoteUid = null;
        });
      },
      onUserJoined: (uid, elapsed) {
        _log('远端加入 $uid');
        setState(() => _remoteUid = uid);
        // Remote SyRtcVideoView rebuilds and binds setupRemoteVideo(uid, viewId)
      },
      onUserOffline: (uid, reason) {
        _log('远端离开 $uid reason=$reason');
        if (_remoteUid == uid) setState(() => _remoteUid = null);
      },
      onKicked: (channelId, reason) {
        _log('被踢出 $channelId reason=$reason');
        setState(() {
          _status = '被踢出: $reason';
          _remoteUid = null;
        });
      },
      onServerMuteAudio: (uid, muted) {
        _log('服务端静音 uid=$uid muted=$muted');
      },
      onError: (code, message) {
        _log('错误 $code $message');
        setState(() => _status = '错误: $message');
      },
      onConnectionStateChanged: (state, reason) {
        _log('连接 state=$state reason=$reason');
      },
    ));
    unawaited(_refreshPermStatus());
  }

  Future<void> _refreshPermStatus() async {
    final mic = await Permission.microphone.status;
    final cam = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _micPerm = mic.toString().split('.').last;
      _camPerm = cam.toString().split('.').last;
    });
  }

  Future<void> _requestPermissions() async {
    _log('请求麦克风/摄像头权限...');
    try {
      final mic = await Permission.microphone.request();
      final cam = await Permission.camera.request();
      _log('麦克风=$mic 摄像头=$cam');
      if (Platform.isAndroid) {
        try {
          await Permission.bluetoothConnect.request();
        } catch (_) {}
      }
    } catch (e) {
      _log('权限请求异常: $e');
    }
    await _refreshPermStatus();
  }

  Future<void> _init() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = '正在初始化...';
    });
    try {
      await _requestPermissions();
      final appId = _appId.text.trim();
      final api = _apiBase.text.trim();
      final sig = _signaling.text.trim();
      if (appId.isEmpty || api.isEmpty) {
        setState(() => _status = '请填写 AppId 和 API');
        return;
      }
      await _engine.init(appId, apiBaseUrl: api, signalingUrl: sig);
      setState(() {
        _initialized = true;
        _status = '已初始化';
      });
      _log('SDK init 成功 → $api  $sig');
    } on PlatformException catch (e) {
      _log('init PlatformException ${e.code} ${e.message}');
      setState(() => _status = '初始化失败: ${e.message}');
    } catch (e) {
      _log('init error $e');
      setState(() => _status = '初始化失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (_busy || _joined) return;
    if (!_initialized) {
      _log('请先初始化');
      return;
    }
    setState(() {
      _busy = true;
      _status = '获取 Token...';
    });
    try {
      final config = AppConfig(
        apiBaseUrl: _apiBase.text.trim(),
        signalingUrl: _signaling.text.trim(),
        appId: _appId.text.trim(),
        appSecret: _appSecret.text.trim(),
      );
      final token = await TokenService(config).fetchRtcToken(
        channelId: _channel.text.trim(),
        uid: _uid.text.trim(),
      );
      final preview = token.length > 16 ? token.substring(0, 16) : token;
      _log('Token ok ($preview...)');
      await _engine.join(_channel.text.trim(), _uid.text.trim(), token);
      await _engine.enableLocalAudio(true);
      setState(() {
        _joined = true;
        _status = '已加入 ${_channel.text.trim()}';
      });
    } catch (e) {
      _log('join error $e');
      setState(() => _status = '加入失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    try {
      await _engine.leave();
    } catch (e) {
      _log('leave error $e');
    }
    setState(() {
      _joined = false;
      _muted = false;
      _videoOn = false;
      _remoteUid = null;
      _status = '已离开';
    });
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await _engine.muteLocalAudio(next);
    setState(() => _muted = next);
    _log(next ? '已静音' : '取消静音');
  }

  Future<void> _enableVideo() async {
    try {
      await _engine.enableVideo();
      await _engine.enableLocalVideo(true);
      await _engine.startPreview();
      // Local SyRtcVideoView binds via onPlatformViewCreated → setupLocalVideo(viewId)
      setState(() {
        _videoOn = true;
        _status = '视频已启用';
      });
      _log('enableVideo + startPreview');
      if (Platform.isIOS) {
        _log('iOS 模拟器通常无摄像头。真机: flutter run -d <deviceId>');
      }
    } catch (e) {
      _log('video error $e');
      setState(() => _status = '视频失败: $e');
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '[$ts] $msg');
      if (_logs.length > 80) _logs.removeLast();
    });
  }

  @override
  void dispose() {
    if (_joined) {
      unawaited(_engine.leave());
    }
    _apiBase.dispose();
    _signaling.dispose();
    _appId.dispose();
    _appSecret.dispose();
    _channel.dispose();
    _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('SY RTC 验证'),
        backgroundColor: const Color(0xFF16213E),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0x33FF9800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '指向本地 Go 后端 :8080（iOS 模拟器 127.0.0.1，Android 模拟器 10.0.2.2）。'
                '真机请改成电脑局域网 IP。模拟器经常没有摄像头。',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ),
            Text(_status,
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('麦克风权限: $_micPerm    摄像头权限: $_camPerm',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 12),
            _field('API Base', _apiBase),
            _field('Signaling', _signaling),
            _field('AppId', _appId),
            _field('AppSecret', _appSecret, obscure: true),
            _field('Channel', _channel),
            _field('UID', _uid),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('请求权限', _requestPermissions),
                _btn('初始化', _initialized ? null : _init),
                _btn('加入', (!_initialized || _joined) ? null : _join),
                _btn('离开', _joined ? _leave : null),
                _btn(_muted ? '取消静音' : '静音', _joined ? _toggleMute : null),
                _btn('启用视频', _initialized ? _enableVideo : null),
              ],
            ),
            const SizedBox(height: 16),
            _videoSurface(
              title: '本地视频 ${_videoOn ? "(preview on)" : ""}',
              child: _videoOn
                  ? SyRtcVideoView(engine: _engine, mirror: true)
                  : _placeholder('启用视频后显示本地预览'),
            ),
            const SizedBox(height: 8),
            _videoSurface(
              title: '远端视频 ${_remoteUid ?? "(无人)"}',
              child: (_remoteUid != null)
                  ? SyRtcVideoView(engine: _engine, uid: _remoteUid)
                  : _placeholder('等待远端用户加入'),
            ),
            const SizedBox(height: 16),
            const Text('日志',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) => Text(
                  _logs[i],
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Future<void> Function()? onTap) {
    return FilledButton(
      onPressed: (_busy || onTap == null) ? null : () => onTap(),
      child: Text(label),
    );
  }

  Widget _field(String label, TextEditingController c, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          isDense: true,
        ),
      ),
    );
  }

  Widget _placeholder(String text) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(text,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ),
    );
  }

  Widget _videoSurface({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: child,
          ),
        ),
      ],
    );
  }
}
