import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
import 'app_config.dart';
import 'token_service.dart';
import 'voice_room_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SY RTC 语聊房测试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const InitPage(),
    );
  }
}

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  final _engine = SyRtcEngine();
  bool _initializing = false;
  String _status = '';
  final List<String> _logs = [];

  final _apiBaseController = TextEditingController(
    text: 'https://syrtcapi.shengyuchenyao.cn/demo-api',
  );
  final _signalingController = TextEditingController(
    text: 'wss://syrtcapi.shengyuchenyao.cn/ws/signaling',
  );
  final _appIdController = TextEditingController(text: 'APP1769003318261114285E3');
  final _appSecretController = TextEditingController(text: '524d401de4c34ad1b554f2b35fe74d6f4f8f7e55614146069b527c1f8799b488');

  void _log(String msg) {
    if (!mounted) return;
    final ts = DateTime.now();
    setState(() {
      _logs.insert(0, '[${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}] $msg');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _requestPermissions() async {
    _log('请求权限...');
    try {
      final micStatus = await Permission.microphone.request();
      _log('麦克风权限: $micStatus');
      if (!micStatus.isGranted) {
        _log('麦克风权限未授予，部分功能可能受限');
      }
      if (Platform.isAndroid) {
        try {
          await Permission.phone.request();
        } catch (_) {}
        try {
          await Permission.bluetoothConnect.request();
        } catch (_) {}
      }
    } catch (e) {
      _log('权限请求异常: $e (继续初始化)');
    }
  }

  Future<void> _initAndEnter() async {
    if (_initializing) return;
    setState(() {
      _initializing = true;
      _status = '正在检查权限...';
      _logs.clear();
    });

    try {
      _log('开始初始化流程');

      await _requestPermissions();

      final appId = _appIdController.text.trim();
      final apiBase = _apiBaseController.text.trim();
      final signaling = _signalingController.text.trim();
      final appSecret = _appSecretController.text.trim();

      if (appId.isEmpty || apiBase.isEmpty) {
        setState(() {
          _status = '请填写AppId和API地址';
          _initializing = false;
        });
        return;
      }

      _log('初始化SDK: appId=${appId.substring(0, 10)}...');
      setState(() => _status = '正在初始化SDK...');

      try {
        await _engine.init(
          appId,
          apiBaseUrl: apiBase,
          signalingUrl: signaling,
        );
        _log('SDK init 成功');
      } catch (e) {
        _log('SDK init 异常: $e');
        setState(() {
          _status = 'SDK初始化异常: $e';
          _initializing = false;
        });
        return;
      }

      _log('检查语聊功能...');
      bool hasVoice = false;
      try {
        hasVoice = await _engine.hasVoiceFeature();
        _log('语聊功能: ${hasVoice ? "已开通" : "未开通"}');
      } catch (e) {
        _log('功能检查失败: $e (默认开通)');
        hasVoice = true;
      }

      setState(() => _status = '初始化成功 (语聊=${hasVoice ? "已开通" : "未开通"})');
      _log('准备进入语聊房...');

      final config = AppConfig(
        apiBaseUrl: apiBase,
        signalingUrl: signaling,
        appId: appId,
        appSecret: appSecret.isEmpty ? null : appSecret,
      );
      final tokenService = TokenService(config);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(
            engine: _engine,
            config: config,
            tokenService: tokenService,
          ),
        ),
      );
    } on PlatformException catch (e) {
      _log('Platform异常: ${e.code} - ${e.message}\n${e.details}');
      setState(() {
        _status = '初始化失败: ${e.message}';
        _initializing = false;
      });
    } catch (e, st) {
      _log('未知异常: $e\n$st');
      setState(() {
        _status = '初始化失败: $e';
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.surround_sound, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 12),
              const Text(
                'SY RTC 语聊房测试',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '测试语聊房功能：加入/退出、上下麦、开关麦、说话检测',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 24),
              _field('API 地址', _apiBaseController),
              _field('信令地址', _signalingController),
              _field('AppId', _appIdController),
              _field('AppSecret', _appSecretController, obscure: true),
              const SizedBox(height: 8),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('失败') || _status.contains('异常') ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _initializing ? null : _initAndEnter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.blueAccent.withOpacity(0.4),
                  ),
                  child: _initializing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('初始化并进入', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              if (_logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('初始化日志', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (_, i) => Text(
                            _logs[i],
                            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiBaseController.dispose();
    _signalingController.dispose();
    _appIdController.dispose();
    _appSecretController.dispose();
    super.dispose();
  }
}
