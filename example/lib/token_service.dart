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
    final appSecret = config.appSecret;
    if ((jwt == null || jwt.isEmpty) && (appSecret == null || appSecret.isEmpty)) {
      throw Exception('未配置 JWT 或 AppSecret，请在配置页填写（demo 可用 AppSecret）');
    }

    final uri = Uri.parse(config.tokenEndpoint).replace(
      queryParameters: {
        'channelId': channelId,
        'uid': uid,
        'expireHours': expireHours.toString(),
      },
    );

    final headers = <String, String>{
      'X-App-Id': config.appId,
      'Content-Type': 'application/json',
    };
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    if (appSecret != null && appSecret.isNotEmpty) {
      headers['X-App-Secret'] = appSecret;
    }

    final response = await http.post(
      uri,
      headers: headers,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Token请求超时(10s)，请检查API地址: $uri'),
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
    if (code != 0) {
      final msg = json['msg'] as String? ?? '未知错误';
      throw Exception('获取 Token 失败: $msg');
    }

    final data = json['data'];
    if (data is String) return data;
    if (data != null) return data.toString();
    throw Exception('Token 响应格式错误: data 为空');
  }
}
