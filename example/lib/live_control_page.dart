import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart'
    hide SyLiveTranscoding, SyTranscodingUser;
import 'package:sy_rtc_flutter_sdk/src/sy_rtc_config_extended.dart';

/// 直播控制页面
///
/// 提供开播、停播、切换布局、更新转码配置等可视化控制界面
class LiveControlPage extends StatefulWidget {
  final SyRtcEngine engine;
  final String channelId;
  final String uid;
  final String token;

  const LiveControlPage({
    super.key,
    required this.engine,
    required this.channelId,
    required this.uid,
    required this.token,
  });

  @override
  State<LiveControlPage> createState() => _LiveControlPageState();
}

class _LiveControlPageState extends State<LiveControlPage> {
  bool _isStreaming = false;
  String _rtmpUrl = '';
  String _layoutMode = 'host-main'; // 'host-main' 或 'pk'
  int _width = 720;
  int _height = 1280;
  int _bitrate = 1200;
  int _fps = 30;
  String _status = '未开播';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播控制'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态卡片
            Card(
              color: _isStreaming ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isStreaming ? Icons.live_tv : Icons.live_tv_outlined,
                          color: _isStreaming ? Colors.red : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isStreaming ? '直播中' : '未开播',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isStreaming ? Colors.red : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _status,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RTMP推流地址输入
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RTMP推流地址',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'rtmp://example.com/live/stream',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _rtmpUrl = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '支持多平台推流：抖音、快手、虎牙、YouTube等',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 布局模式选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '布局模式',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'host-main',
                          label: Text('主播主视角'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 'pk',
                          label: Text('PK双主视角'),
                          icon: Icon(Icons.people),
                        ),
                      ],
                      selected: {_layoutMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _layoutMode = newSelection.first;
                        });
                        if (_isStreaming) {
                          _updateLayout();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _layoutMode == 'host-main'
                          ? '主播大窗口，其他用户小窗口'
                          : '两个主播并排显示（PK模式）',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 视频配置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '视频配置',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('分辨率宽度'),
                              Slider(
                                value: _width.toDouble(),
                                min: 360,
                                max: 1920,
                                divisions: 10,
                                label: '$_width',
                                onChanged: (value) {
                                  setState(() {
                                    _width = value.toInt();
                                  });
                                  if (_isStreaming) {
                                    _updateTranscoding();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('分辨率高度'),
                              Slider(
                                value: _height.toDouble(),
                                min: 640,
                                max: 1080,
                                divisions: 10,
                                label: '$_height',
                                onChanged: (value) {
                                  setState(() {
                                    _height = value.toInt();
                                  });
                                  if (_isStreaming) {
                                    _updateTranscoding();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('码率: $_bitrate Kbps'),
                        Slider(
                          value: _bitrate.toDouble(),
                          min: 400,
                          max: 3000,
                          divisions: 13,
                          label: '$_bitrate Kbps',
                          onChanged: (value) {
                            setState(() {
                              _bitrate = value.toInt();
                            });
                            if (_isStreaming) {
                              _updateTranscoding();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('帧率: $_fps fps'),
                        Slider(
                          value: _fps.toDouble(),
                          min: 15,
                          max: 60,
                          divisions: 9,
                          label: '$_fps fps',
                          onChanged: (value) {
                            setState(() {
                              _fps = value.toInt();
                            });
                            if (_isStreaming) {
                              _updateTranscoding();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStreaming ? null : _startStreaming,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始直播'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStreaming ? _stopStreaming : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止直播'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 提示信息
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isStreaming
                            ? '直播中：可以随时切换布局或调整视频配置'
                            : '请先输入RTMP推流地址，然后点击"开始直播"',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startStreaming() async {
    if (_rtmpUrl.isEmpty) {
      _showError('请先输入RTMP推流地址');
      return;
    }

    try {
      setState(() {
        _status = '正在开播...';
      });

      // 创建转码配置
      final transcoding = SyLiveTranscoding(
        width: _width,
        height: _height,
        videoBitrate: _bitrate,
        videoFramerate: _fps,
        transcodingUsers: _layoutMode == 'pk'
            ? [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 0.5, height: 1.0),
                SyTranscodingUser(
                    uid: 'remote_user',
                    x: 0.5,
                    y: 0.0,
                    width: 0.5,
                    height: 1.0),
              ]
            : [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 1.0, height: 1.0),
              ],
      );

      await widget.engine.startRtmpStreamWithTranscoding(_rtmpUrl, transcoding);

      setState(() {
        _isStreaming = true;
        _status = '直播已开始';
      });

      _showSuccess('直播已开始');
    } catch (e) {
      setState(() {
        _status = '开播失败: $e';
      });
      _showError('开播失败: $e');
    }
  }

  Future<void> _stopStreaming() async {
    if (_rtmpUrl.isEmpty) return;

    try {
      setState(() {
        _status = '正在停播...';
      });

      await widget.engine.stopRtmpStream(_rtmpUrl);

      setState(() {
        _isStreaming = false;
        _status = '直播已停止';
      });

      _showSuccess('直播已停止');
    } catch (e) {
      setState(() {
        _status = '停播失败: $e';
      });
      _showError('停播失败: $e');
    }
  }

  Future<void> _updateLayout() async {
    if (!_isStreaming) return;

    try {
      final transcoding = SyLiveTranscoding(
        width: _width,
        height: _height,
        videoBitrate: _bitrate,
        videoFramerate: _fps,
        transcodingUsers: _layoutMode == 'pk'
            ? [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 0.5, height: 1.0),
                SyTranscodingUser(
                    uid: 'remote_user',
                    x: 0.5,
                    y: 0.0,
                    width: 0.5,
                    height: 1.0),
              ]
            : [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 1.0, height: 1.0),
              ],
      );

      await widget.engine.updateRtmpTranscoding(transcoding);
      _showSuccess('布局已切换');
    } catch (e) {
      _showError('切换布局失败: $e');
    }
  }

  Future<void> _updateTranscoding() async {
    if (!_isStreaming) return;

    try {
      final transcoding = SyLiveTranscoding(
        width: _width,
        height: _height,
        videoBitrate: _bitrate,
        videoFramerate: _fps,
        transcodingUsers: _layoutMode == 'pk'
            ? [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 0.5, height: 1.0),
                SyTranscodingUser(
                    uid: 'remote_user',
                    x: 0.5,
                    y: 0.0,
                    width: 0.5,
                    height: 1.0),
              ]
            : [
                SyTranscodingUser(
                    uid: widget.uid, x: 0.0, y: 0.0, width: 1.0, height: 1.0),
              ],
      );

      await widget.engine.updateRtmpTranscoding(transcoding);
    } catch (e) {
      _showError('更新配置失败: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
