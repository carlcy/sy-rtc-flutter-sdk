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

    // Room management
    func onRoomInfoUpdated(operatorUid: String, roomInfo: [String: Any]) {}
    func onRoomNoticeUpdated(operatorUid: String, notice: String) {}
    func onRoomManagerUpdated(uid: String, isManager: Bool, operatorUid: String) {}

    // Seat management
    func onSeatUpdated(seatIndex: Int, uid: String?, operatorUid: String, action: String) {}
    func onSeatRequestReceived(uid: String, seatIndex: Int?) {}
    func onSeatRequestHandled(operatorUid: String, approved: Bool, seatIndex: Int?) {}
    func onSeatInvitationReceived(operatorUid: String, seatIndex: Int) {}
    func onSeatInvitationHandled(uid: String, accepted: Bool, seatIndex: Int) {}

    // User management
    func onUserKicked(uid: String, operatorUid: String) {}
    func onUserMuted(uid: String, isMuted: Bool, operatorUid: String) {}
    func onUserBanned(uid: String, isBanned: Bool, operatorUid: String) {}

    // Chat & Gift
    func onRoomMessage(uid: String, messageType: String, content: String, extra: [String: Any]?) {}
    func onGiftReceived(fromUid: String, toUid: String, giftId: String, count: Int, extra: [String: Any]?) {}
}
