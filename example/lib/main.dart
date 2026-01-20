import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _engine = SyRtcEngine();
  String _status = '未初始化';
  StreamSubscription<SyUserJoinedEvent>? _userJoinedSubscription;
  StreamSubscription<SyUserOfflineEvent>? _userOfflineSubscription;
  StreamSubscription<SyVolumeIndicationEvent>? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _userJoinedSubscription = _engine.onUserJoined.listen((SyUserJoinedEvent event) {
      if (mounted) {
        setState(() {
          _status = '用户加入: ${event.uid}';
        });
      }
    });

    _userOfflineSubscription = _engine.onUserOffline.listen((SyUserOfflineEvent event) {
      if (mounted) {
        setState(() {
          _status = '用户离开: ${event.uid}';
        });
      }
    });

    _volumeSubscription = _engine.onVolumeIndication.listen((SyVolumeIndicationEvent event) {
      if (mounted && event.speakers.isNotEmpty) {
        setState(() {
          _status = '音量指示: ${event.speakers.length} 个用户';
        });
      }
    });
  }

  Future<void> _initEngine() async {
    try {
      // 初始化时传入API URL以查询功能权限
      await _engine.init(
        'your_app_id',
        apiBaseUrl: 'https://api.example.com', // 您的API基础URL
        // 生产环境建议使用 wss://your-domain.com/ws/signaling
        signalingUrl: 'ws://47.105.48.196/ws/signaling',
      );
      
      // 检查功能权限
      bool hasVoice = await _engine.hasVoiceFeature();
      bool hasLive = await _engine.hasLiveFeature();
      
      setState(() {
        _status = '初始化成功\n功能权限: 语聊=$hasVoice, 直播=$hasLive';
      });
    } catch (e) {
      setState(() {
        _status = '初始化失败: $e';
      });
    }
  }

  Future<void> _joinChannel() async {
    try {
      await _engine.join('channel_001', 'user_001', 'token_here');
      setState(() {
        _status = '加入频道成功';
      });
    } catch (e) {
      setState(() {
        _status = '加入频道失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SY RTC Flutter SDK 示例'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('状态: $_status'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initEngine,
                child: const Text('初始化引擎'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _joinChannel,
                child: const Text('加入频道'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    bool hasLive = await _engine.hasLiveFeature();
                    if (hasLive) {
                      await _engine.enableVideo();
                      setState(() {
                        _status = '视频功能已启用';
                      });
                    } else {
                      setState(() {
                        _status = '当前AppId未开通直播功能';
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _status = '启用视频失败: $e';
                    });
                  }
                },
                child: const Text('启用视频（需要直播权限）'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userJoinedSubscription?.cancel();
    _userOfflineSubscription?.cancel();
    _volumeSubscription?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
