package com.sy.rtc.flutter

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.ConcurrentHashMap

/**
 * Flutter PlatformView container for WebRTC SurfaceViewRenderer.
 * ViewType: [VIEW_TYPE]
 */
class SyRtcVideoPlatformView(
  context: Context,
  private val viewId: Int,
) : PlatformView {
  val container: FrameLayout = FrameLayout(context).also {
    it.layoutParams = FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT,
    )
    it.setBackgroundColor(0xFF000000.toInt())
  }

  init {
    Registry.put(viewId, this)
  }

  override fun getView(): View = container

  override fun dispose() {
    Registry.remove(viewId)
    container.removeAllViews()
  }

  object Registry {
    private val views = ConcurrentHashMap<Int, SyRtcVideoPlatformView>()
    fun put(id: Int, view: SyRtcVideoPlatformView) { views[id] = view }
    fun remove(id: Int) { views.remove(id) }
    fun get(id: Int): SyRtcVideoPlatformView? = views[id]
    fun container(id: Int): FrameLayout? = views[id]?.container
  }

  companion object {
    const val VIEW_TYPE = "sy_rtc_flutter_sdk/video_view"
  }
}

class SyRtcVideoPlatformViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return SyRtcVideoPlatformView(context, viewId)
  }
}
