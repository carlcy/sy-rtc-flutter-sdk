import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

/// 调用后端 POST /api/rtc/token 获取 RTC Token
class TokenService {
  TokenService(this.config);

  final AppConfig config;

  /// 获取 RTC Token
  /// [channelId] 房间 ID
  /// [uid] 用户 ID
  /// [expireHours] 过期时间（小时），默认 24
  Future<String> fetchRtcToken({
    required String channelId,
    required String uid,
    int expireHours = 24,
  }) async {
    final jwt = config.jwt;
    if (jwt == null || jwt.isEmpty) {
      throw Exception('未配置 JWT，请在配置页填写 JWT 或手动输入 Token');
    }

    final uri = Uri.parse(config.tokenEndpoint).replace(
      queryParameters: {
        'channelId': channelId,
        'uid': uid,
        'expireHours': expireHours.toString(),
      },
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $jwt',
        'X-App-Id': config.appId,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final body = response.body;
      String msg = 'HTTP ${response.statusCode}';
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['msg'] != null) msg = json['msg'] as String;
      } catch (_) {}
      throw Exception('获取 Token 失败: $msg');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final code = json['code'] as int?;
    if (code != 200) {
      final msg = json['msg'] as String? ?? '未知错误';
      throw Exception('获取 Token 失败: $msg');
    }

    final data = json['data'];
    if (data is String) return data;
    if (data != null) return data.toString();
    throw Exception('Token 响应格式错误: data 为空');
  }
}
