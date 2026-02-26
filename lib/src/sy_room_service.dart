import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 房间信息
class SyRoomInfo {
  final String channelId;
  final String? hostUid;
  final String status;
  final int onlineCount;
  final int maxSeats;
  final DateTime? createTime;

  SyRoomInfo({
    required this.channelId,
    this.hostUid,
    this.status = 'active',
    this.onlineCount = 0,
    this.maxSeats = 8,
    this.createTime,
  });

  factory SyRoomInfo.fromMap(Map<String, dynamic> map) {
    return SyRoomInfo(
      channelId: map['channelId'] as String? ?? '',
      hostUid: map['hostUid'] as String?,
      status: map['status'] as String? ?? 'active',
      onlineCount: map['heat'] as int? ?? map['onlineCount'] as int? ?? 0,
      maxSeats: map['maxSeats'] as int? ?? 8,
      createTime: map['createTime'] != null
          ? DateTime.tryParse(map['createTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'channelId': channelId,
        'hostUid': hostUid,
        'status': status,
        'onlineCount': onlineCount,
        'maxSeats': maxSeats,
        'createTime': createTime?.toIso8601String(),
      };
}

/// SY RTC 房间服务
///
/// 提供房间管理和 Token 获取的便捷封装。
/// 这是核心 RTC 引擎的可选配套组件。
///
/// 典型使用流程：
/// ```dart
/// final roomService = SyRoomService(
///   apiBaseUrl: 'http://your-server.com/demo-api',
///   appId: 'YOUR_APP_ID',
/// );
/// roomService.setAuthToken(jwt); // 用户登录后获取的 JWT
///
/// // 1. 浏览房间列表（不需要 RTC Token）
/// final rooms = await roomService.getRoomList();
///
/// // 2. 创建房间
/// final room = await roomService.createRoom('my_room');
///
/// // 3. 获取 RTC Token 并加入房间
/// final token = await roomService.fetchToken(channelId: 'my_room', uid: 'user_1');
/// await engine.join('my_room', 'user_1', token);
/// ```
class SyRoomService {
  final String apiBaseUrl;
  final String appId;
  String? _appSecret;
  String? _authToken;

  SyRoomService({
    required this.apiBaseUrl,
    required this.appId,
  });

  /// 设置 API 认证 Token（用户登录后获取的 JWT）
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 设置 AppSecret（仅 Demo/测试用，生产环境应使用 JWT）
  void setAppSecret(String secret) {
    _appSecret = secret;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'X-App-Id': appId,
      'Content-Type': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_appSecret != null && _appSecret!.isNotEmpty) {
      headers['X-App-Secret'] = _appSecret!;
    }
    return headers;
  }

  /// 通过 MethodChannel 发起 HTTP 请求（避免引入 http 依赖）
  static const MethodChannel _channel = MethodChannel('sy_rtc_flutter_sdk');

  Future<Map<String, dynamic>> _httpRequest(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    var url = '$apiBaseUrl$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryStr = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$queryStr';
    }

    try {
      final result = await _channel.invokeMethod('httpRequest', {
        'method': method,
        'url': url,
        'headers': _headers,
        'body': body != null ? jsonEncode(body) : null,
      });

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      if (result is String) {
        return jsonDecode(result) as Map<String, dynamic>;
      }
      return {'code': 0, 'data': result};
    } catch (e) {
      debugPrint('SyRoomService HTTP error: $e');
      rethrow;
    }
  }

  /// 获取活跃房间列表
  ///
  /// 返回当前应用下的所有活跃房间，每个房间含 channelId、在线人数等基本信息。
  /// 不需要 RTC Token，只需要 API 认证（JWT 或 AppSecret）。
  Future<List<SyRoomInfo>> getRoomList() async {
    final result = await _httpRequest('GET', '/api/room/active');
    final code = result['code'] as int? ?? -1;
    if (code != 0) {
      throw Exception(result['msg'] ?? '获取房间列表失败');
    }
    final data = result['data'];
    if (data is List) {
      return data
          .map((e) => SyRoomInfo.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// 创建房间
  ///
  /// [channelId] 房间 ID（唯一标识）
  /// 返回创建的房间信息。
  Future<SyRoomInfo> createRoom(String channelId) async {
    final result = await _httpRequest(
      'POST',
      '/api/room/create',
      body: {'channelId': channelId},
    );
    final code = result['code'] as int? ?? -1;
    if (code != 0) {
      throw Exception(result['msg'] ?? '创建房间失败');
    }
    final data = result['data'];
    if (data is Map) {
      return SyRoomInfo.fromMap(Map<String, dynamic>.from(data));
    }
    return SyRoomInfo(channelId: channelId);
  }

  /// 关闭房间
  Future<void> closeRoom(String channelId) async {
    final result = await _httpRequest(
      'POST',
      '/api/room/$channelId/close',
    );
    final code = result['code'] as int? ?? -1;
    if (code != 0) {
      throw Exception(result['msg'] ?? '关闭房间失败');
    }
  }

  /// 获取房间详情
  Future<SyRoomInfo> getRoomDetail(String channelId) async {
    final result = await _httpRequest('GET', '/api/room/$channelId');
    final code = result['code'] as int? ?? -1;
    if (code != 0) {
      throw Exception(result['msg'] ?? '获取房间详情失败');
    }
    final data = result['data'];
    if (data is Map) {
      return SyRoomInfo.fromMap(Map<String, dynamic>.from(data));
    }
    return SyRoomInfo(channelId: channelId);
  }

  /// 查询频道在线人数
  Future<int> getOnlineCount(String channelId) async {
    final result = await _httpRequest(
      'GET',
      '/api/room/$channelId/online-count',
    );
    final code = result['code'] as int? ?? -1;
    if (code != 0) return 0;
    return result['count'] as int? ?? result['data'] as int? ?? 0;
  }

  /// 获取 RTC Token
  ///
  /// [channelId] 要加入的房间 ID
  /// [uid] 用户 ID
  /// [expireHours] 过期时间（小时），默认 24
  ///
  /// 返回用于 [SyRtcEngine.join] 的 RTC Token。
  Future<String> fetchToken({
    required String channelId,
    required String uid,
    int expireHours = 24,
  }) async {
    final result = await _httpRequest(
      'POST',
      '/api/rtc/token',
      queryParams: {
        'channelId': channelId,
        'uid': uid,
        'expireHours': expireHours.toString(),
      },
    );
    final code = result['code'] as int? ?? -1;
    if (code != 0) {
      throw Exception(result['msg'] ?? '获取 Token 失败');
    }
    final data = result['data'];
    if (data is String) return data;
    if (data != null) return data.toString();
    throw Exception('Token 响应格式错误');
  }
}
