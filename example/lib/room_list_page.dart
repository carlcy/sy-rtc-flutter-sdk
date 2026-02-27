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
  final _uidController = TextEditingController(
      text: 'user_${DateTime.now().millisecondsSinceEpoch % 10000}');

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
      if (mounted) setState(() { _rooms = rooms; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showCreateRoomDialog() {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写用户 ID')),
      );
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建房间'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '房间 ID',
            hintText: '例如: my_room_001',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                Navigator.pop(ctx);
                _doCreateRoom(id);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _doCreateRoom(String channelId) async {
    widget.roomService.setUserId(_uidController.text.trim());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await widget.roomService.createRoom(channelId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间 $channelId 创建成功'), backgroundColor: Colors.green),
      );
      _fetchRooms();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _joinRoom(String channelId) async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写用户 ID')),
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
      ).then((_) => _fetchRooms());
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加入失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房间列表'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRooms),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomDialog,
        icon: const Icon(Icons.add),
        label: const Text('创建房间'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: '我的用户 ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('活跃房间',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _fetchRooms, child: const Text('重试')),
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
                                  const Text('点击右下角 "创建房间" 开始',
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
                                        child: const Icon(Icons.mic,
                                            color: Colors.white, size: 20),
                                      ),
                                      title: Text(room.channelId,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                          '在线: ${room.onlineCount} 人'),
                                      trailing: FilledButton(
                                        onPressed: () =>
                                            _joinRoom(room.channelId),
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
    _uidController.dispose();
    super.dispose();
  }
}
