/// 视频画质预设
/// 
/// 提供多种画质选项，确保直播流畅性

/// 画质等级
enum SyVideoQualityLevel {
  /// 流畅优先：低码率、低分辨率，确保流畅性
  /// 适用于：弱网环境、移动网络
  smooth,
  
  /// 标准画质：平衡码率和分辨率
  /// 适用于：一般网络环境
  standard,
  
  /// 高清画质：较高码率和分辨率
  /// 适用于：良好网络环境
  hd,
  
  /// 超清画质：高码率、高分辨率
  /// 适用于：优秀网络环境、WiFi
  uhd,
  
  /// 4K画质：极高码率、4K分辨率
  /// 适用于：极佳网络环境、有线网络
  ultraHd,
}

/// 视频画质预设配置
class SyVideoQualityPreset {
  /// 画质等级
  final SyVideoQualityLevel level;
  
  /// 分辨率宽度
  final int width;
  
  /// 分辨率高度
  final int height;
  
  /// 帧率（fps）
  final int frameRate;
  
  /// 码率（kbps）
  final int bitrate;
  
  /// 最小码率（kbps）
  final int minBitrate;
  
  /// 最大码率（kbps）
  final int maxBitrate;
  
  /// 是否自适应调整
  final bool adaptive;
  
  /// 描述
  final String description;
  
  SyVideoQualityPreset({
    required this.level,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    this.minBitrate = 0,
    this.maxBitrate = 0,
    this.adaptive = true,
    required this.description,
  });
  
  /// 创建流畅优先画质
  factory SyVideoQualityPreset.smooth() {
    return SyVideoQualityPreset(
      level: SyVideoQualityLevel.smooth,
      width: 426,
      height: 240,
      frameRate: 15,
      bitrate: 150,
      minBitrate: 75,
      maxBitrate: 225,
      description: '流畅优先 (240p, 15fps, 150kbps)',
    );
  }
  
  /// 创建标准画质
  factory SyVideoQualityPreset.standard() {
    return SyVideoQualityPreset(
      level: SyVideoQualityLevel.standard,
      width: 854,
      height: 480,
      frameRate: 20,
      bitrate: 400,
      minBitrate: 200,
      maxBitrate: 600,
      description: '标准画质 (480p, 20fps, 400kbps)',
    );
  }
  
  /// 创建高清画质
  factory SyVideoQualityPreset.hd() {
    return SyVideoQualityPreset(
      level: SyVideoQualityLevel.hd,
      width: 1280,
      height: 720,
      frameRate: 25,
      bitrate: 800,
      minBitrate: 400,
      maxBitrate: 1200,
      description: '高清画质 (720p, 25fps, 800kbps)',
    );
  }
  
  /// 创建超清画质
  factory SyVideoQualityPreset.uhd() {
    return SyVideoQualityPreset(
      level: SyVideoQualityLevel.uhd,
      width: 1920,
      height: 1080,
      frameRate: 30,
      bitrate: 2000,
      minBitrate: 1000,
      maxBitrate: 3000,
      description: '超清画质 (1080p, 30fps, 2000kbps)',
    );
  }
  
  /// 创建4K画质
  factory SyVideoQualityPreset.ultraHd() {
    return SyVideoQualityPreset(
      level: SyVideoQualityLevel.ultraHd,
      width: 3840,
      height: 2160,
      frameRate: 30,
      bitrate: 5000,
      minBitrate: 2500,
      maxBitrate: 7500,
      description: '4K画质 (2160p, 30fps, 5000kbps)',
    );
  }
  
  /// 根据等级创建预设
  factory SyVideoQualityPreset.fromLevel(SyVideoQualityLevel level) {
    switch (level) {
      case SyVideoQualityLevel.smooth:
        return SyVideoQualityPreset.smooth();
      case SyVideoQualityLevel.standard:
        return SyVideoQualityPreset.standard();
      case SyVideoQualityLevel.hd:
        return SyVideoQualityPreset.hd();
      case SyVideoQualityLevel.uhd:
        return SyVideoQualityPreset.uhd();
      case SyVideoQualityLevel.ultraHd:
        return SyVideoQualityPreset.ultraHd();
    }
  }
  
  /// 转换为视频编码配置Map（用于原生调用）
  Map<String, dynamic> toEncoderConfigMap() {
    return {
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'minFrameRate': frameRate - 5,
      'bitrate': bitrate,
      'minBitrate': minBitrate,
      'orientationMode': 'adaptative',
      'degradationPreference': 'balanced',
      'mirrorMode': 'auto',
    };
  }
}

/// 音频质量等级
enum SyAudioQualityLevel {
  /// 低质量：基础处理，低延迟
  low,
  
  /// 中等质量：标准处理
  medium,
  
  /// 高质量：增强处理
  high,
  
  /// 超高质量：极致处理
  ultra,
}
