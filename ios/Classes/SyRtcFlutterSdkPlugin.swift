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
        if let apiUrl = apiBaseUrl, !apiUrl.isEmpty {
          engine?.setApiBaseUrl(apiUrl)
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
      
    case "setApiAuthToken":
      if let args = call.arguments as? [String: Any],
         let token = args["token"] as? String {
        engine?.setApiAuthToken(token)
        result(true)
      } else {
        result(false)
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
      
    case "sendChannelMessage":
      if let args = call.arguments as? [String: Any],
         let message = args["message"] as? String {
        engine?.sendChannelMessage(message)
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

    case "disableVideo":
      engine?.disableVideo()
      result(true)

    case "enableAudio":
      engine?.enableAudio()
      result(true)

    case "disableAudio":
      engine?.disableAudio()
      result(true)

    case "setAudioProfile":
      if let args = call.arguments as? [String: Any] {
        let profile = args["profile"] as? String ?? "default"
        let scenario = args["scenario"] as? String ?? "default"
        engine?.setAudioProfile(profile, scenario: scenario)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid audio profile", details: nil))
      }

    case "setEnableSpeakerphone":
      if let args = call.arguments as? [String: Any],
         let enabled = args["enabled"] as? Bool {
        engine?.setEnableSpeakerphone(enabled)
        result(true)
      } else {
        result(false)
      }

    case "setDefaultAudioRouteToSpeakerphone":
      if let args = call.arguments as? [String: Any],
         let enabled = args["enabled"] as? Bool {
        engine?.setDefaultAudioRouteToSpeakerphone(enabled)
        result(true)
      } else {
        result(false)
      }

    case "isSpeakerphoneEnabled":
      result(engine?.isSpeakerphoneEnabled() ?? false)

    case "enumerateRecordingDevices":
      let devices = engine?.enumerateRecordingDevices() ?? []
      result(devices.map { ["deviceId": $0.deviceId, "deviceName": $0.deviceName] })

    case "enumeratePlaybackDevices":
      let devices = engine?.enumeratePlaybackDevices() ?? []
      result(devices.map { ["deviceId": $0.deviceId, "deviceName": $0.deviceName] })

    case "setRecordingDevice":
      if let args = call.arguments as? [String: Any],
         let deviceId = args["deviceId"] as? String {
        result(engine?.setRecordingDevice(deviceId) ?? -1)
      } else {
        result(-1)
      }

    case "setPlaybackDevice":
      if let args = call.arguments as? [String: Any],
         let deviceId = args["deviceId"] as? String {
        result(engine?.setPlaybackDevice(deviceId) ?? -1)
      } else {
        result(-1)
      }

    case "getRecordingDeviceVolume":
      result(engine?.getRecordingDeviceVolume() ?? 0)

    case "setRecordingDeviceVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.setRecordingDeviceVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "getPlaybackDeviceVolume":
      result(engine?.getPlaybackDeviceVolume() ?? 0)

    case "setPlaybackDeviceVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.setPlaybackDeviceVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "muteRemoteAudioStream":
      if let args = call.arguments as? [String: Any],
         let uid = args["uid"] as? String,
         let muted = args["muted"] as? Bool {
        engine?.muteRemoteAudioStream(uid: uid, muted: muted)
        result(true)
      } else {
        result(false)
      }

    case "muteAllRemoteAudioStreams":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        engine?.muteAllRemoteAudioStreams(muted)
        result(true)
      } else {
        result(false)
      }

    case "adjustUserPlaybackSignalVolume":
      if let args = call.arguments as? [String: Any],
         let uid = args["uid"] as? String,
         let volume = args["volume"] as? Int {
        engine?.adjustUserPlaybackSignalVolume(uid: uid, volume: volume)
        result(true)
      } else {
        result(false)
      }

    case "adjustPlaybackSignalVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.adjustPlaybackSignalVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "renewToken":
      if let args = call.arguments as? [String: Any],
         let token = args["token"] as? String {
        engine?.renewToken(token)
        result(true)
      } else {
        result(false)
      }

    case "getConnectionState":
      result(engine?.getConnectionState() ?? "disconnected")

    case "getNetworkType":
      result(engine?.getNetworkType() ?? "unknown")

    case "adjustRecordingSignalVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.adjustRecordingSignalVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "muteRecordingSignal":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        engine?.muteRecordingSignal(muted)
        result(true)
      } else {
        result(false)
      }

    case "enableLocalVideo":
      if let args = call.arguments as? [String: Any],
         let enabled = args["enabled"] as? Bool {
        engine?.enableLocalVideo(enabled)
        result(true)
      } else {
        result(false)
      }

    case "startPreview":
      engine?.startPreview()
      result(true)

    case "stopPreview":
      engine?.stopPreview()
      result(true)

    case "muteLocalVideoStream":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        engine?.muteLocalVideoStream(muted)
        result(true)
      } else {
        result(false)
      }

    case "muteRemoteVideoStream":
      if let args = call.arguments as? [String: Any],
         let uid = args["uid"] as? String,
         let muted = args["muted"] as? Bool {
        engine?.muteRemoteVideoStream(uid: uid, muted: muted)
        result(true)
      } else {
        result(false)
      }

    case "muteAllRemoteVideoStreams":
      if let args = call.arguments as? [String: Any],
         let muted = args["muted"] as? Bool {
        engine?.muteAllRemoteVideoStreams(muted)
        result(true)
      } else {
        result(false)
      }

    case "setupLocalVideo":
      if let args = call.arguments as? [String: Any],
         let viewId = args["viewId"] as? Int {
        engine?.setupLocalVideo(viewId: viewId)
        result(true)
      } else {
        result(false)
      }

    case "setupRemoteVideo":
      if let args = call.arguments as? [String: Any],
         let uid = args["uid"] as? String,
         let viewId = args["viewId"] as? Int {
        engine?.setupRemoteVideo(uid: uid, viewId: viewId)
        result(true)
      } else {
        result(false)
      }

    case "startScreenCapture":
      if let args = call.arguments as? [String: Any] {
        let config = ScreenCaptureConfiguration(
          captureMouseCursor: args["captureMouseCursor"] as? Bool ?? true,
          captureWindow: args["captureWindow"] as? Bool ?? false,
          frameRate: args["frameRate"] as? Int ?? 15,
          bitrate: args["bitrate"] as? Int ?? 0,
          width: args["width"] as? Int ?? 0,
          height: args["height"] as? Int ?? 0
        )
        engine?.startScreenCapture(config)
        result(true)
      } else {
        result(false)
      }

    case "stopScreenCapture":
      engine?.stopScreenCapture()
      result(true)

    case "updateScreenCaptureConfiguration":
      if let args = call.arguments as? [String: Any] {
        let config = ScreenCaptureConfiguration(
          captureMouseCursor: args["captureMouseCursor"] as? Bool ?? true,
          captureWindow: args["captureWindow"] as? Bool ?? false,
          frameRate: args["frameRate"] as? Int ?? 15,
          bitrate: args["bitrate"] as? Int ?? 0,
          width: args["width"] as? Int ?? 0,
          height: args["height"] as? Int ?? 0
        )
        engine?.updateScreenCaptureConfiguration(config)
        result(true)
      } else {
        result(false)
      }

    case "setBeautyEffectOptions":
      if let args = call.arguments as? [String: Any] {
        let options = BeautyOptions(
          enabled: args["enabled"] as? Bool ?? false,
          lighteningLevel: args["lighteningLevel"] as? Double ?? 0.5,
          rednessLevel: args["rednessLevel"] as? Double ?? 0.1,
          smoothnessLevel: args["smoothnessLevel"] as? Double ?? 0.5
        )
        engine?.setBeautyEffectOptions(options)
        result(true)
      } else {
        result(false)
      }

    case "startAudioMixing":
      if let args = call.arguments as? [String: Any],
         let filePath = args["filePath"] as? String {
        let config = AudioMixingConfiguration(
          filePath: filePath,
          loopback: args["loopback"] as? Bool ?? false,
          replace: args["replace"] as? Bool ?? false,
          cycle: args["cycle"] as? Int ?? 1,
          startPos: args["startPos"] as? Int ?? 0
        )
        engine?.startAudioMixing(config)
        result(true)
      } else {
        result(false)
      }

    case "stopAudioMixing":
      engine?.stopAudioMixing()
      result(true)

    case "pauseAudioMixing":
      engine?.pauseAudioMixing()
      result(true)

    case "resumeAudioMixing":
      engine?.resumeAudioMixing()
      result(true)

    case "adjustAudioMixingVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.adjustAudioMixingVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "getAudioMixingCurrentPosition":
      result(engine?.getAudioMixingCurrentPosition() ?? 0)

    case "setAudioMixingPosition":
      if let args = call.arguments as? [String: Any],
         let position = args["position"] as? Int {
        engine?.setAudioMixingPosition(position)
        result(true)
      } else {
        result(false)
      }

    case "playEffect":
      if let args = call.arguments as? [String: Any],
         let soundId = args["soundId"] as? Int,
         let filePath = args["filePath"] as? String {
        let config = AudioEffectConfiguration(
          filePath: filePath,
          loopCount: args["loopCount"] as? Int ?? 1,
          publish: args["publish"] as? Bool ?? false,
          startPos: args["startPos"] as? Int ?? 0
        )
        engine?.playEffect(soundId: soundId, config: config)
        result(true)
      } else {
        result(false)
      }

    case "stopEffect":
      if let args = call.arguments as? [String: Any],
         let soundId = args["soundId"] as? Int {
        engine?.stopEffect(soundId)
        result(true)
      } else {
        result(false)
      }

    case "stopAllEffects":
      engine?.stopAllEffects()
      result(true)

    case "setEffectsVolume":
      if let args = call.arguments as? [String: Any],
         let volume = args["volume"] as? Int {
        engine?.setEffectsVolume(volume)
        result(true)
      } else {
        result(false)
      }

    case "preloadEffect":
      if let args = call.arguments as? [String: Any],
         let soundId = args["soundId"] as? Int,
         let filePath = args["filePath"] as? String {
        engine?.preloadEffect(soundId, filePath: filePath)
        result(true)
      } else {
        result(false)
      }

    case "unloadEffect":
      if let args = call.arguments as? [String: Any],
         let soundId = args["soundId"] as? Int {
        engine?.unloadEffect(soundId)
        result(true)
      } else {
        result(false)
      }

    case "startAudioRecording":
      if let args = call.arguments as? [String: Any],
         let filePath = args["filePath"] as? String {
        let config = AudioRecordingConfiguration(
          filePath: filePath,
          sampleRate: args["sampleRate"] as? Int ?? 32000,
          channels: args["channels"] as? Int ?? 1,
          codecType: args["codecType"] as? String ?? "aacLc",
          quality: args["quality"] as? String ?? "medium"
        )
        result(engine?.startAudioRecording(config) ?? -1)
      } else {
        result(-1)
      }

    case "stopAudioRecording":
      engine?.stopAudioRecording()
      result(true)

    case "createDataStream":
      if let args = call.arguments as? [String: Any] {
        let reliable = args["reliable"] as? Bool ?? true
        let ordered = args["ordered"] as? Bool ?? true
        result(engine?.createDataStream(reliable: reliable, ordered: ordered) ?? 0)
      } else {
        result(0)
      }

    case "sendStreamMessage":
      if let args = call.arguments as? [String: Any],
         let streamId = args["streamId"] as? Int,
         let data = args["data"] as? FlutterStandardTypedData {
        engine?.sendStreamMessage(streamId: streamId, data: data.data)
        result(true)
      } else {
        result(false)
      }

    case "startRtmpStreamWithTranscoding":
      if !appFeatures.contains("live") {
        result(FlutterError(code: "FEATURE_NOT_ENABLED", message: "当前AppId未开通直播功能", details: nil))
        return
      }
      if let args = call.arguments as? [String: Any],
         let url = args["url"] as? String {
        let users = (args["transcodingUsers"] as? [[String: Any]])?.compactMap { u -> TranscodingUser? in
          guard let uid = u["uid"] as? String else { return nil }
          return TranscodingUser(
            uid: uid,
            x: u["x"] as? Double ?? 0,
            y: u["y"] as? Double ?? 0,
            width: u["width"] as? Double ?? 0,
            height: u["height"] as? Double ?? 0,
            zOrder: u["zOrder"] as? Int ?? 0,
            alpha: u["alpha"] as? Double ?? 1.0
          )
        }
        let transcoding = LiveTranscoding(
          width: args["width"] as? Int ?? 360,
          height: args["height"] as? Int ?? 640,
          videoBitrate: args["videoBitrate"] as? Int ?? 400,
          videoFramerate: args["videoFramerate"] as? Int ?? 15,
          lowLatency: args["lowLatency"] as? Bool ?? false,
          videoGop: args["videoGop"] as? Int ?? 30,
          backgroundColor: args["backgroundColor"] as? Int ?? 0x000000,
          watermarkUrl: args["watermarkUrl"] as? String,
          transcodingUsers: users
        )
        engine?.startRtmpStreamWithTranscoding(url: url, transcoding: transcoding)
        result(true)
      } else {
        result(false)
      }

    case "stopRtmpStream":
      if let args = call.arguments as? [String: Any],
         let url = args["url"] as? String {
        engine?.stopRtmpStream(url: url)
        result(true)
      } else {
        result(false)
      }

    case "updateRtmpTranscoding":
      if let args = call.arguments as? [String: Any] {
        let users = (args["transcodingUsers"] as? [[String: Any]])?.compactMap { u -> TranscodingUser? in
          guard let uid = u["uid"] as? String else { return nil }
          return TranscodingUser(
            uid: uid,
            x: u["x"] as? Double ?? 0,
            y: u["y"] as? Double ?? 0,
            width: u["width"] as? Double ?? 0,
            height: u["height"] as? Double ?? 0,
            zOrder: u["zOrder"] as? Int ?? 0,
            alpha: u["alpha"] as? Double ?? 1.0
          )
        }
        let transcoding = LiveTranscoding(
          width: args["width"] as? Int ?? 360,
          height: args["height"] as? Int ?? 640,
          videoBitrate: args["videoBitrate"] as? Int ?? 400,
          videoFramerate: args["videoFramerate"] as? Int ?? 15,
          lowLatency: args["lowLatency"] as? Bool ?? false,
          videoGop: args["videoGop"] as? Int ?? 30,
          backgroundColor: args["backgroundColor"] as? Int ?? 0x000000,
          watermarkUrl: args["watermarkUrl"] as? String,
          transcodingUsers: users
        )
        engine?.updateRtmpTranscoding(transcoding)
        result(true)
      } else {
        result(false)
      }

    case "takeSnapshot":
      if let args = call.arguments as? [String: Any],
         let uid = args["uid"] as? String,
         let filePath = args["filePath"] as? String {
        engine?.takeSnapshot(uid: uid, filePath: filePath)
        result(true)
      } else {
        result(false)
      }
      
    case "release":
      engine?.release()
      engine = nil
      result(true)

    case "httpRequest":
      if let args = call.arguments as? [String: Any],
         let method = args["method"] as? String,
         let urlStr = args["url"] as? String,
         let url = URL(string: urlStr) {
        let headers = args["headers"] as? [String: String] ?? [:]
        let bodyStr = args["body"] as? String
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = method
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        if let bodyStr = bodyStr { request.httpBody = bodyStr.data(using: .utf8) }
        URLSession.shared.dataTask(with: request) { data, response, error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "HTTP_ERROR", message: error.localizedDescription, details: nil))
              return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
              result(FlutterError(code: "PARSE_ERROR", message: "Invalid response", details: nil))
              return
            }
            result(json)
          }
        }.resume()
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing method or url", details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
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

  public func onChannelMessage(uid: String, message: String) {
    eventChannel?.invokeMethod("onChannelMessage", arguments: ["uid": uid, "message": message])
  }

  public func onStreamMessage(uid: String, streamId: Int, data: Data) {
    eventChannel?.invokeMethod("onStreamMessage", arguments: [
      "uid": uid,
      "streamId": streamId,
      "data": [UInt8](data)
    ])
  }

  public func onStreamMessageError(uid: String, streamId: Int, code: Int, missed: Int, cached: Int) {
    eventChannel?.invokeMethod("onStreamMessageError", arguments: [
      "uid": uid,
      "streamId": streamId,
      "code": code,
      "missed": missed,
      "cached": cached
    ])
  }
}
