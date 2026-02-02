/// 示例应用配置
///
/// 用于配置 API 基础地址、信令地址、AppId 及可选的 JWT（用于拉取 RTC Token）。
class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.signalingUrl,
    required this.appId,
    this.jwt,
  });

  /// API 基础 URL，如 https://api.example.com（不要末尾斜杠）
  final String apiBaseUrl;

  /// 信令 WebSocket URL，如 wss://api.example.com/ws/signaling
  final String signalingUrl;

  /// 应用 ID
  final String appId;

  /// 用户 JWT，用于调用 POST /api/rtc/token 获取 RTC Token（可选，不填则需手动输入 Token）
  final String? jwt;

  String get tokenEndpoint => '$apiBaseUrl/api/rtc/token';

  AppConfig copyWith({
    String? apiBaseUrl,
    String? signalingUrl,
    String? appId,
    String? jwt,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      signalingUrl: signalingUrl ?? this.signalingUrl,
      appId: appId ?? this.appId,
      jwt: jwt ?? this.jwt,
    );
  }
}
