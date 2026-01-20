/// SY RTC 配置扩展类
/// 
/// 包含所有音频、视频、直播相关的配置类

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

/// 音频录制配置
class SyAudioRecordingConfiguration {
  /// 文件路径
  final String filePath;

  /// 采样率（Hz）
  final int sampleRate;

  /// 声道数（1=单声道，2=双声道）
  final int channels;

  /// 编码格式
  final SyAudioCodecType codecType;

  /// 录音质量
  final SyAudioRecordingQuality quality;

  SyAudioRecordingConfiguration({
    required this.filePath,
    this.sampleRate = 32000,
    this.channels = 1,
    this.codecType = SyAudioCodecType.aacLc,
    this.quality = SyAudioRecordingQuality.medium,
  });
}

/// 音频编码格式
enum SyAudioCodecType {
  aacLc,    // AAC-LC
  heAac,    // HE-AAC
  heAacV2,  // HE-AAC v2
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

/// 旁路推流配置
class SyLiveTranscoding {
  /// 视频宽度
  final int width;

  /// 视频高度
  final int height;

  /// 视频码率（Kbps）
  final int videoBitrate;

  /// 视频帧率（fps）
  final int videoFramerate;

  /// 是否低延迟
  final bool lowLatency;

  /// 视频 GOP（秒）
  final int videoGop;

  /// 背景颜色
  final int backgroundColor;

  /// 水印图片路径
  final String? watermarkUrl;

  /// 水印位置
  final SyTranscodingUser? watermark;

  /// 用户列表
  final List<SyTranscodingUser>? transcodingUsers;

  SyLiveTranscoding({
    this.width = 360,
    this.height = 640,
    this.videoBitrate = 400,
    this.videoFramerate = 15,
    this.lowLatency = false,
    this.videoGop = 30,
    this.backgroundColor = 0x000000,
    this.watermarkUrl,
    this.watermark,
    this.transcodingUsers,
  });
}

/// 转码用户配置
class SyTranscodingUser {
  /// 用户ID
  final String uid;

  /// X 坐标（0.0-1.0）
  final double x;

  /// Y 坐标（0.0-1.0）
  final double y;

  /// 宽度（0.0-1.0）
  final double width;

  /// 高度（0.0-1.0）
  final double height;

  /// Z 顺序
  final int zOrder;

  /// 透明度（0.0-1.0）
  final double alpha;

  SyTranscodingUser({
    required this.uid,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.zOrder = 0,
    this.alpha = 1.0,
  });
}
