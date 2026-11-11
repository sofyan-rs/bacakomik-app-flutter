package org.kurodev.yoru.mihon

import android.app.Application
import android.content.Context
import org.kurodev.yoru.mihon.host.ExtensionHost
import org.kurodev.yoru.mihon.host.HostError
import org.kurodev.yoru.mihon.host.MemoStore
import org.kurodev.yoru.mihon.host.optString
import org.kurodev.yoru.mihon.host.string
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
import okhttp3.Cookie
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import java.io.File

/**
 * Runs Mihon extensions inside the app. The app's Dart side calls [handle]
 * (through the `yoru/mihon` channel) and [image] for `mihon://` images.
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
 * | `setCookies` | url, cookies (name=value) | – (cookies a WebView got, for the url's host) |
 * | `userAgent` | source | the User-Agent the source sends |
 */
object MihonHost {
    private lateinit var app: Application
    private lateinit var platform: MihonPlatform
    private lateinit var memos: MemoStore
    private lateinit var host: ExtensionHost
    private lateinit var contract: Contract
    private lateinit var index: SourceIndex

    @Volatile
    private var started = false

    /** Whether [start] ran: Android's start checks it before building its platform. */
    internal val isStarted get() = started

    /**
     * Sets up what extensions expect from Mihon on [platform]: Android's from
     * `MihonHost.start(context, …)` (MihonHostAndroid.kt), a desktop JVM's from
     * its helper process. Once per
     * process; the User-Agent is set by the caller ([HostNetwork.userAgent]).
     */
    @Synchronized
    fun start(
        platform: MihonPlatform,
        appVersion: String,
    ) {
        if (started) return
        this.platform = platform
        app = platform.app
        val folder = platform.folder.apply { mkdirs() }
        HostNetwork.cookieJar = platform.cookieJar
        HostNetwork.browserCheckSolver = platform.browserCheck
        HostNetwork.cacheDir = platform.cacheDir
        HostDns.restore(app)
        HostNetwork.dns = HostDns
        Slugs.init(app)
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
        memos = MemoStore(File(folder, "memos.json"))
        host = ExtensionHost(platform.loader, memos, platform.settings, File(folder, "chapters"))
        contract = Contract(host, app.getSharedPreferences("bacakomik_mihon_scanlators", Context.MODE_PRIVATE))
        index = SourceIndex(app)
        started = true
    }

    /** Extension lib versions this host runs. */
    val libs: List<String> get() = platform.loader.libs

    /** Writes what extensions memoised now (a desktop host about to exit). */
    fun saveMemos() {
        if (started) memos.save()
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
            "libs" -> JsonArray(platform.loader.libs.map(::JsonPrimitive))
            // Paths of comics an import adds whose slugs are hashed (Slugs).
            "remember" -> {
                (args["urls"] as? JsonArray).orEmpty().forEach { Slugs.remember(it.jsonPrimitive.content) }
                JsonNull
            }
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
                for (id in index.remove(pkg)) {
                    // AndroidCompat (desktop) throws for settings never
                    // opened; Android returns false. Either way none are left.
                    runCatching { app.deleteSharedPreferences("source_$id") }
                }
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
            // Cookies the app's WebView got for a site (a check the reader
            // passed there): plain name=value pairs, kept for the url's host.
            // On Android the WebView and the extensions already share them.
            "setCookies" -> {
                val url = args.string("url").toHttpUrlOrNull() ?: throw HostError("Not a web address.", 400)
                val cookies = (args["cookies"] as? JsonArray).orEmpty().mapNotNull { Cookie.parse(url, it.jsonPrimitive.content) }
                if (cookies.isNotEmpty()) HostNetwork.cookieJar.saveFromResponse(url, cookies)
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
        val info = platform.inspect(path)
        val signers = info.signers
        if (signer != null && signer.lowercase() !in signers) {
            throw HostError("The extension is signed with a key its repo does not name.", 403)
        }
        val lib = info.lib
        val supported = lib.toDoubleOrNull() in platform.loader.libs.map { it.toDouble() }
        val pkg = info.pkg
        return buildJsonObject {
            put("pkg", pkg)
            put("name", info.name?.removePrefix("Tachiyomi: "))
            put("versionName", info.versionName)
            put("versionCode", info.versionCode)
            put("lib", lib)
            put("supported", supported)
            put("nsfw", info.nsfw)
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
