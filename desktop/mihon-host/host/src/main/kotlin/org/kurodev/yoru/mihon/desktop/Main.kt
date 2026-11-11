// Yoru's Mihon extension host for Windows, macOS and Linux: started by the
// app on first use, it runs Mihon extensions with the same code as Android
// (MihonHost) and answers over stdin/stdout (LineServer).
//
//   yoru-mihon-host --root <folder> [--user-agent <ua>] [--app-version <v>]
//
// Adapted from SCANCORE's desktop/Main.kt (MIT).
package org.kurodev.yoru.mihon.desktop

import android.app.Application
import android.os.Looper
import eu.kanade.tachiyomi.network.HostNetwork
import eu.kanade.tachiyomi.network.PersistentCookieJar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runInterruptible
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import org.kurodev.yoru.mihon.MihonHost
import org.kurodev.yoru.mihon.MihonPlatform
import org.kurodev.yoru.mihon.host.HostError
import xyz.nulldev.androidcompat.AndroidCompat
import xyz.nulldev.androidcompat.AndroidCompatInitializer
import java.io.File
import java.io.OutputStreamWriter
import java.io.PrintStream
import java.util.Base64
import java.util.concurrent.CountDownLatch
import kotlin.system.exitProcess

/** The protocol's version; the app refuses a host that speaks another. */
const val HOST_VERSION = "2"

fun main(args: Array<String>) {
    val options = args.toList().zipWithNext().filter { it.first.startsWith("--") }.associate { it.first.removePrefix("--") to it.second }
    val root = File(options["root"] ?: run { System.err.println("--root is required"); exitProcess(2) })
    root.mkdirs()

    // The protocol owns stdout; anything an extension (or native code:
    // Chromium) prints goes to stderr.
    val protocol = OutputStreamWriter(StdoutGuard.protocolStream(), Charsets.UTF_8)
    System.setOut(PrintStream(System.err, true, "UTF-8"))
    val server = LineServer(protocol)

    try {
        setUp(root, server, options["user-agent"], options["app-version"] ?: "")
    } catch (e: Throwable) {
        e.printStackTrace()
        server.send(buildJsonObject { put("ready", false); put("error", e.message ?: e.javaClass.simpleName) })
        exitProcess(1)
    }
    server.send(
        buildJsonObject {
            put("ready", true)
            put("version", HOST_VERSION)
            put("libs", buildJsonArray { MihonHost.libs.forEach { add(JsonPrimitive(it)) } })
        },
    )
    server.serve(
        System.`in`.bufferedReader(Charsets.UTF_8),
        handle = { method, params ->
            withChromium {
                when (method) {
                    "handle" ->
                        MihonHost.handle(
                            params["method"]?.jsonPrimitive?.content ?: throw HostError("No method.", 400),
                            params["args"] as? JsonObject ?: JsonObject(emptyMap()),
                        )
                    "image" -> {
                        val url = params["url"]?.jsonPrimitive?.content ?: throw HostError("No image.", 400)
                        val (bytes, type) = MihonHost.image(url)
                        buildJsonObject {
                            put("bytes", Base64.getEncoder().encodeToString(bytes))
                            put("type", type)
                        }
                    }
                    else -> throw HostError("The Mihon host does not know \"$method\".", 400)
                }
            }
        },
        stop = { it == "shutdown" },
    )
    // Shut down, or the app went away (stdin closed).
    MihonHost.saveMemos()
    exitProcess(0)
}

// Everything an extension expects of the app: Android stand-ins, the network
// with the app's identity and cookies, then MihonHost as on Android.
private fun setUp(
    root: File,
    server: LineServer,
    userAgent: String?,
    appVersion: String,
) {
    // AndroidCompat keeps the emulated app's files (SharedPreferences: the
    // source index, slugs, scanlators, extension settings) here.
    System.setProperty("yoru.mihon.root", root.absolutePath)
    userAgent?.let { HostNetwork.userAgent = it }
    startMainThread()
    AndroidCompatInitializer().init(HostNetwork.userAgent)
    // Web views run in Chromium, downloaded when an extension first opens
    // one (CefRuntime); progress goes to the app as events.
    CefRuntime.root = root
    CefRuntime.onProgress = { progress, error ->
        server.send(
            buildJsonObject {
                put("event", "progress")
                put("what", "chromium")
                put("progress", progress)
                error?.let { put("error", it) }
            },
        )
    }
    android.webkit.WebView.setProviderFactory { view -> CefRuntime.providerFor(view) }
    val app = Application()
    AndroidCompat().startApp(app)
    val loader = ApkLoader(File(root, "jars"))
    MihonHost.start(
        MihonPlatform(
            app = app,
            folder = root,
            cacheDir = File(root, "cache"),
            loader = loader,
            inspect = loader::inspect,
            settings = CompatSettings(app),
            cookieJar = PersistentCookieJar(File(root, "cookies.json")),
            browserCheck = AppBrowserCheck(server),
        ),
        appVersion,
    )
    Runtime.getRuntime().addShutdownHook(Thread { MihonHost.saveMemos() })
}

// A call during which a web view waited for Chromium (or could not get it)
// and that failed meanwhile, perhaps because the extension stopped waiting:
// once Chromium is there, tried once more; without it, a failure that says
// why.
private suspend fun withChromium(call: suspend () -> JsonElement): JsonElement {
    val before = CefRuntime.waited
    val first = runCatching { call() }
    if (first.isSuccess || CefRuntime.waited == before) return first.getOrThrow()
    runInterruptible(Dispatchers.IO) { CefRuntime.ensureReady() }
    return call()
}

// Android's main thread: extensions make Handlers on Looper.getMainLooper()
// and post toasts or web-view work to it. Calls still run on the protocol's
// workers, so myLooper() stays null there, as on a background thread on
// Android.
private fun startMainThread() {
    if (Looper.getMainLooper() != null) return
    val ready = CountDownLatch(1)
    Thread({
        Looper.prepareMainLooper()
        ready.countDown()
        Looper.loop()
    }, "main").apply {
        isDaemon = true
        start()
    }
    ready.await()
}
