import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'sy_rtc_engine.dart';

/// Native video surface (AndroidView / UiKitView) wired to
/// [SyRtcEngine.setupLocalVideo] / [SyRtcEngine.setupRemoteVideo].
///
/// ViewType: `sy_rtc_flutter_sdk/video_view`
class SyRtcVideoView extends StatefulWidget {
  const SyRtcVideoView({
    super.key,
    required this.engine,
    this.uid,
    this.mirror = false,
  });

  /// Local preview when null / empty; otherwise remote [uid].
  final SyRtcEngine engine;
  final String? uid;
  final bool mirror;

  static const String viewType = 'sy_rtc_flutter_sdk/video_view';

  bool get isLocal => uid == null || uid!.isEmpty;

  @override
  State<SyRtcVideoView> createState() => _SyRtcVideoViewState();
}

class _SyRtcVideoViewState extends State<SyRtcVideoView> {
  int? _viewId;

  Future<void> _bind(int viewId) async {
    _viewId = viewId;
    try {
      if (widget.isLocal) {
        await widget.engine.setupLocalVideo(viewId);
      } else {
        await widget.engine.setupRemoteVideo(widget.uid!, viewId);
      }
    } catch (e) {
      debugPrint('SyRtcVideoView bind failed: $e');
    }
  }

  @override
  void didUpdateWidget(covariant SyRtcVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final viewId = _viewId;
    if (viewId == null) return;
    if (oldWidget.uid != widget.uid || oldWidget.engine != widget.engine) {
      _bind(viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ColoredBox(
        color: Color(0xFF000000),
        child: Center(
          child: Text(
            'Video PlatformView is mobile-only',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ),
      );
    }

    final creationParams = <String, dynamic>{
      'uid': widget.uid ?? '',
      'mirror': widget.mirror || widget.isLocal,
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: SyRtcVideoView.viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        onPlatformViewCreated: (id) => _bind(id),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    }
    if (Platform.isIOS) {
      return UiKitView(
        viewType: SyRtcVideoView.viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        onPlatformViewCreated: (id) => _bind(id),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    }
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Center(
        child: Text(
          'Unsupported platform',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
        ),
      ),
    );
  }
}
