package org.kurodev.bacakomik.mihon

import android.app.Application
import android.content.Context
import com.mediumdev.scancore.host.ExtensionHost
import com.mediumdev.scancore.host.HostError
import com.mediumdev.scancore.host.MemoStore
import com.mediumdev.scancore.host.android.AndroidLoader
import com.mediumdev.scancore.host.android.AndroidSettings
import com.mediumdev.scancore.host.android.WebViewBrowserCheck
import com.mediumdev.scancore.host.android.WebViewCookieJar
import com.mediumdev.scancore.host.optString
import com.mediumdev.scancore.host.string
import eu.kanade.tachiyomi.AppInfo
import eu.kanade.tachiyomi.network.HostNetwork
import eu.kanade.tachiyomi.network.JavaScriptEngine
import eu.kanade.tachiyomi.network.NetworkHelper
import eu.kanade.tachiyomi.source.online.HttpSource
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.protobuf.ProtoBuf
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.addSingleton
import uy.kohesive.injekt.api.addSingletonFactory
import java.io.File

/**
 * Runs Mihon extensions inside the app. The app's Dart side calls [handle]
 * (through the `bacakomik/mihon` channel) and [image] for `mihon://` images.
 *
 * Calls (args and results are JSON):
 *
 * | method | args | result |
 * |---|---|---|
 * | `libs` | – | lib versions this host runs |
 * | `inspect` | path, signer | the APK's pkg, versions, lib, nsfw, signers, sources; refuses another signer before loading code |
 * | `install` | pkg, apk, signer | its sources; remembers the APK for later calls |
 * | `uninstall` | pkg | – (drops its sources' settings too) |
 * | `call` | source, method, args | the contract's result ([Contract]) |
 * | `preferences` / `setPreference` | source (, key, value) | the source's settings |
 * | `userAgent` | source | the User-Agent the source sends |
 */
object MihonHost {
    private lateinit var app: Application
    private lateinit var loader: AndroidLoader
    private lateinit var host: ExtensionHost
    private lateinit var contract: Contract
    private lateinit var index: SourceIndex

    @Volatile
    private var started = false

    /** Whether this phone can run Mihon extensions (Android 9+). */
    val supported get() = android.os.Build.VERSION.SDK_INT >= 28

    /** Sets up what extensions expect from Mihon. [userAgent]: the app's own, so WebView cookies stay valid. */
    @Synchronized
    fun start(
        context: Context,
        userAgent: String?,
        appVersion: String,
    ) {
        if (userAgent != null) HostNetwork.userAgent = userAgent
        if (started) return
        // Signing info (28) and DelegateLastClassLoader (27).
        if (!supported) throw HostError("Mihon extensions need Android 9 or newer.", 501)
        app = context.applicationContext as Application
        val folder = File(app.filesDir, "mihon").apply { mkdirs() }
        HostNetwork.cookieJar = WebViewCookieJar(File(folder, "cookies.json"))
        HostNetwork.browserCheckSolver = WebViewBrowserCheck(app)
        HostNetwork.cacheDir = File(app.cacheDir, "mihon")
        AppInfo.set(versionCode = 1, versionName = appVersion)
        Injekt.addSingleton<Application>(app)
        Injekt.addSingleton<Context>(app)
        Injekt.addSingletonFactory { NetworkHelper(app) }
        Injekt.addSingletonFactory { JavaScriptEngine(app) }
        Injekt.addSingletonFactory {
            Json {
                ignoreUnknownKeys = true
                explicitNulls = false
            }
        }
        Injekt.addSingletonFactory<ProtoBuf> { ProtoBuf }
        loader = AndroidLoader(app)
        host = ExtensionHost(loader, MemoStore(File(folder, "memos.json")), AndroidSettings(app))
        contract = Contract(host)
        index = SourceIndex(app)
        started = true
    }

    private fun check() {
        if (!started) throw HostError("The Mihon host is not started.", 503)
    }

    suspend fun handle(
        method: String,
        args: JsonObject,
    ): JsonElement {
        check()
        return when (method) {
            "libs" -> JsonArray(loader.libs.map(::JsonPrimitive))
            "inspect" -> inspect(args.string("path"), args.optString("signer"))
            "install" -> {
                val pkg = args.string("pkg")
                val apk = args.string("apk")
                val signer = args.string("signer").lowercase()
                host.unload(pkg)
                val sources = host.handle("load", buildJsonObject {
                    put("pkg", pkg)
                    put("apk", apk)
                    put("signer", signer)
                }).jsonArray
                index.put(pkg, apk, signer, sources.map { it.jsonObject["id"]!!.jsonPrimitive.content })
                sources
            }
            "uninstall" -> {
                val pkg = args.string("pkg")
                host.unload(pkg)
                for (id in index.remove(pkg)) app.deleteSharedPreferences("source_$id")
                JsonNull
            }
            "call" -> {
                val params = index.params(args.string("source"))
                contract.call(params, args.string("method"), args["args"] as? JsonArray ?: JsonArray(emptyList()))
            }
            "preferences" -> host.handle("preferences", index.params(args.string("source")))
            "setPreference" -> {
                val source = args.string("source")
                val params = index.params(source)
                host.handle("setPreference", JsonObject(params + ("key" to JsonPrimitive(args.string("key"))) + ("value" to (args["value"] ?: JsonNull))))
                // Extensions read their settings when built: the next call
                // builds them again.
                host.unload(params.string("pkg"))
                JsonNull
            }
            "userAgent" -> {
                val source = host.source(index.params(args.string("source")))
                JsonPrimitive((source as? HttpSource)?.headers?.get("User-Agent") ?: HostNetwork.userAgent)
            }
            else -> throw HostError("The Mihon host does not know \"$method\".", 400)
        }
    }

    private suspend fun inspect(
        path: String,
        signer: String?,
    ): JsonElement {
        val info = loader.inspect(path)
        val signers = loader.signers(info)
        if (signer != null && signer.lowercase() !in signers) {
            throw HostError("The extension is signed with a key its repo does not name.", 403)
        }
        val lib = loader.lib(info)
        val supported = lib.toDoubleOrNull() in loader.libs.map { it.toDouble() }
        val meta = info.applicationInfo?.metaData
        val pkg = info.packageName
        return buildJsonObject {
            put("pkg", pkg)
            put("name", info.applicationInfo?.loadLabel(app.packageManager)?.toString()?.removePrefix("Tachiyomi: "))
            put("versionName", info.versionName)
            put("versionCode", info.longVersionCode)
            put("lib", lib)
            put("supported", supported)
            put("nsfw", (meta?.getInt("tachiyomi.extension.nsfw") ?: 0) == 1)
            put("signers", buildJsonArray { signers.forEach { add(JsonPrimitive(it)) } })
            // Loading runs the extension's code: only once the signer is
            // the trusted one.
            if (supported && signer != null) {
                put("sources", host.handle("load", buildJsonObject {
                    put("pkg", pkg)
                    put("apk", path)
                    put("signer", signer)
                }))
                host.unload(pkg)
            }
        }
    }

    /** A `mihon://` image ([Images]): its bytes and content type. */
    suspend fun image(url: String): Pair<ByteArray, String?> {
        check()
        val ref = Images.parse(url)
        val source = host.source(index.params(ref.sourceId))
        val response =
            when (ref) {
                is Images.Cover -> host.cover(source, ref.url)
                is Images.Page -> host.image(source, ref.page)
            }
        return response.use {
            if (!it.isSuccessful) throw HostError("The site answered HTTP ${it.code} for an image.", it.code)
            it.body.bytes() to it.header("Content-Type")
        }
    }
}
