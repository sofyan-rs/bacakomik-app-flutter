package org.kurodev.bacakomik

import android.content.Context
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.pichillilorenzo.flutter_inappwebview_android.InAppWebViewFlutterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MihonChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bacakomik/hidden_webviews")
            .setMethodCallHandler { call, result ->
                val view = hiddenWebView(flutterEngine, call.argument<String>("id"))
                when (call.method) {
                    "render" -> result.success(view != null && render(view))
                    "hide" -> {
                        view?.visibility = View.INVISIBLE
                        result.success(view != null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** The view of the headless WebView [id] (`HeadlessInAppWebView.id`). */
    private fun hiddenWebView(engine: FlutterEngine, id: String?): View? {
        if (id == null) return null
        val plugin = engine.plugins.get(InAppWebViewFlutterPlugin::class.java)
            as? InAppWebViewFlutterPlugin ?: return null
        return plugin.headlessInAppWebViewManager?.webViews?.get(id)?.flutterWebView?.view
    }

    /**
     * Headless WebViews sit invisible inside the Flutter view, where Chromium
     * runs no rendering steps: no requestAnimationFrame, IntersectionObserver
     * or scrolling, which lazy-loading pages need. Fully transparent but
     * visible, they render like one on screen and still cannot be seen. The
     * view is moved into an [Untouchable] frame first, so it takes no touches
     * meant for the app.
     *
     * Rendering costs frames on the UI thread for as long as the page runs
     * its animations and ads, so Dart asks for it per page and only while a
     * script or a check runs, and hides the page again with `hide`.
     */
    private fun render(view: View): Boolean {
        val parent = view.parent as? ViewGroup ?: return false
        if (parent !is Untouchable) {
            val index = parent.indexOfChild(view)
            val params = view.layoutParams
            parent.removeView(view)
            val frame = Untouchable(this)
            frame.addView(view, FrameLayout.LayoutParams(params.width, params.height))
            parent.addView(frame, index, params)
        }
        view.alpha = 0f
        view.visibility = View.VISIBLE
        return true
    }

    /** Lets touches through to the views behind it. */
    private class Untouchable(context: Context) : FrameLayout(context) {
        init {
            alpha = 0f
        }

        override fun dispatchTouchEvent(event: MotionEvent): Boolean = false

        override fun onInterceptTouchEvent(event: MotionEvent): Boolean = false

        // Gone with the WebView it held.
        override fun onViewRemoved(child: View?) {
            super.onViewRemoved(child)
            if (childCount == 0) post { (parent as? ViewGroup)?.removeView(this) }
        }
    }
}
