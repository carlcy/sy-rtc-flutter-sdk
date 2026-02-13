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
}
