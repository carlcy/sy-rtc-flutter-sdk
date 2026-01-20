library;

export 'src/sy_rtc_engine.dart';
export 'src/sy_rtc_config.dart';
export 'src/sy_rtc_config_extended.dart' 
  hide 
    // 音频相关
    SyAudioProfile, 
    SyAudioScenario,
    SyAudioRecordingConfiguration,
    SyAudioCodecType,
    SyAudioRecordingQuality,
    SyAudioMixingConfiguration,
    SyAudioEffectConfiguration,
    SyAudioDeviceInfo,
    // 视频相关
    SyVideoEncoderConfiguration,
    SyVideoOutputOrientationMode,
    SyDegradationPreference,
    SyVideoMirrorModeType,
    SyVideoDeviceInfo,
    SyScreenCaptureConfiguration,
    SyBeautyOptions,
    // 直播相关
    SyLiveTranscoding,
    SyTranscodingUser;
export 'src/sy_rtc_video_quality.dart';
export 'src/sy_rtc_event_handler.dart';
export 'src/sy_rtc_events.dart';
