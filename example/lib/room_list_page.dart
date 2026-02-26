import 'package:flutter/material.dart';
import 'package:sy_rtc_flutter_sdk/sy_rtc_flutter_sdk.dart';
import 'app_config.dart';
import 'voice_room_page.dart';

class RoomListPage extends StatefulWidget {
  final SyRtcEngine engine;
  final AppConfig config;
  final SyRoomService roomService;

  const RoomListPage({
    super.key,
    required this.engine,
    required this.config,
    required this.roomService,
  });

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  List<SyRoomInfo> _rooms = [];
  bool _loading = false;
  String? _error;
  final _channelIdController = TextEditingController();
  final _uidController = TextEditingController(text: 'user_${DateTime.now().millisecondsSinceEpoch % 10000}');

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await widget.roomService.getRoomList();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createRoom() async {
    final channelId = _channelIdController.text.trim();
    if (channelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入房间ID')),
      );
      return;
    }
    try {
      await widget.roomService.createRoom(channelId);
      _channelIdController.clear();
      _fetchRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('房间 $channelId 创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  Future<void> _joinRoom(String channelId) async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户ID')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await widget.roomService.fetchToken(
        channelId: channelId,
        uid: uid,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(
            engine: widget.engine,
            config: widget.config,
            roomService: widget.roomService,
            channelId: channelId,
            uid: uid,
            token: token,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取 Token 失败: $e')),
        );
      }
    }
  }

  void _quickJoin() {
    final channelId = _channelIdController.text.trim();
    if (channelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入房间ID')),
      );
      return;
    }
    _joinRoom(channelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房间列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRooms,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('快速加入 / 创建房间',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _uidController,
                      decoration: const InputDecoration(
                        labelText: '用户 ID',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _channelIdController,
                            decoration: const InputDecoration(
                              labelText: '房间 ID',
                              hintText: '输入房间ID加入或创建',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _quickJoin,
                          child: const Text('加入'),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          onPressed: _createRoom,
                          child: const Text('创建'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('活跃房间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_rooms.length} 个房间',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 8),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchRooms,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : _rooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.meeting_room_outlined,
                                      size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  const Text('暂无活跃房间'),
                                  const SizedBox(height: 4),
                                  const Text('输入房间ID直接加入，或创建新房间',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchRooms,
                              child: ListView.builder(
                                itemCount: _rooms.length,
                                itemBuilder: (ctx, i) {
                                  final room = _rooms[i];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: room.status == 'active'
                                            ? Colors.green
                                            : Colors.grey,
                                        child: const Icon(Icons.mic, color: Colors.white),
                                      ),
                                      title: Text(room.channelId),
                                      subtitle: Text(
                                        '在线: ${room.onlineCount} 人 · ${room.status}',
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () => _joinRoom(room.channelId),
                                        child: const Text('加入'),
                                      ),
                                    ),
                                  );
                                },
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
    _channelIdController.dispose();
    _uidController.dispose();
    super.dispose();
  }
}
