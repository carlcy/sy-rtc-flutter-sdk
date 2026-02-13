import Foundation

/// SY RTC引擎主类
/// 
/// SY RTC 引擎主类，提供实时音视频通信功能
public class SyRtcEngine {
    private var appId: String?
    private var eventHandler: SyRtcEventHandler?
    private var impl: SyRtcEngineImpl?
    
    /// 单例
    public static let shared = SyRtcEngine()
    
    private init() {}
    
    /// 初始化引擎
    /// 
    /// - Parameter appId: 应用ID
    public func initialize(appId: String) {
        self.appId = appId
        impl = SyRtcEngineImpl(appId: appId)
        impl?.initialize()
    }
    
    /// 初始化引擎（兼容旧API）
    public func `init`(_ appId: String) {
        initialize(appId: appId)
    }
    
    /// 加入频道
    public func join(channelId: String, uid: String, token: String) {
        impl?.eventHandler = eventHandler
        impl?.join(channelId: channelId, uid: uid, token: token)
    }
    
    /// 离开频道
    public func leave() {
        impl?.leave()
    }
    
    /// 启用/禁用本地音频
    public func enableLocalAudio(_ enabled: Bool) {
        impl?.enableLocalAudio(enabled)
    }
    
    /// 静音本地音频
    public func muteLocalAudio(_ muted: Bool) {
        impl?.muteLocalAudio(muted)
    }
    
    /// 设置客户端角色
    public func setClientRole(_ role: SyRtcClientRole) {
        impl?.setClientRole(role)
    }
    
    /// 设置事件处理器
    public func setEventHandler(_ handler: SyRtcEventHandler) {
        self.eventHandler = handler
        impl?.eventHandler = handler
    }
    
    /// 设置信令服务器地址（可选）
    public func setSignalingServerUrl(_ url: String) {
        impl?.setSignalingServerUrl(url)
    }

    /// 设置后端 API Base URL（用于直播旁路：开播/关播/切布局/更新转码等）
    public func setApiBaseUrl(_ url: String) {
        impl?.setApiBaseUrl(url)
    }

    /// 设置后端 API 认证 Token（JWT）
    /// 用于调用 /api/rtc/live/* 等需要登录认证的接口
    public func setApiAuthToken(_ token: String) {
        impl?.setApiAuthToken(token)
    }
    
    /// 启用视频模块
    public func enableVideo() {
        impl?.enableVideo()
    }
    
    /// 设置视频编码配置
    public func setVideoEncoderConfiguration(width: Int, height: Int, frameRate: Int, bitrate: Int) {
        impl?.setVideoEncoderConfiguration(width: width, height: height, frameRate: frameRate, bitrate: bitrate)
    }
    
    /// 开始视频预览
    public func startPreview() {
        impl?.startPreview()
    }
    
    /// 停止视频预览
    public func stopPreview() {
        impl?.stopPreview()
    }
    
    /// 设置本地视频视图
    public func setupLocalVideo(viewId: Int) {
        impl?.setupLocalVideo(viewId: viewId)
    }
    
    /// 设置远端视频视图
    public func setupRemoteVideo(uid: String, viewId: Int) {
        impl?.setupRemoteVideo(uid: uid, viewId: viewId)
    }
    
    /// 设置音频质量
    public func setAudioQuality(_ quality: String) {
        impl?.setAudioQuality(quality)
    }

    // MARK: - 网络质量/状态

    public func getConnectionState() -> String {
        return impl?.getConnectionState() ?? "disconnected"
    }

    public func getNetworkType() -> String {
        return impl?.getNetworkType() ?? "unknown"
    }

    // MARK: - 音频路由/设备

    public func setEnableSpeakerphone(_ enabled: Bool) {
        impl?.setEnableSpeakerphone(enabled)
    }

    public func setDefaultAudioRouteToSpeakerphone(_ enabled: Bool) {
        impl?.setDefaultAudioRouteToSpeakerphone(enabled)
    }

    public func isSpeakerphoneEnabled() -> Bool {
        return impl?.isSpeakerphoneEnabled() ?? false
    }

    public func enumerateRecordingDevices() -> [AudioDeviceInfo] {
        return impl?.enumerateRecordingDevices() ?? []
    }

    public func enumeratePlaybackDevices() -> [AudioDeviceInfo] {
        return impl?.enumeratePlaybackDevices() ?? []
    }

    public func setRecordingDevice(_ deviceId: String) -> Int {
        return impl?.setRecordingDevice(deviceId) ?? -1
    }

    public func setPlaybackDevice(_ deviceId: String) -> Int {
        return impl?.setPlaybackDevice(deviceId) ?? -1
    }

    public func getRecordingDeviceVolume() -> Int {
        return impl?.getRecordingDeviceVolume() ?? 0
    }

    public func setRecordingDeviceVolume(_ volume: Int) {
        impl?.setRecordingDeviceVolume(volume)
    }

    public func getPlaybackDeviceVolume() -> Int {
        return impl?.getPlaybackDeviceVolume() ?? 0
    }

    public func setPlaybackDeviceVolume(_ volume: Int) {
        impl?.setPlaybackDeviceVolume(volume)
    }

    // MARK: - 远端音频控制

    public func muteRemoteAudioStream(uid: String, muted: Bool) {
        impl?.muteRemoteAudioStream(uid: uid, muted: muted)
    }

    public func muteAllRemoteAudioStreams(_ muted: Bool) {
        impl?.muteAllRemoteAudioStreams(muted)
    }

    public func adjustUserPlaybackSignalVolume(uid: String, volume: Int) {
        impl?.adjustUserPlaybackSignalVolume(uid: uid, volume: volume)
    }

    public func adjustPlaybackSignalVolume(_ volume: Int) {
        impl?.adjustPlaybackSignalVolume(volume)
    }

    // MARK: - 录音信号

    public func adjustRecordingSignalVolume(_ volume: Int) {
        impl?.adjustRecordingSignalVolume(volume)
    }

    public func muteRecordingSignal(_ muted: Bool) {
        impl?.muteRecordingSignal(muted)
    }

    // MARK: - Token

    public func renewToken(_ token: String) {
        impl?.renewToken(token)
    }

    // MARK: - 音频参数

    public func setAudioProfile(_ profile: String, scenario: String) {
        impl?.setAudioProfile(profile, scenario: scenario)
    }

    public func enableAudio() {
        impl?.enableAudio()
    }

    public func disableAudio() {
        impl?.disableAudio()
    }

    // MARK: - 视频

    public func disableVideo() {
        impl?.disableVideo()
    }

    public func enableLocalVideo(_ enabled: Bool) {
        impl?.enableLocalVideo(enabled)
    }

    public func muteLocalVideoStream(_ muted: Bool) {
        impl?.muteLocalVideoStream(muted)
    }

    public func muteRemoteVideoStream(uid: String, muted: Bool) {
        impl?.muteRemoteVideoStream(uid: uid, muted: muted)
    }

    public func muteAllRemoteVideoStreams(_ muted: Bool) {
        impl?.muteAllRemoteVideoStreams(muted)
    }

    // MARK: - 屏幕共享

    public func startScreenCapture(_ config: ScreenCaptureConfiguration) {
        impl?.startScreenCapture(config)
    }

    public func stopScreenCapture() {
        impl?.stopScreenCapture()
    }

    public func updateScreenCaptureConfiguration(_ config: ScreenCaptureConfiguration) {
        impl?.updateScreenCaptureConfiguration(config)
    }

    // MARK: - 美颜

    public func setBeautyEffectOptions(_ options: BeautyOptions) {
        impl?.setBeautyEffectOptions(options)
    }

    // MARK: - 音频混音

    public func startAudioMixing(_ config: AudioMixingConfiguration) {
        impl?.startAudioMixing(config)
    }

    public func stopAudioMixing() {
        impl?.stopAudioMixing()
    }

    public func pauseAudioMixing() {
        impl?.pauseAudioMixing()
    }

    public func resumeAudioMixing() {
        impl?.resumeAudioMixing()
    }

    public func adjustAudioMixingVolume(_ volume: Int) {
        impl?.adjustAudioMixingVolume(volume)
    }

    public func getAudioMixingCurrentPosition() -> Int {
        return impl?.getAudioMixingCurrentPosition() ?? 0
    }

    public func setAudioMixingPosition(_ position: Int) {
        impl?.setAudioMixingPosition(position)
    }

    // MARK: - 音效

    public func playEffect(soundId: Int, config: AudioEffectConfiguration) {
        impl?.playEffect(soundId: soundId, config: config)
    }

    public func stopEffect(_ soundId: Int) {
        impl?.stopEffect(soundId)
    }

    public func stopAllEffects() {
        impl?.stopAllEffects()
    }

    public func setEffectsVolume(_ volume: Int) {
        impl?.setEffectsVolume(volume)
    }

    public func preloadEffect(_ soundId: Int, filePath: String) {
        impl?.preloadEffect(soundId, filePath: filePath)
    }

    public func unloadEffect(_ soundId: Int) {
        impl?.unloadEffect(soundId)
    }

    // MARK: - 音频录制

    public func startAudioRecording(_ config: AudioRecordingConfiguration) -> Int {
        return impl?.startAudioRecording(config) ?? -1
    }

    public func stopAudioRecording() {
        impl?.stopAudioRecording()
    }

    // MARK: - 数据流

    public func createDataStream(reliable: Bool, ordered: Bool) -> Int {
        return impl?.createDataStream(reliable: reliable, ordered: ordered) ?? 0
    }

    public func sendStreamMessage(streamId: Int, data: Data) {
        impl?.sendStreamMessage(streamId: streamId, data: data)
    }

    // MARK: - 旁路推流（RTMP）

    public func startRtmpStreamWithTranscoding(url: String, transcoding: LiveTranscoding) {
        impl?.startRtmpStreamWithTranscoding(url: url, transcoding: transcoding)
    }

    public func stopRtmpStream(url: String) {
        impl?.stopRtmpStream(url: url)
    }

    public func updateRtmpTranscoding(_ transcoding: LiveTranscoding) {
        impl?.updateRtmpTranscoding(transcoding: transcoding)
    }

    // MARK: - 截图

    public func takeSnapshot(uid: String, filePath: String) {
        impl?.takeSnapshot(uid: uid, filePath: filePath)
    }
    
    /// 释放资源
    public func release() {
        eventHandler = nil
        appId = nil
    }
}
