// MihonHost on Android: the platform it runs on inside the app. Left out of
// the desktop host's build (desktop/mihon-host), which starts MihonHost with
// a platform of its own.
package org.kurodev.yoru.mihon

import android.app.Application
import android.content.Context
import eu.kanade.tachiyomi.network.HostNetwork
import org.kurodev.yoru.mihon.host.HostError
import org.kurodev.yoru.mihon.host.android.AndroidLoader
import org.kurodev.yoru.mihon.host.android.AndroidSettings
import org.kurodev.yoru.mihon.host.android.WebViewBrowserCheck
import org.kurodev.yoru.mihon.host.android.WebViewCookieJar
import java.io.File

private const val PREFS = "bacakomik_mihon"

/** Whether this phone can run Mihon extensions (Android 9+). */
val MihonHost.supported get() = android.os.Build.VERSION.SDK_INT >= 28

/** Sets up what extensions expect from Mihon. [userAgent]: the app's own, so WebView cookies stay valid. */
fun MihonHost.start(
    context: Context,
    userAgent: String?,
    appVersion: String,
) {
    synchronized(this) { startAndroid(context, userAgent, appVersion) }
}

private fun MihonHost.startAndroid(
    context: Context,
    userAgent: String?,
    appVersion: String,
) {
    if (userAgent != null) HostNetwork.userAgent = userAgent
    // Kept for a start without Dart (background downloads, MihonProxy).
    context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .edit()
        .apply { if (userAgent != null) putString("userAgent", userAgent) }
        .putString("appVersion", appVersion)
        .apply()
    if (isStarted) return
    // Signing info (28) and DelegateLastClassLoader (27).
    if (!supported) throw HostError("Mihon extensions need Android 9 or newer.", 501)
    val app = context.applicationContext as Application
    val folder = File(app.filesDir, "mihon").apply { mkdirs() }
    val loader = AndroidLoader(app)
    start(
        MihonPlatform(
            app = app,
            folder = folder,
            cacheDir = File(app.cacheDir, "mihon"),
            loader = loader,
            inspect = { path -> androidInspect(app, loader, path) },
            settings = AndroidSettings(app),
            cookieJar = WebViewCookieJar(File(folder, "cookies.json")),
            browserCheck = WebViewBrowserCheck(app),
        ),
        appVersion,
    )
}

/** Starts with what the last [start] from Dart was given, when Dart isn't running. */
fun MihonHost.ensureStarted(context: Context) {
    if (isStarted) return
    val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    start(context, prefs.getString("userAgent", null), prefs.getString("appVersion", null) ?: "")
}

/** [ApkInfo] from Android's package manager. */
private fun androidInspect(
    app: Application,
    loader: AndroidLoader,
    path: String,
): ApkInfo {
    val info = loader.inspect(path)
    return ApkInfo(
        pkg = info.packageName,
        name = info.applicationInfo?.loadLabel(app.packageManager)?.toString(),
        versionName = info.versionName,
        versionCode = info.longVersionCode,
        lib = loader.lib(info),
        nsfw = (info.applicationInfo?.metaData?.getInt("tachiyomi.extension.nsfw") ?: 0) == 1,
        signers = loader.signers(info),
    )
}
