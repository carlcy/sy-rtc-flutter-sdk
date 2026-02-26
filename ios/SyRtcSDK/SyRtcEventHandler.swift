import Foundation

/// SY RTC事件处理器协议
public protocol SyRtcEventHandler: AnyObject {
    /// 用户加入回调
    func onUserJoined(uid: String, elapsed: Int)
    
    /// 用户离开回调
    func onUserOffline(uid: String, reason: String)
    
    /// 音量指示回调
    func onVolumeIndication(speakers: [SyVolumeInfo])

    /// 错误回调（可选）
    func onError(code: Int, message: String)

    /// 数据流消息回调（可选）
    func onStreamMessage(uid: String, streamId: Int, data: Data)

    /// 数据流消息错误回调（可选）
    func onStreamMessageError(uid: String, streamId: Int, code: Int, missed: Int, cached: Int)

    /// 频道消息回调
    func onChannelMessage(uid: String, message: String)
}

// MARK: - Optional callbacks (default empty implementations)

/// 默认实现：保持向后兼容（实现方可选择不实现以下可选回调）
public extension SyRtcEventHandler {
    func onJoinChannelSuccess(channelId: String, uid: String, elapsed: Int) {}
    func onLeaveChannel(stats: [String: Any]) {}
    func onRejoinChannelSuccess(channelId: String, uid: String, elapsed: Int) {}
    func onRtcStats(stats: [String: Any]) {}
    func onUserMuteAudio(uid: String, muted: Bool) {}
    func onConnectionStateChanged(state: String, reason: String) {}
    func onNetworkQuality(uid: String, txQuality: String, rxQuality: String) {}
    func onTokenPrivilegeWillExpire() {}
    func onRequestToken() {}
    func onLocalAudioStateChanged(state: String, error: String) {}
    func onRemoteAudioStateChanged(uid: String, state: String, reason: String, elapsed: Int) {}
    func onLocalVideoStateChanged(state: String, error: String) {}
    func onRemoteVideoStateChanged(uid: String, state: String, reason: String, elapsed: Int) {}
    func onFirstRemoteVideoDecoded(uid: String, width: Int, height: Int, elapsed: Int) {}
    func onFirstRemoteVideoFrame(uid: String, width: Int, height: Int, elapsed: Int) {}
    func onVideoSizeChanged(uid: String, width: Int, height: Int, rotation: Int) {}
    func onAudioRoutingChanged(routing: Int) {}
    func onAudioPublishStateChanged(channelId: String, oldState: String, newState: String, elapsed: Int) {}
    func onAudioSubscribeStateChanged(channelId: String, uid: String, oldState: String, newState: String, elapsed: Int) {}
}

/// 音量信息
public struct SyVolumeInfo {
    public let uid: String
    public let volume: Int
    
    public init(uid: String, volume: Int) {
        self.uid = uid
        self.volume = volume
    }
}

public extension SyRtcEventHandler {
    func onError(code: Int, message: String) {}
    func onStreamMessage(uid: String, streamId: Int, data: Data) {}
    func onStreamMessageError(uid: String, streamId: Int, code: Int, missed: Int, cached: Int) {}
    func onChannelMessage(uid: String, message: String) {}
}
