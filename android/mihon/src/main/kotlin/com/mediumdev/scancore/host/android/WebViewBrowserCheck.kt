package com.mediumdev.scancore.host.android

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import eu.kanade.tachiyomi.network.BrowserCheckSolver
import eu.kanade.tachiyomi.network.PersistentCookieJar
import okhttp3.Cookie
import okhttp3.Headers
import okhttp3.HttpUrl
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

// Passes a Cloudflare check in a web view nobody sees, as Mihon does: the
// page loads with the extension's user agent and headers, and once the site
// sets a new cf_clearance the request goes again (CloudflareInterceptor).
// A challenge that wants a tap ("interactiveBegin") or a failed one stops at
// once, and the reader gets the browser check button instead.
class WebViewBrowserCheck(
    context: Context,
) : BrowserCheckSolver {
    private val context = context.applicationContext
    private val main = Handler(Looper.getMainLooper())

    // Cloudflare's challenge page posts its progress to the window.
    private val listener =
        """
        addEventListener("message", ({data}) => {
            if (data && data.source === "cloudflare-challenge") scancore.postMessage(String(data.event));
        })
        """.trimIndent()

    @SuppressLint("SetJavaScriptEnabled")
    override fun solve(
        url: HttpUrl,
        userAgent: String,
        headers: Headers,
    ): Boolean {
        if (Looper.myLooper() == Looper.getMainLooper()) return false
        val target = url.toString()
        val cookies = CookieManager.getInstance()
        val previous = clearance(target)
        val latch = CountDownLatch(1)
        var web: WebView? = null
        var passed = false
        var gone = false
        var challenged = false
        main.post {
            try {
                // Its own clearance would only be refused again.
                cookies.setCookie(target, "cf_clearance=; Max-Age=0")
                web =
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        settings.userAgentString = userAgent
                        cookies.setAcceptCookie(true)
                        cookies.setAcceptThirdPartyCookies(this, true)
                        addJavascriptInterface(
                            object {
                                @Suppress("unused")
                                @JavascriptInterface
                                fun postMessage(event: String) {
                                    if (event == "interactiveBegin" || event == "fail") latch.countDown()
                                }
                            },
                            "scancore",
                        )
                        webViewClient =
                            object : WebViewClient() {
                                override fun onPageFinished(
                                    view: WebView,
                                    finished: String,
                                ) {
                                    val now = clearance(target)
                                    if (!now.isNullOrBlank() && now != previous) {
                                        passed = true
                                        latch.countDown()
                                    } else if (!challenged) {
                                        // The page came without a check: nothing to pass here.
                                        latch.countDown()
                                    } else {
                                        view.evaluateJavascript(listener, null)
                                    }
                                }

                                override fun onReceivedHttpError(
                                    view: WebView,
                                    request: WebResourceRequest,
                                    response: WebResourceResponse,
                                ) {
                                    if (!request.isForMainFrame) return
                                    if (response.responseHeaders?.get("cf-mitigated") == "challenge" || response.statusCode in setOf(403, 503, 429)) {
                                        challenged = true
                                    } else {
                                        latch.countDown()
                                    }
                                }

                                override fun onRenderProcessGone(
                                    view: WebView,
                                    detail: RenderProcessGoneDetail,
                                ): Boolean {
                                    // Not handling it kills the app; failing the check is enough.
                                    gone = true
                                    latch.countDown()
                                    return true
                                }
                            }
                        loadUrl(target, headers.toMap())
                    }
                // The clearance arrives well before the site behind the
                // check finishes loading (every cover on its home page):
                // look for it four times a second rather than waiting for
                // the page.
                val poll =
                    object : Runnable {
                        override fun run() {
                            if (latch.count == 0L) return
                            val now = clearance(target)
                            if (!now.isNullOrBlank() && now != previous) {
                                passed = true
                                latch.countDown()
                            } else {
                                main.postDelayed(this, 250)
                            }
                        }
                    }
                main.postDelayed(poll, 250)
            } catch (_: Throwable) {
                // No web view on this device (being updated, or disabled).
                latch.countDown()
            }
        }
        latch.await(30, TimeUnit.SECONDS)
        main.post {
            web?.run {
                if (!gone) {
                    removeJavascriptInterface("scancore")
                    stopLoading()
                }
                destroy()
            }
            cookies.flush()
        }
        return passed || clearance(target).let { !it.isNullOrBlank() && it != previous }
    }

    private fun clearance(url: String): String? =
        CookieManager
            .getInstance()
            .getCookie(url)
            ?.split(';')
            ?.map { it.trim() }
            ?.firstOrNull { it.startsWith("cf_clearance=") }
            ?.substringAfter('=')

    // The headers the extension sent, but not the ones the web view sets itself.
    private fun Headers.toMap(): Map<String, String> =
        names()
            .filter { it.lowercase() !in skipped }
            .associateWith { get(it).orEmpty() }

    private val skipped = setOf("cookie", "host", "content-length", "accept-encoding", "connection", "user-agent")
}

// Extensions and Android's web views see the same cookies, as in Mihon: what
// the reader passes in the browser check (or the hidden check sets) reaches
// every extension at once, whatever site it was for. The host's own file
// keeps what extensions set, as before.
class WebViewCookieJar(
    file: File,
) : PersistentCookieJar(file) {
    private val manager by lazy { CookieManager.getInstance() }

    override fun add(list: List<Cookie>) {
        super.add(list)
        runCatching {
            for (cookie in list) manager.setCookie(cookie.url(), cookie.toString())
        }
    }

    override fun loadForRequest(url: HttpUrl): List<Cookie> {
        val own = super.loadForRequest(url)
        val web =
            runCatching {
                manager.getCookie(url.toString()).orEmpty().split(';').mapNotNull { Cookie.parse(url, it.trim()) }
            }.getOrDefault(emptyList())
        if (web.isEmpty()) return own
        // The web view's value wins: it is the newer clearance.
        val names = web.map { it.name }.toSet()
        return own.filter { it.name !in names } + web
    }

    private fun Cookie.url() = "${if (secure) "https" else "http"}://${domain.removePrefix(".")}$path"
}
