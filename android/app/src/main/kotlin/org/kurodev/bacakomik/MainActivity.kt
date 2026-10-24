package org.kurodev.bacakomik

import android.content.Context
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bacakomik/hidden_webviews")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "render" -> result.success(renderHiddenWebViews())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Headless WebViews sit invisible inside the Flutter view, where Chromium
     * runs no rendering steps: no requestAnimationFrame, IntersectionObserver
     * or scrolling, which lazy-loading pages need. Fully transparent but
     * visible, they render like one on screen and still cannot be seen. Each
     * is moved into a [Untouchable] frame first, so it takes no touches meant
     * for the app.
     */
    private fun renderHiddenWebViews(): Int {
        val found = mutableListOf<View>()
        fun holdsWebView(view: View): Boolean = view is WebView ||
            (view is ViewGroup && (0 until view.childCount).any { holdsWebView(view.getChildAt(it)) })
        fun visit(view: View) {
            if (view.visibility == View.INVISIBLE && holdsWebView(view)) {
                found += view
                return
            }
            if (view is ViewGroup) for (i in 0 until view.childCount) visit(view.getChildAt(i))
        }
        visit(window.decorView)
        for (view in found) {
            val parent = view.parent as? ViewGroup ?: continue
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
        }
        return found.size
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
