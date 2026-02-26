package com.sy.rtc.flutter

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.sy.rtc.sdk.RtcEngine
import com.sy.rtc.sdk.RtcEventHandler
import com.sy.rtc.sdk.RtcClientRole
import com.sy.rtc.sdk.VolumeInfo
import com.sy.rtc.sdk.AudioDeviceInfo
import com.sy.rtc.sdk.AudioMixingConfiguration
import com.sy.rtc.sdk.AudioEffectConfiguration
import com.sy.rtc.sdk.AudioRecordingConfiguration
import com.sy.rtc.sdk.BeautyOptions
import com.sy.rtc.sdk.LiveTranscoding
import com.sy.rtc.sdk.ScreenCaptureConfiguration
import com.sy.rtc.sdk.TranscodingUser

/** SyRtcFlutterSdkPlugin */
class SyRtcFlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private var engine: RtcEngine? = null
  private var eventChannel: MethodChannel? = null
  private var appFeatures: Set<String> = mutableSetOf("voice")
  private var apiBaseUrl: String? = null
  private var flutterContext: android.content.Context? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  private fun invokeOnMain(method: String, arguments: Any?) {
    mainHandler.post {
      try {
        eventChannel?.invokeMethod(method, arguments)
      } catch (t: Throwable) {
        android.util.Log.e("SyRtcFlutterSdk", "invokeOnMain failed: $method", t)
      }
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sy_rtc_flutter_sdk")
    channel.setMethodCallHandler(this)
    
    eventChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "sy_rtc_flutter_sdk/events")
    flutterContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
    when (call.method) {
      "init" -> {
        val appId = call.argument<String>("appId")
        val apiUrl = call.argument<String>("apiBaseUrl")
        val signalingUrl = call.argument<String>("signalingUrl")
        if (appId == null) {
          result.error("INVALID_ARGUMENT", "appId is required", null)
          return
        }

        try {
          engine = RtcEngine.create()
          val context = flutterContext
          if (context == null) {
            result.error("INIT_ERROR", "context is required", null)
            return
          }

          engine?.init(appId, context)
          if (signalingUrl != null && signalingUrl.isNotEmpty()) {
            engine?.setSignalingServerUrl(signalingUrl)
          }
          apiBaseUrl = apiUrl
          if (apiUrl != null && apiUrl.isNotEmpty()) {
            engine?.setApiBaseUrl(apiUrl)
          }

          if (apiUrl != null && apiUrl.isNotEmpty()) {
            checkFeatures(appId, apiUrl)
          } else {
            appFeatures = mutableSetOf("voice")
          }
          result.success(true)
        } catch (t: Throwable) {
          android.util.Log.e("SyRtcFlutterSdk", "init failed", t)
          result.error("INIT_ERROR", "SDK init failed: ${t.message}", t.stackTraceToString())
        }
      }
      "checkFeatures" -> {
        val appId = call.argument<String>("appId")
        val apiUrl = call.argument<String>("apiBaseUrl")
        if (appId != null && apiUrl != null) {
          checkFeatures(appId, apiUrl)
          result.success(true)
        } else {
          result.error("INVALID_ARGUMENT", "appId and apiBaseUrl are required", null)
        }
      }
      "hasFeature" -> {
        val feature = call.argument<String>("feature")
        if (feature != null) {
          result.success(appFeatures.contains(feature))
        } else {
          result.error("INVALID_ARGUMENT", "feature is required", null)
        }
      }
      "setApiAuthToken" -> {
        val token = call.argument<String>("token") ?: ""
        engine?.setApiAuthToken(token)
        result.success(true)
      }
      "join" -> {
        val channelId = call.argument<String>("channelId")
        val uid = call.argument<String>("uid")
        val token = call.argument<String>("token")
        if (channelId != null && uid != null && token != null) {
          engine?.setEventHandler(createEventHandler())
          engine?.join(channelId, uid, token)
          result.success(true)
        } else {
          result.error("INVALID_ARGUMENT", "channelId, uid, token are required", null)
        }
      }
      "leave" -> {
        engine?.leave()
        result.success(true)
      }
      "enableLocalAudio" -> {
        val enabled = call.argument<Boolean>("enabled") ?: false
        engine?.enableLocalAudio(enabled)
        result.success(true)
      }
      "muteLocalAudio" -> {
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteLocalAudio(muted)
        result.success(true)
      }
      "sendChannelMessage" -> {
        val message = call.argument<String>("message") ?: ""
        engine?.sendChannelMessage(message)
        result.success(true)
      }
      "setClientRole" -> {
        val roleStr = call.argument<String>("role") ?: "audience"
        val role = if (roleStr == "host") RtcClientRole.HOST else RtcClientRole.AUDIENCE
        engine?.setClientRole(role)
        result.success(true)
      }
      "setVideoEncoderConfiguration" -> {
        val args = call.arguments as? Map<*, *>
        if (args != null) {
          val width = args["width"] as? Int ?: 640
          val height = args["height"] as? Int ?: 480
          val frameRate = args["frameRate"] as? Int ?: 15
          val bitrate = args["bitrate"] as? Int ?: 400
          // 需要先检查是否有live权限
          if (!appFeatures.contains("live")) {
            result.error("FEATURE_NOT_ENABLED", "当前AppId未开通直播功能", null)
          } else {
            engine?.setVideoEncoderConfiguration(width, height, frameRate, bitrate)
            result.success(true)
          }
        } else {
          result.error("INVALID_ARGUMENT", "Invalid video encoder configuration", null)
        }
      }
      "setAudioQuality" -> {
        val args = call.arguments as? Map<*, *>
        val qualityStr = args?.get("quality") as? String ?: "high"
        // 音频质量设置（低/中/高/超高）
        engine?.setAudioQuality(qualityStr)
        result.success(true)
      }
      "enableVideo" -> {
        if (!appFeatures.contains("live")) {
          result.error("FEATURE_NOT_ENABLED", "当前AppId未开通直播功能", null)
        } else {
          engine?.enableVideo()
          result.success(true)
        }
      }
      "disableVideo" -> {
        engine?.disableVideo()
        result.success(true)
      }
      "enableAudio" -> {
        engine?.enableAudio()
        result.success(true)
      }
      "disableAudio" -> {
        engine?.disableAudio()
        result.success(true)
      }
      "setAudioProfile" -> {
        val args = call.arguments as? Map<*, *>
        val profile = args?.get("profile") as? String ?: "default"
        val scenario = args?.get("scenario") as? String ?: "default"
        engine?.setAudioProfile(profile, scenario)
        result.success(true)
      }
      "setEnableSpeakerphone" -> {
        val enabled = call.argument<Boolean>("enabled") ?: false
        engine?.setEnableSpeakerphone(enabled)
        result.success(true)
      }
      "setDefaultAudioRouteToSpeakerphone" -> {
        val enabled = call.argument<Boolean>("enabled") ?: false
        engine?.setDefaultAudioRouteToSpeakerphone(enabled)
        result.success(true)
      }
      "isSpeakerphoneEnabled" -> {
        result.success(engine?.isSpeakerphoneEnabled() ?: false)
      }
      "enumerateRecordingDevices" -> {
        val devices = engine?.enumerateRecordingDevices() ?: emptyList()
        result.success(devices.map { mapOf("deviceId" to it.deviceId, "deviceName" to it.deviceName) })
      }
      "enumeratePlaybackDevices" -> {
        val devices = engine?.enumeratePlaybackDevices() ?: emptyList()
        result.success(devices.map { mapOf("deviceId" to it.deviceId, "deviceName" to it.deviceName) })
      }
      "setRecordingDevice" -> {
        val deviceId = call.argument<String>("deviceId") ?: ""
        result.success(engine?.setRecordingDevice(deviceId) ?: -1)
      }
      "setPlaybackDevice" -> {
        val deviceId = call.argument<String>("deviceId") ?: ""
        result.success(engine?.setPlaybackDevice(deviceId) ?: -1)
      }
      "getRecordingDeviceVolume" -> {
        result.success(engine?.getRecordingDeviceVolume() ?: 0)
      }
      "setRecordingDeviceVolume" -> {
        val volume = call.argument<Int>("volume") ?: 0
        engine?.setRecordingDeviceVolume(volume)
        result.success(true)
      }
      "getPlaybackDeviceVolume" -> {
        result.success(engine?.getPlaybackDeviceVolume() ?: 0)
      }
      "setPlaybackDeviceVolume" -> {
        val volume = call.argument<Int>("volume") ?: 0
        engine?.setPlaybackDeviceVolume(volume)
        result.success(true)
      }
      "muteRemoteAudioStream" -> {
        val uid = call.argument<String>("uid") ?: ""
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteRemoteAudioStream(uid, muted)
        result.success(true)
      }
      "muteAllRemoteAudioStreams" -> {
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteAllRemoteAudioStreams(muted)
        result.success(true)
      }
      "adjustUserPlaybackSignalVolume" -> {
        val uid = call.argument<String>("uid") ?: ""
        val volume = call.argument<Int>("volume") ?: 100
        engine?.adjustUserPlaybackSignalVolume(uid, volume)
        result.success(true)
      }
      "adjustPlaybackSignalVolume" -> {
        val volume = call.argument<Int>("volume") ?: 100
        engine?.adjustPlaybackSignalVolume(volume)
        result.success(true)
      }
      "renewToken" -> {
        val token = call.argument<String>("token") ?: ""
        engine?.renewToken(token)
        result.success(true)
      }
      "getConnectionState" -> {
        result.success(engine?.getConnectionState() ?: "disconnected")
      }
      "getNetworkType" -> {
        result.success(engine?.getNetworkType() ?: "unknown")
      }
      "adjustRecordingSignalVolume" -> {
        val volume = call.argument<Int>("volume") ?: 100
        engine?.adjustRecordingSignalVolume(volume)
        result.success(true)
      }
      "muteRecordingSignal" -> {
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteRecordingSignal(muted)
        result.success(true)
      }
      "enableLocalVideo" -> {
        val enabled = call.argument<Boolean>("enabled") ?: true
        engine?.enableLocalVideo(enabled)
        result.success(true)
      }
      "startPreview" -> {
        engine?.startPreview()
        result.success(true)
      }
      "stopPreview" -> {
        engine?.stopPreview()
        result.success(true)
      }
      "muteLocalVideoStream" -> {
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteLocalVideoStream(muted)
        result.success(true)
      }
      "muteRemoteVideoStream" -> {
        val uid = call.argument<String>("uid") ?: ""
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteRemoteVideoStream(uid, muted)
        result.success(true)
      }
      "muteAllRemoteVideoStreams" -> {
        val muted = call.argument<Boolean>("muted") ?: false
        engine?.muteAllRemoteVideoStreams(muted)
        result.success(true)
      }
      "setupLocalVideo" -> {
        // Android 侧 SDK setupLocalVideo 接受 Any，这里仅透传 viewId（上层若需要可扩展为 SurfaceView/TextureView）
        val viewId = call.argument<Int>("viewId") ?: 0
        engine?.setupLocalVideo(viewId)
        result.success(true)
      }
      "setupRemoteVideo" -> {
        val uid = call.argument<String>("uid") ?: ""
        val viewId = call.argument<Int>("viewId") ?: 0
        engine?.setupRemoteVideo(uid, viewId)
        result.success(true)
      }
      "startScreenCapture" -> {
        val args = call.arguments as? Map<*, *>
        val config = ScreenCaptureConfiguration(
          width = args?.get("width") as? Int ?: 0,
          height = args?.get("height") as? Int ?: 0,
          frameRate = args?.get("frameRate") as? Int ?: 15,
          bitrate = args?.get("bitrate") as? Int ?: 0,
          captureMouseCursor = args?.get("captureMouseCursor") as? Boolean ?: true
        )
        engine?.startScreenCapture(config)
        result.success(true)
      }
      "stopScreenCapture" -> {
        engine?.stopScreenCapture()
        result.success(true)
      }
      "updateScreenCaptureConfiguration" -> {
        val args = call.arguments as? Map<*, *>
        val config = ScreenCaptureConfiguration(
          width = args?.get("width") as? Int ?: 0,
          height = args?.get("height") as? Int ?: 0,
          frameRate = args?.get("frameRate") as? Int ?: 15,
          bitrate = args?.get("bitrate") as? Int ?: 0,
          captureMouseCursor = args?.get("captureMouseCursor") as? Boolean ?: true
        )
        engine?.updateScreenCaptureConfiguration(config)
        result.success(true)
      }
      "setBeautyEffectOptions" -> {
        val args = call.arguments as? Map<*, *>
        val options = BeautyOptions(
          enabled = args?.get("enabled") as? Boolean ?: false,
          lighteningLevel = (args?.get("lighteningLevel") as? Number)?.toDouble() ?: 0.5,
          smoothnessLevel = (args?.get("smoothnessLevel") as? Number)?.toDouble() ?: 0.5,
          rednessLevel = (args?.get("rednessLevel") as? Number)?.toDouble() ?: 0.1
        )
        engine?.setBeautyEffectOptions(options)
        result.success(true)
      }
      "startAudioMixing" -> {
        val args = call.arguments as? Map<*, *>
        val config = AudioMixingConfiguration(
          filePath = args?.get("filePath") as? String ?: "",
          loopback = args?.get("loopback") as? Boolean ?: false,
          cycle = args?.get("cycle") as? Int ?: 1,
          startPos = args?.get("startPos") as? Int ?: 0
        )
        engine?.startAudioMixing(config)
        result.success(true)
      }
      "stopAudioMixing" -> {
        engine?.stopAudioMixing()
        result.success(true)
      }
      "pauseAudioMixing" -> {
        engine?.pauseAudioMixing()
        result.success(true)
      }
      "resumeAudioMixing" -> {
        engine?.resumeAudioMixing()
        result.success(true)
      }
      "adjustAudioMixingVolume" -> {
        val volume = call.argument<Int>("volume") ?: 100
        engine?.adjustAudioMixingVolume(volume)
        result.success(true)
      }
      "getAudioMixingCurrentPosition" -> {
        result.success(engine?.getAudioMixingCurrentPosition() ?: 0)
      }
      "setAudioMixingPosition" -> {
        val position = call.argument<Int>("position") ?: 0
        engine?.setAudioMixingPosition(position)
        result.success(true)
      }
      "playEffect" -> {
        val args = call.arguments as? Map<*, *>
        val soundId = args?.get("soundId") as? Int ?: 0
        val config = AudioEffectConfiguration(
          filePath = args?.get("filePath") as? String ?: "",
          loopCount = args?.get("loopCount") as? Int ?: 1,
          publish = args?.get("publish") as? Boolean ?: false,
          startPos = args?.get("startPos") as? Int ?: 0
        )
        engine?.playEffect(soundId, config)
        result.success(true)
      }
      "stopEffect" -> {
        val soundId = call.argument<Int>("soundId") ?: 0
        engine?.stopEffect(soundId)
        result.success(true)
      }
      "stopAllEffects" -> {
        engine?.stopAllEffects()
        result.success(true)
      }
      "setEffectsVolume" -> {
        val volume = call.argument<Int>("volume") ?: 100
        engine?.setEffectsVolume(volume)
        result.success(true)
      }
      "preloadEffect" -> {
        val args = call.arguments as? Map<*, *>
        val soundId = args?.get("soundId") as? Int ?: 0
        val filePath = args?.get("filePath") as? String ?: ""
        engine?.preloadEffect(soundId, filePath)
        result.success(true)
      }
      "unloadEffect" -> {
        val soundId = call.argument<Int>("soundId") ?: 0
        engine?.unloadEffect(soundId)
        result.success(true)
      }
      "startAudioRecording" -> {
        val args = call.arguments as? Map<*, *>
        val config = AudioRecordingConfiguration(
          filePath = args?.get("filePath") as? String ?: "",
          sampleRate = args?.get("sampleRate") as? Int ?: 32000,
          channels = args?.get("channels") as? Int ?: 1,
          codecType = args?.get("codecType") as? String ?: "aacLc",
          quality = args?.get("quality") as? String ?: "medium"
        )
        result.success(engine?.startAudioRecording(config) ?: -1)
      }
      "stopAudioRecording" -> {
        engine?.stopAudioRecording()
        result.success(true)
      }
      "createDataStream" -> {
        val reliable = call.argument<Boolean>("reliable") ?: true
        val ordered = call.argument<Boolean>("ordered") ?: true
        result.success(engine?.createDataStream(reliable, ordered) ?: 0)
      }
      "sendStreamMessage" -> {
        val streamId = call.argument<Int>("streamId") ?: 0
        val data = call.argument<ByteArray>("data") ?: ByteArray(0)
        engine?.sendStreamMessage(streamId, data)
        result.success(true)
      }
      "startRtmpStreamWithTranscoding" -> {
        val args = call.arguments as? Map<*, *>
        val url = args?.get("url") as? String ?: ""
        val users = (args?.get("transcodingUsers") as? List<*>)?.mapNotNull { u ->
          val m = u as? Map<*, *> ?: return@mapNotNull null
          TranscodingUser(
            uid = m["uid"] as? String ?: return@mapNotNull null,
            x = (m["x"] as? Number)?.toDouble() ?: 0.0,
            y = (m["y"] as? Number)?.toDouble() ?: 0.0,
            width = (m["width"] as? Number)?.toDouble() ?: 0.0,
            height = (m["height"] as? Number)?.toDouble() ?: 0.0,
            zOrder = m["zOrder"] as? Int ?: 0,
            alpha = (m["alpha"] as? Number)?.toDouble() ?: 1.0
          )
        }
        val transcoding = LiveTranscoding(
          width = args?.get("width") as? Int ?: 360,
          height = args?.get("height") as? Int ?: 640,
          videoBitrate = args?.get("videoBitrate") as? Int ?: 400,
          videoFramerate = args?.get("videoFramerate") as? Int ?: 15,
          lowLatency = args?.get("lowLatency") as? Boolean ?: false,
          videoGop = args?.get("videoGop") as? Int ?: 30,
          backgroundColor = args?.get("backgroundColor") as? Int ?: 0x000000,
          watermarkUrl = args?.get("watermarkUrl") as? String,
          transcodingUsers = users
        )
        engine?.startRtmpStreamWithTranscoding(url, transcoding)
        result.success(true)
      }
      "stopRtmpStream" -> {
        val url = call.argument<String>("url") ?: ""
        engine?.stopRtmpStream(url)
        result.success(true)
      }
      "updateRtmpTranscoding" -> {
        val args = call.arguments as? Map<*, *>
        val users = (args?.get("transcodingUsers") as? List<*>)?.mapNotNull { u ->
          val m = u as? Map<*, *> ?: return@mapNotNull null
          TranscodingUser(
            uid = m["uid"] as? String ?: return@mapNotNull null,
            x = (m["x"] as? Number)?.toDouble() ?: 0.0,
            y = (m["y"] as? Number)?.toDouble() ?: 0.0,
            width = (m["width"] as? Number)?.toDouble() ?: 0.0,
            height = (m["height"] as? Number)?.toDouble() ?: 0.0,
            zOrder = m["zOrder"] as? Int ?: 0,
            alpha = (m["alpha"] as? Number)?.toDouble() ?: 1.0
          )
        }
        val transcoding = LiveTranscoding(
          width = args?.get("width") as? Int ?: 360,
          height = args?.get("height") as? Int ?: 640,
          videoBitrate = args?.get("videoBitrate") as? Int ?: 400,
          videoFramerate = args?.get("videoFramerate") as? Int ?: 15,
          lowLatency = args?.get("lowLatency") as? Boolean ?: false,
          videoGop = args?.get("videoGop") as? Int ?: 30,
          backgroundColor = args?.get("backgroundColor") as? Int ?: 0x000000,
          watermarkUrl = args?.get("watermarkUrl") as? String,
          transcodingUsers = users
        )
        engine?.updateRtmpTranscoding(transcoding)
        result.success(true)
      }
      "takeSnapshot" -> {
        val args = call.arguments as? Map<*, *>
        val uid = args?.get("uid") as? String ?: ""
        val filePath = args?.get("filePath") as? String ?: ""
        engine?.takeSnapshot(uid, filePath)
        result.success(true)
      }
      "release" -> {
        engine?.release()
        engine = null
        result.success(true)
      }
      "httpRequest" -> {
        val method = call.argument<String>("method") ?: "GET"
        val url = call.argument<String>("url") ?: ""
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        val body = call.argument<String>("body")
        Thread {
          try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.requestMethod = method
            conn.connectTimeout = 10000
            conn.readTimeout = 10000
            for ((k, v) in headers) conn.setRequestProperty(k, v)
            if (body != null && (method == "POST" || method == "PUT")) {
              conn.doOutput = true
              conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            }
            val responseCode = conn.responseCode
            val stream = if (responseCode in 200..299) conn.inputStream else conn.errorStream
            val responseBody = stream?.bufferedReader()?.use { it.readText() } ?: ""
            conn.disconnect()
            val json = org.json.JSONObject(responseBody)
            val map = jsonToMap(json)
            android.os.Handler(android.os.Looper.getMainLooper()).post { result.success(map) }
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("HTTP_ERROR", e.message, null)
            }
          }
        }.start()
      }
      else -> {
        result.notImplemented()
      }
    }
    } catch (t: Throwable) {
      android.util.Log.e("SyRtcFlutterSdk", "onMethodCall error: ${call.method}", t)
      try { result.error("NATIVE_ERROR", "${call.method} failed: ${t.message}", t.stackTraceToString()) } catch (_: Throwable) {}
    }
  }

  private fun createEventHandler(): RtcEventHandler {
    return object : RtcEventHandler() {
      override fun onJoinChannelSuccess(channelId: String, uid: String, elapsed: Int) {
        invokeOnMain("onJoinChannelSuccess", mapOf("channelId" to channelId, "uid" to uid, "elapsed" to elapsed))
      }

      override fun onLeaveChannel(stats: Map<String, Any?>) {
        invokeOnMain("onLeaveChannel", mapOf("stats" to stats))
      }

      override fun onConnectionStateChanged(state: String, reason: String) {
        invokeOnMain("onConnectionStateChanged", mapOf("state" to state, "reason" to reason))
      }

      override fun onUserJoined(uid: String, elapsed: Int) {
        invokeOnMain("onUserJoined", mapOf("uid" to uid, "elapsed" to elapsed))
      }

      override fun onUserOffline(uid: String, reason: String) {
        invokeOnMain("onUserOffline", mapOf("uid" to uid, "reason" to reason))
      }

      override fun onVolumeIndication(speakers: List<VolumeInfo>) {
        val speakersList = speakers.map { mapOf("uid" to it.uid, "volume" to it.volume) }
        invokeOnMain("onVolumeIndication", mapOf("speakers" to speakersList))
      }

      override fun onError(code: Int, message: String) {
        invokeOnMain("onError", mapOf("errCode" to code, "errMsg" to message))
      }

      override fun onChannelMessage(uid: String, message: String) {
        invokeOnMain("onChannelMessage", mapOf("uid" to uid, "message" to message))
      }

      override fun onStreamMessage(uid: String, streamId: Int, data: ByteArray) {
        invokeOnMain("onStreamMessage", mapOf(
          "uid" to uid,
          "streamId" to streamId,
          "data" to data.toList()
        ))
      }

      override fun onStreamMessageError(uid: String, streamId: Int, code: Int, missed: Int, cached: Int) {
        invokeOnMain("onStreamMessageError", mapOf(
          "uid" to uid,
          "streamId" to streamId,
          "code" to code,
          "missed" to missed,
          "cached" to cached
        ))
      }
    }
  }

  private fun checkFeatures(appId: String, apiBaseUrl: String) {
    // 在后台线程中查询功能权限
    Thread {
      try {
        val url = "$apiBaseUrl/api/rtc/feature/$appId"
        val connection = java.net.URL(url).openConnection() as java.net.HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 5000
        connection.readTimeout = 5000
        
        val responseCode = connection.responseCode
        if (responseCode == 200) {
          val inputStream = connection.inputStream
          val response = inputStream.bufferedReader().use { it.readText() }
          inputStream.close()
          
          // 解析JSON响应
          val jsonObject = org.json.JSONObject(response)
          if (jsonObject.getInt("code") == 0) {
            val data = jsonObject.getJSONObject("data")
            val featuresArray = data.getJSONArray("features")
            val features = mutableSetOf<String>()
            for (i in 0 until featuresArray.length()) {
              features.add(featuresArray.getString(i))
            }
            appFeatures = features
          }
        }
        connection.disconnect()
      } catch (e: Exception) {
        // 查询失败，使用默认值（只有语聊功能）
        appFeatures = mutableSetOf("voice")
        android.util.Log.e("SyRtcFlutterSdk", "功能权限查询失败: ${e.message}")
      }
    }.start()
  }

  private fun jsonToMap(json: org.json.JSONObject): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = json.keys()
    while (keys.hasNext()) {
      val key = keys.next()
      val value = json.opt(key)
      map[key] = when (value) {
        is org.json.JSONObject -> jsonToMap(value)
        is org.json.JSONArray -> jsonArrayToList(value)
        org.json.JSONObject.NULL -> null
        else -> value
      }
    }
    return map
  }

  private fun jsonArrayToList(arr: org.json.JSONArray): List<Any?> {
    val list = mutableListOf<Any?>()
    for (i in 0 until arr.length()) {
      val value = arr.opt(i)
      list.add(when (value) {
        is org.json.JSONObject -> jsonToMap(value)
        is org.json.JSONArray -> jsonArrayToList(value)
        org.json.JSONObject.NULL -> null
        else -> value
      })
    }
    return list
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    engine?.release()
    engine = null
  }
}
