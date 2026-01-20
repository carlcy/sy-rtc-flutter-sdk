import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';

/// 功能权限使用示例
/// 
/// 展示如何根据AppId的功能权限启用/禁用相应功能
class FeaturePermissionExample extends StatefulWidget {
  final String appId;
  final String apiBaseUrl;
  
  const FeaturePermissionExample({
    Key? key,
    required this.appId,
    required this.apiBaseUrl,
  }) : super(key: key);
  
  @override
  State<FeaturePermissionExample> createState() => _FeaturePermissionExampleState();
}

class _FeaturePermissionExampleState extends State<FeaturePermissionExample> {
  final SyRtcEngine _engine = SyRtcEngine();
  bool _hasVoice = false;
  bool _hasLive = false;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }
  
  Future<void> _initializeEngine() async {
    try {
      // 初始化引擎并查询功能权限
      await _engine.init(widget.appId, apiBaseUrl: widget.apiBaseUrl);
      
      // 检查功能权限
      _hasVoice = await _engine.hasVoiceFeature();
      _hasLive = await _engine.hasLiveFeature();
      
      setState(() {
        _isInitialized = true;
      });
      
      print('功能权限检查完成: voice=$_hasVoice, live=$_hasLive');
    } catch (e) {
      print('初始化失败: $e');
    }
  }
  
  Future<void> _joinChannel() async {
    if (!_hasVoice) {
      _showError('当前AppId未开通语聊功能');
      return;
    }
    
    try {
      // 获取Token（从服务器）
      String token = await _getTokenFromServer();
      
      await _engine.join('test_channel', 'user_001', token);
      
      _showSuccess('加入频道成功');
    } catch (e) {
      _showError('加入频道失败: $e');
    }
  }
  
  Future<void> _enableVideo() async {
    if (!_hasLive) {
      _showError('当前AppId未开通直播功能，无法使用视频功能');
      return;
    }
    
    try {
      await _engine.enableVideo();
      await _engine.startPreview();
      _showSuccess('视频功能已启用');
    } catch (e) {
      _showError('启用视频失败: $e');
    }
  }
  
  Future<void> _enableAudio() async {
    if (!_hasVoice) {
      _showError('当前AppId未开通语聊功能');
      return;
    }
    
    try {
      await _engine.enableLocalAudio(true);
      _showSuccess('音频功能已启用');
    } catch (e) {
      _showError('启用音频失败: $e');
    }
  }
  
  Future<String> _getTokenFromServer() async {
    // 从服务器获取Token
    // 实际实现应该调用您的后端API获取Token
    // 示例：
    // final response = await http.get(
    //   Uri.parse('${widget.apiBaseUrl}/api/rtc/token?channelId=test_channel&uid=user_001')
    // );
    // return jsonDecode(response.body)['token'];
    
    // 这里返回示例Token，实际使用时请替换为真实的Token获取逻辑
    return 'your_token_here';
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能权限示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 功能权限显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前AppId功能权限',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureChip('语聊', _hasVoice, Colors.green),
                        const SizedBox(width: 8),
                        _buildFeatureChip('直播', _hasLive, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 功能按钮
            ElevatedButton.icon(
              onPressed: _hasVoice ? _joinChannel : null,
              icon: const Icon(Icons.phone),
              label: const Text('加入频道（需要语聊权限）'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _hasVoice ? _enableAudio : null,
              icon: const Icon(Icons.mic),
              label: const Text('启用音频（需要语聊权限）'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _hasLive ? _enableVideo : null,
              icon: const Icon(Icons.videocam),
              label: const Text('启用视频（需要直播权限）'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasLive ? Colors.orange : Colors.grey,
              ),
            ),
            
            if (!_hasLive)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '提示：当前AppId未开通直播功能，无法使用视频相关功能。\n请购买包含直播功能的套餐。',
                  style: TextStyle(color: Colors.orange[700], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureChip(String label, bool enabled, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: enabled ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
      avatar: Icon(
        enabled ? Icons.check_circle : Icons.cancel,
        color: enabled ? color : Colors.grey,
        size: 18,
      ),
    );
  }
  
  @override
  void dispose() {
    _engine.leave();
    super.dispose();
  }
}
