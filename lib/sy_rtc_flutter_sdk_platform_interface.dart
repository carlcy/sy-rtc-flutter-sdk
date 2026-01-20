import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sy_rtc_flutter_sdk_method_channel.dart';

abstract class SyRtcFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a SyRtcFlutterSdkPlatform.
  SyRtcFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static SyRtcFlutterSdkPlatform _instance = MethodChannelSyRtcFlutterSdk();

  /// The default instance of [SyRtcFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelSyRtcFlutterSdk].
  static SyRtcFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SyRtcFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(SyRtcFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
