// Ported from SCANCORE's host/desktop/CefRuntime.kt
// (https://github.com/medium-gh/scancore, MIT, see LICENSE-SCANCORE).
// YORU: pinned SHA-256 per platform instead of the checksum file next to the
// download, kept in <root>/chromium/<version>, progress over LineServer, and
// the first web view waits for the download instead of failing.
package org.kurodev.yoru.mihon.desktop

import android.webkit.WebView
import android.webkit.WebViewProvider
import com.jetbrains.cef.JCefAppConfig
import eu.kanade.tachiyomi.network.HostNetwork
import eu.kanade.tachiyomi.network.MemoryCookieJar
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import okhttp3.OkHttpClient
import okhttp3.Request
import org.cef.CefApp
import org.cef.CefSettings
import org.cef.SystemBootstrap
import org.cef.network.CefCookie
import org.cef.network.CefCookieManager
import org.kurodev.yoru.mihon.host.HostError
import xyz.nulldev.androidcompat.webkit.CefHelper
import xyz.nulldev.androidcompat.webkit.KcefWebViewProvider
import xyz.nulldev.androidcompat.webkit.NoWebViewProvider
import java.io.File
import java.security.MessageDigest
import java.util.Date
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong
import kotlin.concurrent.thread

/**
 * The web view extensions open (`android.webkit.WebView`: Keiyoushi's
 * runWebView and others) on computers: Chromium through JetBrains' JCEF, as
 * Suwayomi and SCANCORE do, drawn off screen (no window).
 *
 * Its native part comes with a JetBrains Runtime release (about 250 MB),
 * downloaded the first time an extension creates a web view, never at start,
 * checked against the SHA-256 pinned below and kept in
 * `<root>/chromium/<version>` for later runs. The Java part (the jcef jar,
 * which must match that release) ships in the runtime.
 */
object CefRuntime {
    // The JetBrains Runtime release whose native JCEF matches the jcef jar
    // (gradle/libs.versions.toml: 144.0.15-g72717cf-chromium-144.0.7559.172).
    // A new jcef means a new release here, and new checksums.
    private const val JBR = "25.0.4"
    private const val BUILD = "b508.27"
    const val VERSION = "$JBR-$BUILD"

    private class Archive(
        val platform: String,
        val sha256: String,
    ) {
        val name get() = "jbr_jcef-$JBR-$platform-$BUILD.tar.gz"
        val url get() = "https://cache-redirector.jetbrains.com/intellij-jbr/$name"
    }

    // SHA-256 of each archive, taken from the files themselves after checking
    // them against JetBrains' published SHA-512 (<url>.checksum).
    private val archives =
        mapOf(
            "windows-x64" to Archive("windows-x64", "6df29fd7fdd385c25195f4ba1ff138513c3fa0912ddd496ed9e0e5e80b875782"),
            "linux-x64" to Archive("linux-x64", "ba94da3ef76bbac5951a79714be2a9e17303b5dd2a44927023468b9a2644bba9"),
            "linux-arm64" to Archive("linux-aarch64", "dc6d1d4a2cae2c4dd31e019b048e1913fd7e28c0bf9222a0e54a4d9db3cc072e"),
            "macos-x64" to Archive("osx-x64", "7bc8b5aad9b70f0e291ace8be5a20435633ba60f7012fdd3421bfd83c3f553d3"),
            "macos-arm64" to Archive("osx-aarch64", "0cb5e6729c7fc92c1cb0f7906fabe8a5072f23cebeba1e1f170016eb67b231f8"),
        )

    /** Set by Main before any extension runs. */
    lateinit var root: File

    /** Download and unpack progress, 0 to 1 (1 also when it failed). */
    @Volatile
    var onProgress: (progress: Double, error: String?) -> Unit = { _, _ -> }

    private val base get() = File(root, "chromium")
    private val dir get() = File(base, VERSION)
    private val marker get() = File(dir, "yoru-chromium.txt")

    @Volatile
    private var download: CompletableFuture<Unit>? = null

    @Volatile
    private var started: Result<Unit>? = null

    private val waits = AtomicLong()

    /**
     * Grows each time a web view had to wait for Chromium or could not get
     * it: a call that failed meanwhile is worth one more try once it is ready
     * (an extension may have given up waiting).
     */
    val waited: Long get() = waits.get()

    // What WebView(context) gets. The first one waits for the download (the
    // extension's own timeout usually starts after the web view exists);
    // without Chromium, a web view whose every call says why.
    fun providerFor(view: WebView): WebViewProvider =
        try {
            if (!installed()) waits.incrementAndGet()
            ensureReady(retry = true)
            KcefWebViewProvider(view)
        } catch (e: HostError) {
            waits.incrementAndGet()
            NoWebViewProvider.create(view, e.message)
        }

    /**
     * Downloads Chromium if it is not there yet and starts it; blocks. A
     * failure is a [HostError] that says why. A download that failed is
     * tried again only when [retry] (a new web view), not for a call that
     * just saw it fail.
     */
    fun ensureReady(retry: Boolean = false) {
        if (!installed()) {
            try {
                fetchOnce(retry).get()
            } catch (e: ExecutionException) {
                throw failure(e.cause ?: e)
            }
        }
        start().onFailure { throw failure(it) }
    }

    private fun failure(e: Throwable) = HostError("Could not get the browser this extension needs: ${e.message ?: e.javaClass.simpleName}", 503)

    private fun installed() = marker.isFile && marker.readText().trim() == VERSION

    fun platform(): String {
        val os = System.getProperty("os.name").lowercase()
        val arch =
            when (val a = System.getProperty("os.arch").lowercase()) {
                "amd64", "x86_64" -> "x64"
                "aarch64", "arm64" -> "arm64"
                else -> a
            }
        return when {
            os.startsWith("windows") -> "windows-$arch"
            os.startsWith("mac") -> "macos-$arch"
            else -> "linux-$arch"
        }
    }

    // One download at a time; a failed one is tried again by the next web
    // view, not by the calls already waiting on it.
    private fun fetchOnce(retry: Boolean): CompletableFuture<Unit> =
        synchronized(this) {
            download?.takeIf { !retry || !it.isCompletedExceptionally }?.let { return it }
            val job = CompletableFuture<Unit>()
            download = job
            thread(name = "chromium-download", isDaemon = true) {
                try {
                    fetch()
                    onProgress(1.0, null)
                    job.complete(Unit)
                } catch (e: Throwable) {
                    System.err.println("Chromium download failed: $e")
                    onProgress(1.0, e.message ?: e.toString())
                    job.completeExceptionally(e)
                }
            }
            job
        }

    private fun fetch() {
        val platform = platform()
        val archive = archives[platform] ?: error("there is no Chromium build for $platform")
        val client =
            OkHttpClient
                .Builder()
                .followRedirects(true)
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .build()
        val work = File(base, "download.part").apply { deleteRecursively(); mkdirs() }
        val file = File(work, archive.name)
        val digest = MessageDigest.getInstance("SHA-256")
        onProgress(0.0, null)
        try {
            client.newCall(Request.Builder().url(archive.url).build()).execute().use { response ->
                if (!response.isSuccessful) error("the download failed (HTTP ${response.code})")
                val total = response.body.contentLength()
                var done = 0L
                var reported = 0
                response.body.byteStream().use { input ->
                    file.outputStream().buffered().use { output ->
                        val buffer = ByteArray(1 shl 16)
                        while (true) {
                            val n = input.read(buffer)
                            if (n < 0) break
                            output.write(buffer, 0, n)
                            digest.update(buffer, 0, n)
                            done += n
                            // Downloading is the first 90%, unpacking the rest.
                            val percent = if (total > 0) (done * 90 / total).toInt() else 0
                            if (percent > reported) {
                                reported = percent
                                onProgress(percent / 100.0, null)
                            }
                        }
                    }
                }
            }
        } catch (e: java.io.IOException) {
            work.deleteRecursively()
            throw java.io.IOException("the download failed (${e.message ?: e.javaClass.simpleName}). Check your connection.", e)
        }
        val actual = digest.digest().joinToString("") { "%02x".format(it) }
        if (actual != archive.sha256) {
            work.deleteRecursively()
            error("the download does not match its checksum")
        }
        System.err.println("Chromium $VERSION downloaded (${file.length()} bytes, SHA-256 $actual verified)")
        install(file, work)
    }

    // The JetBrains Runtime archive unpacked into place: what
    // JCefAppConfig.getInstance(dir) reads (Linux: the runtime's lib folder;
    // Windows: lib and bin; macOS: lib and Frameworks), without the Java
    // class library this host does not use.
    private fun install(
        archive: File,
        work: File,
    ) {
        val unpacked = File(work, "unpacked").apply { mkdirs() }
        // tar comes with Windows 10 and later (System32's, not another on the
        // PATH that reads C: as a host name), macOS and Linux.
        val tar =
            System.getenv("SystemRoot")?.let { File(it, "System32/tar.exe") }?.takeIf { it.isFile }?.path ?: "tar"
        val process = ProcessBuilder(tar, "-xzf", archive.absolutePath, "-C", unpacked.absolutePath).redirectErrorStream(true).start()
        val log = process.inputStream.bufferedReader().readText()
        check(process.waitFor() == 0) { "unpacking failed: ${log.take(300)}" }
        archive.delete()
        onProgress(0.95, null)
        val top = unpacked.listFiles()!!.single { it.isDirectory }
        val target = File(base, "$VERSION.part").apply { deleteRecursively(); mkdirs() }
        val unused = setOf("modules", "ct.sym", "src.zip", "jvm.lib")
        fun moveAll(from: File) =
            from.listFiles()!!.filter { it.name !in unused }.forEach { check(it.renameTo(File(target, it.name))) { "could not move ${it.name}" } }
        when {
            platform().startsWith("macos") -> {
                val contents = File(top, "Contents")
                moveAll(File(contents, "Home/lib"))
                check(File(contents, "Frameworks").renameTo(File(target, "Frameworks"))) { "could not move Frameworks" }
            }
            platform().startsWith("windows") -> {
                moveAll(File(top, "lib"))
                moveAll(File(top, "bin"))
            }
            else -> moveAll(File(top, "lib"))
        }
        File(target, "yoru-chromium.txt").writeText("$VERSION\n")
        dir.deleteRecursively()
        check(target.renameTo(dir)) { "could not move Chromium into place" }
        work.deleteRecursively()
        // Older versions, no longer used.
        base.listFiles()?.filter { it.isDirectory && it.name != VERSION && it.name != "cache" }?.forEach { it.deleteRecursively() }
    }

    // Once per process (CefApp cannot start twice); a few seconds.
    @Synchronized
    private fun start(): Result<Unit> =
        started ?: runCatching { initialize() }
            .onFailure {
                System.err.println("Chromium failed to start: $it")
                it.printStackTrace()
            }.also { started = it }

    private fun initialize() {
        System.loadLibrary("jawt")
        val app =
            CefApp.getInstanceIfAny() ?: run {
                val config =
                    JCefAppConfig.getInstance(dir.absolutePath, false).apply {
                        // getInstance(path) points macOS at Frameworks/jcef
                        // Helper.app, but JetBrains Runtime keeps the helper
                        // inside cef_server.app (as its getInstance() does):
                        // CEF would stop the process at start.
                        if (System.getProperty("os.name").lowercase().startsWith("mac")) {
                            val helper = File(dir, "Frameworks/cef_server.app/Contents/Frameworks/jcef Helper.app")
                            appArgsAsList.replaceAll {
                                when {
                                    it.startsWith("--main-bundle-path=") -> "--main-bundle-path=${helper.path}"
                                    it.startsWith("--browser-subprocess-path=") ->
                                        "--browser-subprocess-path=${File(helper, "Contents/MacOS/jcef Helper").path}"
                                    else -> it
                                }
                            }
                        }
                        appArgsAsList.addAll(
                            listOf(
                                "--disable-gpu",
                                // Drawn into memory, never into a window.
                                "--off-screen-rendering-enabled",
                                "--disable-dev-shm-usage",
                                "--change-stack-guard-on-fork=disable",
                                "--mute-audio",
                            ),
                        )
                        cefSettings.apply {
                            windowless_rendering_enabled = true
                            cache_path = File(base, "cache").absolutePath
                            log_severity = CefSettings.LogSeverity.LOGSEVERITY_WARNING
                        }
                    }
                // As CefApp does inside, but here, so a failure is an
                // exception rather than a browser that never comes.
                val os = System.getProperty("os.name").lowercase()
                when {
                    os.startsWith("windows") -> {
                        config.getLoader().loadLibrary("chrome_elf")
                        config.getLoader().loadLibrary("libcef")
                    }
                    os.startsWith("mac") -> {}
                    else -> config.getLoader().loadLibrary("cef")
                }
                config.getLoader().loadLibrary("jcef")
                CefApp.setIsRemoteEnabled(config.isRemoteEnabled)
                SystemBootstrap.setLoader(config.getLoader())
                CefApp.startup(config.appArgs)
                CefApp.getInstance(config.appArgs, config.cefSettings, config.serverExe)
            }
        CefHelper.cefApp.value = Result.success(app)
        runBlocking { withTimeout(60_000) { CefHelper.waitForInit().first() } }
        System.err.println("Chromium $VERSION started (off screen)")
        // The host's cookies (browser checks passed in the app, sign-ins) in
        // each new web view, as Suwayomi does.
        KcefWebViewProvider.initHandler =
            object : KcefWebViewProvider.InitBrowserHandler {
                override fun init(provider: KcefWebViewProvider) {
                    val manager = CefCookieManager.getGlobalManager() ?: return
                    for (cookie in (HostNetwork.cookieJar as? MemoryCookieJar)?.all().orEmpty()) {
                        val expires = if (cookie.persistent) Date(cookie.expiresAt) else null
                        manager.setCookie(
                            (if (cookie.secure) "https://" else "http://") + cookie.domain,
                            CefCookie(
                                cookie.name, cookie.value, cookie.domain, cookie.path, cookie.secure, cookie.httpOnly,
                                Date(), Date(), expires != null, expires,
                            ),
                        )
                    }
                }
            }
        Runtime.getRuntime().addShutdownHook(Thread { runCatching { CefApp.getInstanceIfAny()?.dispose() } })
    }
}
