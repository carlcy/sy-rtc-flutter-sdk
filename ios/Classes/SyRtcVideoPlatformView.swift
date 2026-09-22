import Flutter
import UIKit

/// Flutter PlatformView container for WebRTC RTCMTLVideoView.
/// ViewType: sy_rtc_flutter_sdk/video_view
final class SyRtcVideoPlatformView: NSObject, FlutterPlatformView {
  static let viewType = "sy_rtc_flutter_sdk/video_view"
  private static var registry: [Int64: SyRtcVideoPlatformView] = [:]
  private static let lock = NSLock()

  let viewId: Int64
  let container: UIView

  init(frame: CGRect, viewId: Int64, args: Any?) {
    self.viewId = viewId
    self.container = UIView(frame: frame)
    self.container.backgroundColor = .black
    self.container.clipsToBounds = true
    super.init()
    Self.lock.lock()
    Self.registry[viewId] = self
    Self.lock.unlock()
  }

  func view() -> UIView { container }

  deinit {
    Self.lock.lock()
    Self.registry.removeValue(forKey: viewId)
    Self.lock.unlock()
  }

  static func container(for viewId: Int64) -> UIView? {
    lock.lock()
    defer { lock.unlock() }
    return registry[viewId]?.container
  }

  static func container(forInt viewId: Int) -> UIView? {
    container(for: Int64(viewId))
  }
}

final class SyRtcVideoPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    SyRtcVideoPlatformView(frame: frame, viewId: viewId, args: args)
  }
}
