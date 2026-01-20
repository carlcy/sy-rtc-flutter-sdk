import Flutter
import UIKit

public class SyRtcFlutterSdkPlugin: NSObject, FlutterPlugin {
  private var engine: SyRtcEngine?
  private var eventChannel: FlutterMethodChannel?
  private var appFeatures: Set<String> = ["voice"] // 默认只有语聊功能
  private var apiBaseUrl: String?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "sy_rtc_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = SyRtcFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    instance.eventChannel = FlutterMethodChannel(name: "sy_rtc_flutter_sdk/events", binaryMessenger: registrar.messenger())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      if let args = call.arguments as? [String: Any],
         let appId = args["appId"] as? String {
        engine = SyRtcEngine.shared
        engine?.initialize(appId: appId)
        apiBaseUrl = args["apiBaseUrl"] as? String
        if let signalingUrl = args["signalingUrl"] as? String, !signalingUrl.isEmpty {
          engine?.setSignalingServerUrl(signalingUrl)
        }
        // 如果提供了API URL，查询功能权限
        if let apiUrl = apiBaseUrl, !apiUrl.isEmpty {
          checkFeatures(appId: appId, apiBaseUrl: apiUrl)
        } else {
          // 默认只有语聊功能
          appFeatures = ["voice"]
        }
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "appId is required", details: nil))
      }
      
    case "checkFeatures":
      if let args = call.arguments as? [String: Any],
         let appId = args["appId"] as? String,
         let apiUrl = args["apiBaseUrl"] as? String {
        checkFeatures(appId: appId, apiBaseUrl: apiUrl)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "appId and apiBaseUrl are required", details: nil))
      }
      
    case "hasFeature":
      if let args = call.arguments as? [String: Any],
         let feature = args["feature"] as? String {
        result(appFeatures.contains(feature))
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "feature is required", details: nil))
      }
      
    case "join":
      if let args = call.arguments as? [String: Any],
         let channelId = args["channelId"] as? String,
         let uid = args["uid"] as? String,
         let token = args["token"] as? String {
        engine?.setEventHandler(self)
        engine?.join(channelId: channelId, uid: uid, token: token)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "channelId, uid, token are required", details: nil))
      }
      
    case "leave":
      engine?.leave()
      result(true)
      
    case "enableLocalAudio":
      if let args = call.arguments as? [String: Any],
         let enabled = args["enabled"] as? Bool {
        engine?.enableLocalAudio(enabled)
        result(true)
      } else {
        result(false)
      }
      
    case "muteLocalAudio":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        engine?.muteLocalAudio(muted)
        result(true)
      } else {
        result(false)
      }
      
    case "setClientRole":
      if let args = call.arguments as? [String: Any],
         let roleStr = args["role"] as? String {
        let role: SyRtcClientRole = roleStr == "host" ? .host : .audience
        engine?.setClientRole(role)
        result(true)
      } else {
        result(false)
      }
      
    case "setVideoEncoderConfiguration":
      if let args = call.arguments as? [String: Any] {
        let width = args["width"] as? Int ?? 640
        let height = args["height"] as? Int ?? 480
        let frameRate = args["frameRate"] as? Int ?? 15
        let bitrate = args["bitrate"] as? Int ?? 400
        if !appFeatures.contains("live") {
          result(FlutterError(code: "FEATURE_NOT_ENABLED", message: "当前AppId未开通直播功能", details: nil))
        } else {
          engine?.setVideoEncoderConfiguration(width: width, height: height, frameRate: frameRate, bitrate: bitrate)
          result(true)
        }
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid video encoder configuration", details: nil))
      }
      
    case "setAudioQuality":
      if let args = call.arguments as? [String: Any],
         let quality = args["quality"] as? String {
        engine?.setAudioQuality(quality)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "quality is required", details: nil))
      }
      
    case "enableVideo":
      if !appFeatures.contains("live") {
        result(FlutterError(code: "FEATURE_NOT_ENABLED", message: "当前AppId未开通直播功能", details: nil))
      } else {
        engine?.enableVideo()
        result(true)
      }
      
    case "release":
      engine?.release()
      engine = nil
      result(true)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

  private func checkFeatures(appId: String, apiBaseUrl: String) {
    let urlString = "\(apiBaseUrl)/api/rtc/feature/\(appId)"
    guard let url = URL(string: urlString) else {
      appFeatures = ["voice"]
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 5.0
    
    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }
      
      if let error = error {
        // 查询失败，使用默认值
        self.appFeatures = ["voice"]
        print("功能权限查询失败: \(error.localizedDescription)")
        return
      }
      
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let code = json["code"] as? Int,
            code == 0,
            let dataObj = json["data"] as? [String: Any],
            let featuresArray = dataObj["features"] as? [String] else {
        self.appFeatures = ["voice"]
        return
      }
      
      self.appFeatures = Set(featuresArray)
    }
    
    task.resume()
  }
}

extension SyRtcFlutterSdkPlugin: SyRtcEventHandler {
  public func onUserJoined(uid: String, elapsed: Int) {
    eventChannel?.invokeMethod("onUserJoined", arguments: ["uid": uid, "elapsed": elapsed])
  }
  
  public func onUserOffline(uid: String, reason: String) {
    eventChannel?.invokeMethod("onUserOffline", arguments: ["uid": uid, "reason": reason])
  }
  
  public func onVolumeIndication(speakers: [SyVolumeInfo]) {
    let speakersList = speakers.map { ["uid": $0.uid, "volume": $0.volume] }
    eventChannel?.invokeMethod("onVolumeIndication", arguments: ["speakers": speakersList])
  }

  public func onError(code: Int, message: String) {
    eventChannel?.invokeMethod("onError", arguments: ["errCode": code, "errMsg": message])
  }
}
