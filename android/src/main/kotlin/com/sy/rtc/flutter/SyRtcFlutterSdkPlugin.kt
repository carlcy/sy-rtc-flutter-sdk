package com.sy.rtc.flutter

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

/** SyRtcFlutterSdkPlugin */
class SyRtcFlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private var engine: RtcEngine? = null
  private var eventChannel: MethodChannel? = null
  private var appFeatures: Set<String> = mutableSetOf("voice") // 默认只有语聊功能
  private var apiBaseUrl: String? = null
  private var flutterContext: android.content.Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sy_rtc_flutter_sdk")
    channel.setMethodCallHandler(this)
    
    eventChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "sy_rtc_flutter_sdk/events")
    flutterContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "init" -> {
        val appId = call.argument<String>("appId")
        val apiUrl = call.argument<String>("apiBaseUrl")
        if (appId != null) {
          engine = RtcEngine.create()
          // 使用保存的 Application Context
          val context = flutterContext
          if (context != null) {
            engine?.init(appId, context)
            apiBaseUrl = apiUrl
          // 如果提供了API URL，查询功能权限
          if (apiUrl != null && apiUrl.isNotEmpty()) {
            checkFeatures(appId, apiUrl)
          } else {
            // 默认只有语聊功能
            appFeatures = mutableSetOf("voice")
          }
          result.success(true)
        } else {
          result.error("INVALID_ARGUMENT", "appId is required", null)
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
      "release" -> {
        engine?.release()
        engine = null
        result.success(true)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun createEventHandler(): RtcEventHandler {
    return object : RtcEventHandler {
      override fun onUserJoined(uid: String, elapsed: Int) {
        eventChannel?.invokeMethod("onUserJoined", mapOf("uid" to uid, "elapsed" to elapsed))
      }

      override fun onUserOffline(uid: String, reason: String) {
        eventChannel?.invokeMethod("onUserOffline", mapOf("uid" to uid, "reason" to reason))
      }

      override fun onVolumeIndication(speakers: List<VolumeInfo>) {
        val speakersList = speakers.map { mapOf("uid" to it.uid, "volume" to it.volume) }
        eventChannel?.invokeMethod("onVolumeIndication", mapOf("speakers" to speakersList))
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

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    engine?.release()
    engine = null
  }
}
