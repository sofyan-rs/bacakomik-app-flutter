package org.kurodev.yoru.mihon

import android.app.Application
import eu.kanade.tachiyomi.network.BrowserCheckSolver
import okhttp3.CookieJar
import org.kurodev.yoru.mihon.host.ExtensionLoader
import org.kurodev.yoru.mihon.host.SettingsBridge
import java.io.File

/** An extension APK's manifest and signers, read without running its code. */
data class ApkInfo(
    val pkg: String,
    val name: String?,
    val versionName: String?,
    val versionCode: Long,
    val lib: String,
    val nsfw: Boolean,
    /** SHA-256 of each signing certificate, lowercase hex. */
    val signers: List<String>,
)

/**
 * What the system running [MihonHost] gives it: Android inside the app
 * (the package manager, WebView), or a desktop JVM with Android stand-ins
 * (dex2jar, the app's own browser for checks). Everything else is the same
 * code on both.
 */
class MihonPlatform(
    val app: Application,
    /** Memos, chapter lists and cookies. */
    val folder: File,
    /** OkHttp's cache. */
    val cacheDir: File,
    val loader: ExtensionLoader,
    /** Reads an APK's manifest and signers; throws HostError when it cannot. */
    val inspect: (path: String) -> ApkInfo,
    val settings: SettingsBridge,
    val cookieJar: CookieJar,
    /** Passes browser checks without the reader; null where there is nothing to do it. */
    val browserCheck: BrowserCheckSolver?,
)
