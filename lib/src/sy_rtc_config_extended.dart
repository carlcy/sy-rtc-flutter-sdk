/// SY RTC 配置扩展类，包含音频、视频相关的配置。
library;

/// 音频配置
enum SyAudioProfile {
  defaultProfile,    // 默认配置（48 kHz，单声道，编码码率约 48 Kbps）
  speechStandard,   // 标准语音（32 kHz，单声道，编码码率约 18 Kbps）
  musicStandard,    // 标准音乐（48 kHz，单声道，编码码率约 64 Kbps）
  musicStandardStereo, // 标准立体声音乐（48 kHz，双声道，编码码率约 80 Kbps）
  musicHighQuality, // 高质量音乐（48 kHz，单声道，编码码率约 96 Kbps）
  musicHighQualityStereo, // 高质量立体声音乐（48 kHz，双声道，编码码率约 128 Kbps）
}

/// 音频场景
enum SyAudioScenario {
  defaultScenario,  // 默认场景
  chatRoom,         // 语聊房
  gameStreaming,    // 游戏直播
  showRoom,         // 秀场
  meeting,          // 会议
  education,        // 教育
}

/// 视频编码配置
class SyVideoEncoderConfiguration {
  /// 视频分辨率宽度
  final int width;

  /// 视频分辨率高度
  final int height;

  /// 帧率（fps）
  final int frameRate;

  /// 最小帧率（fps）
  final int minFrameRate;

  /// 码率（Kbps）
  final int bitrate;

  /// 最小码率（Kbps）
  final int minBitrate;

  /// 视频方向模式
  final SyVideoOutputOrientationMode orientationMode;

  /// 编码方向偏好
  final SyDegradationPreference degradationPreference;

  /// 镜像模式
  final SyVideoMirrorModeType mirrorMode;

  SyVideoEncoderConfiguration({
    this.width = 640,
    this.height = 480,
    this.frameRate = 15,
    this.minFrameRate = -1,
    this.bitrate = 0,
    this.minBitrate = -1,
    this.orientationMode = SyVideoOutputOrientationMode.adaptative,
    this.degradationPreference = SyDegradationPreference.maintainQuality,
    this.mirrorMode = SyVideoMirrorModeType.auto,
  });
}

/// 视频输出方向模式
enum SyVideoOutputOrientationMode {
  adaptative,      // 自适应模式
  fixedLandscape,  // 固定横屏
  fixedPortrait,   // 固定竖屏
}

/// 编码降级偏好
enum SyDegradationPreference {
  maintainQuality,  // 保持质量
  maintainFramerate, // 保持帧率
  balanced,          // 平衡
}

/// 视频镜像模式
enum SyVideoMirrorModeType {
  auto,     // 自动
  enabled,  // 启用
  disabled, // 禁用
}

/// 本地录音配置。两端原生 SDK 规则相同：
///
/// - [codecType]：[SyAudioCodecType.aacLc] 输出 AAC（MPEG-4，文件建议 `.m4a`）；[SyAudioCodecType.wav] 输出 16 bit WAV。
///   HE-AAC 两端都没有实现，传入时原生回调 `onError(1000)`，[SyRtcEngine.startAudioRecording] 返回 -1。不支持 mp3。
/// - 频道内：录 WebRTC 管线里的 PCM（本端采集 + 远端解码）混成单声道，不另开麦克风，
///   [includeLocal] / [includeRemote] 控制是否包含本端、远端。本端静音时不录本端，本端静音了某远端时不录他。
/// - 频道外：只录麦克风，仅 AAC。频道外开始的录音 join 后请重新开始。
/// - [channels] 目前只支持 1；[quality]：low 32 kbps、medium 64 kbps、high 128 kbps（仅 AAC）。leave 时自动停止。
class SyAudioRecordingConfiguration {
  /// 文件路径
  final String filePath;

  /// 采样率（Hz），8000–48000
  final int sampleRate;

  /// 声道数：目前只支持 1（混音输出为单声道）
  final int channels;

  /// 编码格式
  final SyAudioCodecType codecType;

  /// 录音质量（AAC 码率）
  final SyAudioRecordingQuality quality;

  /// 频道内录音是否包含本端采集
  final bool includeLocal;

  /// 频道内录音是否混入远端声音
  final bool includeRemote;

  SyAudioRecordingConfiguration({
    required this.filePath,
    this.sampleRate = 32000,
    this.channels = 1,
    this.codecType = SyAudioCodecType.aacLc,
    this.quality = SyAudioRecordingQuality.medium,
    this.includeLocal = true,
    this.includeRemote = true,
  });

  /// 传给原生的参数。
  Map<String, Object> toMap() => {
        'filePath': filePath,
        'sampleRate': sampleRate,
        'channels': channels,
        'codecType': codecType.name,
        'quality': quality.name,
        'includeLocal': includeLocal,
        'includeRemote': includeRemote,
      };
}

/// 录音编码格式
enum SyAudioCodecType {
  /// AAC-LC（.m4a）
  aacLc,

  /// 未实现：原生返回 -1 并回调 onError(1000)
  @Deprecated('两端都未实现 HE-AAC，请用 aacLc 或 wav')
  heAac,

  /// 未实现：原生返回 -1 并回调 onError(1000)
  @Deprecated('两端都未实现 HE-AAC v2，请用 aacLc 或 wav')
  heAacV2,

  /// 16 bit PCM WAV
  wav,
}

/// 录音质量
enum SyAudioRecordingQuality {
  low,     // 低质量
  medium,  // 中等质量
  high,    // 高质量
}

/// 音频混音配置
class SyAudioMixingConfiguration {
  /// 文件路径
  final String filePath;

  /// 是否循环播放
  final bool loopback;

  /// 是否替换麦克风采集
  final bool replace;

  /// 循环次数（-1 表示无限循环）
  final int cycle;

  /// 开始位置（毫秒）
  final int startPos;

  SyAudioMixingConfiguration({
    required this.filePath,
    this.loopback = false,
    this.replace = false,
    this.cycle = 1,
    this.startPos = 0,
  });
}

/// 音效配置
class SyAudioEffectConfiguration {
  /// 文件路径
  final String filePath;

  /// 循环次数（-1 表示无限循环）
  final int loopCount;

  /// 是否发送到远端
  final bool publish;

  /// 开始位置（毫秒）
  final int startPos;

  SyAudioEffectConfiguration({
    required this.filePath,
    this.loopCount = 1,
    this.publish = false,
    this.startPos = 0,
  });
}

/// 音频设备信息
class SyAudioDeviceInfo {
  /// 设备ID
  final String deviceId;

  /// 设备名称
  final String deviceName;

  SyAudioDeviceInfo({
    required this.deviceId,
    required this.deviceName,
  });
}

/// 视频设备信息
class SyVideoDeviceInfo {
  /// 设备ID
  final String deviceId;

  /// 设备名称
  final String deviceName;

  SyVideoDeviceInfo({
    required this.deviceId,
    required this.deviceName,
  });
}

/// 屏幕共享配置
class SyScreenCaptureConfiguration {
  /// 是否捕获鼠标
  final bool captureMouseCursor;

  /// 是否捕获窗口
  final bool captureWindow;

  /// 帧率（fps）
  final int frameRate;

  /// 码率（Kbps）
  final int bitrate;

  /// 宽度
  final int width;

  /// 高度
  final int height;

  SyScreenCaptureConfiguration({
    this.captureMouseCursor = true,
    this.captureWindow = false,
    this.frameRate = 15,
    this.bitrate = 0,
    this.width = 0,
    this.height = 0,
  });
}

/// 美颜配置
class SyBeautyOptions {
  /// 是否启用美颜
  final bool enabled;

  /// 美白程度（0.0-1.0）
  final double lighteningLevel;

  /// 红润程度（0.0-1.0）
  final double rednessLevel;

  /// 光滑程度（0.0-1.0）
  final double smoothnessLevel;

  SyBeautyOptions({
    this.enabled = false,
    this.lighteningLevel = 0.5,
    this.rednessLevel = 0.1,
    this.smoothnessLevel = 0.5,
  });
}

