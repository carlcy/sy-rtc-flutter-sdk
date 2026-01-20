import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sy_rtc_flutter_sdk_platform_interface.dart';

/// An implementation of [SyRtcFlutterSdkPlatform] that uses method channels.
class MethodChannelSyRtcFlutterSdk extends SyRtcFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sy_rtc_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
