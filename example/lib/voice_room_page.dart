import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
import 'app_config.dart';
import 'token_service.dart';

class VoiceRoomPage extends StatefulWidget {
  final SyRtcEngine engine;
  final AppConfig config;
  final TokenService tokenService;

  const VoiceRoomPage({
    super.key,
    required this.engine,
    required this.config,
    required this.tokenService,
  });

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _SeatInfo {
  String? uid;
  bool isMuted;
  bool isSpeaking;
  int volume;

  _SeatInfo({this.uid, this.isMuted = false, this.isSpeaking = false, this.volume = 0});
}

class _VoiceRoomPageState extends State<VoiceRoomPage> {
  final _channelController = TextEditingController(text: 'test_room_001');
  final _uidController = TextEditingController(text: 'user_${DateTime.now().millisecondsSinceEpoch % 10000}');

  bool _inRoom = false;
  bool _isJoining = false;
  bool _isOnMic = false;
  bool _isMicMuted = false;
  bool _isSpeakerOn = true;
  String _myUid = '';
  String _channelId = '';

  final List<_SeatInfo> _seats = List.generate(9, (_) => _SeatInfo());
  final Set<String> _onlineUsers = {};
  final List<String> _logs = [];

  StreamSubscription<SyUserJoinedEvent>? _joinSub;
  StreamSubscription<SyUserOfflineEvent>? _leaveSub;
  StreamSubscription<SyVolumeIndicationEvent>? _volumeSub;
  StreamSubscription<SyErrorEvent>? _errorSub;
  StreamSubscription<SyChannelMessageEvent>? _channelMsgSub;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _joinSub = widget.engine.onUserJoined.listen((e) {
      setState(() {
        _onlineUsers.add(e.uid);
      });
      _log('用户加入: ${e.uid}');
      _broadcastMySeatIfOnMic();
    });

    _leaveSub = widget.engine.onUserOffline.listen((e) {
      setState(() {
        _onlineUsers.remove(e.uid);
        for (final seat in _seats) {
          if (seat.uid == e.uid) {
            seat.uid = null;
            seat.isMuted = false;
            seat.isSpeaking = false;
            seat.volume = 0;
          }
        }
      });
      _log('用户离开: ${e.uid}');
    });

    _volumeSub = widget.engine.onVolumeIndication.listen((e) {
      if (!mounted) return;
      setState(() {
        for (final seat in _seats) {
          if (seat.uid != null) {
            seat.isSpeaking = false;
            seat.volume = 0;
          }
        }
        for (final speaker in e.speakers) {
          final uid = speaker['uid'] as String?;
          final vol = speaker['volume'] as int? ?? 0;
          if (uid == null) continue;
          for (final seat in _seats) {
            if (seat.uid == uid) {
              seat.isSpeaking = vol > 10;
              seat.volume = vol;
            }
          }
        }
      });
    });

    _errorSub = widget.engine.onError.listen((e) {
      _log('错误: [${e.errCode}] ${e.errMsg}');
    });

    _channelMsgSub = widget.engine.onChannelMessage.listen((e) {
      _handleChannelMessage(e.uid, e.message);
    });
  }

  void _handleChannelMessage(String fromUid, String message) {
    if (fromUid == _myUid) return;
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final action = data['action'] as String?;
      switch (action) {
        case 'seat-take':
          final uid = data['uid'] as String;
          final seatIndex = (data['seatIndex'] as num).toInt();
          final muted = data['muted'] as bool? ?? false;
          if (seatIndex >= 0 && seatIndex < _seats.length) {
            setState(() {
              for (final s in _seats) {
                if (s.uid == uid) {
                  s.uid = null;
                  s.isMuted = false;
                  s.isSpeaking = false;
                  s.volume = 0;
                }
              }
              _seats[seatIndex].uid = uid;
              _seats[seatIndex].isMuted = muted;
            });
            _log('$uid 上了${seatIndex == 0 ? "房主位" : "${seatIndex}号麦"}');
          }
          break;
        case 'seat-leave':
          final uid = data['uid'] as String;
          setState(() {
            for (final s in _seats) {
              if (s.uid == uid) {
                s.uid = null;
                s.isMuted = false;
                s.isSpeaking = false;
                s.volume = 0;
              }
            }
          });
          _log('$uid 下麦了');
          break;
        case 'seat-mute':
          final uid = data['uid'] as String;
          final muted = data['muted'] as bool? ?? false;
          setState(() {
            for (final s in _seats) {
              if (s.uid == uid) {
                s.isMuted = muted;
              }
            }
          });
          break;
        case 'seat-sync-request':
          _broadcastMySeatIfOnMic();
          break;
      }
    } catch (e) {
      _log('处理频道消息失败: $e');
    }
  }

  void _broadcastSeatAction(Map<String, dynamic> data) {
    try {
      widget.engine.sendChannelMessage(jsonEncode(data));
    } catch (e) {
      _log('广播麦位状态失败: $e');
    }
  }

  void _broadcastMySeatIfOnMic() {
    if (!_isOnMic || !_inRoom) return;
    final myIdx = _seats.indexWhere((s) => s.uid == _myUid);
    if (myIdx == -1) return;
    _broadcastSeatAction({
      'action': 'seat-take',
      'uid': _myUid,
      'seatIndex': myIdx,
      'muted': _isMicMuted,
    });
  }

  void _log(String msg) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '[${_timeStr()}] $msg');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  String _timeStr() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _joinRoom() async {
    final channelId = _channelController.text.trim();
    final uid = _uidController.text.trim();
    if (channelId.isEmpty || uid.isEmpty) {
      _log('请填写房间ID和用户ID');
      _showError('请填写房间ID和用户ID');
      return;
    }

    setState(() => _isJoining = true);
    _log('正在拉取Token (API: ${widget.config.tokenEndpoint})...');
    try {
      final token = await widget.tokenService.fetchRtcToken(
        channelId: channelId,
        uid: uid,
      );
      _log('Token已获取: ${token.substring(0, 20)}...');

      _log('正在加入房间 (channelId=$channelId, uid=$uid)...');
      await widget.engine.join(channelId, uid, token);
      _log('join 调用完成');

      _log('设置角色为听众...');
      await widget.engine.setClientRole('audience');
      _log('setClientRole 完成');

      _log('开启扬声器...');
      await widget.engine.setEnableSpeakerphone(true);
      _log('setEnableSpeakerphone 完成');

      setState(() {
        _inRoom = true;
        _isJoining = false;
        _isOnMic = false;
        _isMicMuted = false;
        _isSpeakerOn = true;
        _myUid = uid;
        _channelId = channelId;
        _onlineUsers.add(uid);
      });
      _log('=== 已成功加入房间: $channelId (身份: 听众) ===');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (_inRoom) {
          _broadcastSeatAction({'action': 'seat-sync-request', 'uid': _myUid});
        }
      });
    } catch (e, st) {
      _log('!!! 加入房间失败: $e');
      _log('堆栈: ${st.toString().split('\n').take(5).join('\n')}');
      setState(() => _isJoining = false);
      _showError('加入房间失败: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    try {
      if (_isOnMic) {
        _broadcastSeatAction({
          'action': 'seat-leave',
          'uid': _myUid,
        });
      }
      await widget.engine.leave();
      setState(() {
        _inRoom = false;
        _isOnMic = false;
        _isMicMuted = false;
        _onlineUsers.clear();
        for (final seat in _seats) {
          seat.uid = null;
          seat.isMuted = false;
          seat.isSpeaking = false;
          seat.volume = 0;
        }
      });
      _log('已离开房间');
    } catch (e) {
      _log('离开房间失败: $e');
    }
  }

  Future<void> _goOnMic() async {
    if (!_inRoom || _isOnMic) return;

    final emptyIdx = _seats.indexWhere((s) => s.uid == null);
    if (emptyIdx == -1) {
      _log('麦位已满，无法上麦');
      return;
    }

    try {
      await widget.engine.setClientRole('host');
      await widget.engine.muteLocalAudio(false);
      setState(() {
        _isOnMic = true;
        _isMicMuted = false;
        _seats[emptyIdx].uid = _myUid;
        _seats[emptyIdx].isMuted = false;
      });
      _broadcastSeatAction({
        'action': 'seat-take',
        'uid': _myUid,
        'seatIndex': emptyIdx,
        'muted': false,
      });
      _log('上麦成功 (麦位${emptyIdx + 1})');
    } catch (e) {
      _log('上麦失败: $e');
    }
  }

  Future<void> _goOffMic() async {
    if (!_inRoom || !_isOnMic) return;
    try {
      _broadcastSeatAction({
        'action': 'seat-leave',
        'uid': _myUid,
      });
      await widget.engine.muteLocalAudio(true);
      await widget.engine.setClientRole('audience');
      setState(() {
        _isOnMic = false;
        _isMicMuted = false;
        for (final seat in _seats) {
          if (seat.uid == _myUid) {
            seat.uid = null;
            seat.isMuted = false;
            seat.isSpeaking = false;
            seat.volume = 0;
          }
        }
      });
      _log('下麦成功');
    } catch (e) {
      _log('下麦失败: $e');
    }
  }

  Future<void> _toggleMic() async {
    if (!_inRoom || !_isOnMic) return;
    try {
      final newMuted = !_isMicMuted;
      await widget.engine.muteLocalAudio(newMuted);
      setState(() {
        _isMicMuted = newMuted;
        for (final seat in _seats) {
          if (seat.uid == _myUid) {
            seat.isMuted = newMuted;
          }
        }
      });
      _broadcastSeatAction({
        'action': 'seat-mute',
        'uid': _myUid,
        'muted': newMuted,
      });
      _log(newMuted ? '麦克风已关闭' : '麦克风已开启');
    } catch (e) {
      _log('麦克风切换失败: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    if (!_inRoom) return;
    try {
      final newState = !_isSpeakerOn;
      await widget.engine.setEnableSpeakerphone(newState);
      setState(() => _isSpeakerOn = newState);
      _log(newState ? '扬声器已开启' : '已切换到听筒');
    } catch (e) {
      _log('扬声器切换失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(_inRoom ? '语聊房: $_channelId' : '语聊房测试'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          if (_inRoom)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        '在线 ${_onlineUsers.length}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _inRoom ? _buildRoomView() : _buildJoinView(),
    );
  }

  Widget _buildJoinView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.mic_rounded, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 16),
          const Text('语聊房测试', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'AppId: ${widget.config.appId.substring(0, 10)}...',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 32),
          _inputField('房间ID', _channelController),
          const SizedBox(height: 12),
          _inputField('用户ID', _uidController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isJoining ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.blueAccent.withOpacity(0.4),
              ),
              child: _isJoining
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('正在加入...', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      ],
                    )
                  : const Text('加入房间', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildLogPanel(),
          ],
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildRoomView() {
    return Column(
      children: [
        _buildMyStatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _buildSeatsGrid(),
                const SizedBox(height: 12),
                _buildControlButtons(),
                const SizedBox(height: 12),
                _buildLogPanel(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          Icon(
            _isOnMic ? Icons.mic : Icons.headphones,
            color: _isOnMic ? Colors.greenAccent : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '我: $_myUid',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _isOnMic ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isOnMic ? (_isMicMuted ? '已上麦(静音)' : '已上麦') : '听众',
              style: TextStyle(
                color: _isOnMic ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            _isSpeakerOn ? Icons.volume_up : Icons.hearing,
            color: Colors.white54,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _isSpeakerOn ? '扬声器' : '听筒',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_seat, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 6),
                const Text('麦位 (房主+8麦)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${_seats.where((s) => s.uid != null).length}/9 在麦',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Seat 0 = host, centered
            Center(child: _buildSeat(0, isHost: true)),
            const SizedBox(height: 12),
            // Seats 1-4
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (int i = 1; i <= 4; i++) _buildSeat(i)],
            ),
            const SizedBox(height: 12),
            // Seats 5-8
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (int i = 5; i <= 8; i++) _buildSeat(i)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeat(int index, {bool isHost = false}) {
    final seat = _seats[index];
    final isEmpty = seat.uid == null;
    final isMe = seat.uid == _myUid;
    final speaking = seat.isSpeaking && !seat.isMuted;

    return GestureDetector(
      onTap: () {
        if (isEmpty && !_isOnMic && _inRoom) {
          _goOnMicAt(index);
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isHost ? 68 : 60,
            height: isHost ? 68 : 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEmpty
                  ? Colors.grey.withOpacity(0.2)
                  : speaking
                      ? Colors.greenAccent.withOpacity(0.3)
                      : Colors.blueAccent.withOpacity(0.2),
              border: Border.all(
                color: speaking
                    ? Colors.greenAccent
                    : isEmpty
                        ? Colors.grey.withOpacity(0.3)
                        : (isMe ? Colors.blueAccent : Colors.white24),
                width: speaking ? 3 : 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isEmpty
                      ? Icons.add
                      : seat.isMuted
                          ? Icons.mic_off
                          : Icons.mic,
                  color: isEmpty
                      ? Colors.grey[600]
                      : seat.isMuted
                          ? Colors.redAccent
                          : (speaking ? Colors.greenAccent : Colors.white70),
                  size: isHost ? 28 : 24,
                ),
                if (!isEmpty && speaking)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${seat.volume}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty
                ? (isHost ? '房主' : '${index}号麦')
                : (isMe ? '我' : seat.uid!.length > 6 ? '${seat.uid!.substring(0, 6)}..' : seat.uid!),
            style: TextStyle(
              color: isMe ? Colors.blueAccent : Colors.white70,
              fontSize: 10,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isHost && !isEmpty)
            const Text('房主', style: TextStyle(color: Colors.amber, fontSize: 9)),
        ],
      ),
    );
  }

  Future<void> _goOnMicAt(int seatIndex) async {
    if (!_inRoom || _isOnMic) return;
    try {
      await widget.engine.setClientRole('host');
      await widget.engine.muteLocalAudio(false);
      setState(() {
        _isOnMic = true;
        _isMicMuted = false;
        _seats[seatIndex].uid = _myUid;
        _seats[seatIndex].isMuted = false;
      });
      _broadcastSeatAction({
        'action': 'seat-take',
        'uid': _myUid,
        'seatIndex': seatIndex,
        'muted': false,
      });
      _log('上麦成功 (${seatIndex == 0 ? "房主位" : "${seatIndex}号麦"})');
    } catch (e) {
      _log('上麦失败: $e');
    }
  }

  Widget _buildControlButtons() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('操作面板', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ctrlBtn(
                    icon: Icons.arrow_upward,
                    label: '上麦',
                    color: Colors.green,
                    enabled: _inRoom && !_isOnMic,
                    onTap: _goOnMic,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ctrlBtn(
                    icon: Icons.arrow_downward,
                    label: '下麦',
                    color: Colors.orange,
                    enabled: _inRoom && _isOnMic,
                    onTap: _goOffMic,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ctrlBtn(
                    icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                    label: _isMicMuted ? '开麦' : '关麦',
                    color: _isMicMuted ? Colors.red : Colors.blue,
                    enabled: _inRoom && _isOnMic,
                    onTap: _toggleMic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ctrlBtn(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                    label: _isSpeakerOn ? '听筒' : '扬声器',
                    color: Colors.purple,
                    enabled: _inRoom,
                    onTap: _toggleSpeaker,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ctrlBtn(
                    icon: Icons.exit_to_app,
                    label: '退出房间',
                    color: Colors.red,
                    enabled: _inRoom,
                    onTap: _leaveRoom,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : Colors.grey[700], size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: enabled ? color : Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                const Text('事件日志', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _logs.clear()),
                  child: const Text('清除', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _logs.isEmpty
                  ? Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey[600], fontSize: 12)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          _logs[i],
                          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _volumeSub?.cancel();
    _errorSub?.cancel();
    _channelMsgSub?.cancel();
    _channelController.dispose();
    _uidController.dispose();
    super.dispose();
  }
}
