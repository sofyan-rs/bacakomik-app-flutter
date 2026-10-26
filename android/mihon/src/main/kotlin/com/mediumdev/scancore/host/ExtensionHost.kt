// From SCANCORE's ExtensionHost.kt (MIT). BACAKOMIK: Aniyomi (anime) left
// out, the line protocol's own calls (hello, setUserAgent, setCookies,
// networkUse) dropped, and the source and its images opened to the app's
// adapter (source(), image(), cover()).
package com.mediumdev.scancore.host

import android.content.SharedPreferences
import androidx.preference.PreferenceScreen
import eu.kanade.tachiyomi.network.GET
import eu.kanade.tachiyomi.network.NetworkHelper
import eu.kanade.tachiyomi.network.awaitSuccess
import eu.kanade.tachiyomi.source.CatalogueSource
import eu.kanade.tachiyomi.source.ConfigurableSource
import eu.kanade.tachiyomi.source.Source
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import eu.kanade.tachiyomi.source.model.SMangaUpdate
import eu.kanade.tachiyomi.source.online.HttpSource
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Response
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.coroutineContext

// What one extension holds.
class LoadedExtension(
    val sources: List<Source> = emptyList(),
)

// Loads extensions on first use (the package manager) and reports what they
// contain.
interface ExtensionLoader {
    // The extension's sources. `signer` is the SHA-256 of the certificate
    // the app trusted; the loader refuses a file signed otherwise.
    fun load(
        pkg: String,
        path: String,
        signer: String?,
    ): LoadedExtension

    // Lib versions this host runs (e.g. "1.4", "1.5", "1.6").
    val libs: List<String>
}

// Answers the app's calls for Mihon extensions. Every call names its
// extension (pkg, apk, signer) so the host can load it on demand, and its
// source by id.
class ExtensionHost(
    private val loader: ExtensionLoader,
    private val memos: MemoStore,
    private val settings: SettingsBridge,
    // BACAKOMIK: each series' last chapter list, handed back to
    // getMangaUpdate so sources that read only new chapters ("fetch until
    // known") can; null keeps none.
    private val chapterDir: java.io.File? = null,
) {
    // By package: each source id's Source.
    private val loaded = ConcurrentHashMap<String, Map<Long, Source>>()
    private val locks = ConcurrentHashMap<String, Mutex>()

    val libs get() = loader.libs

    suspend fun handle(
        method: String,
        params: JsonObject,
    ): JsonElement =
        when (method) {
            "load" -> describe(sources(params))
            "unload" -> {
                unload(params.string("pkg"))
                JsonNull
            }
            else -> {
                // Everything the call does over the network counts for its
                // extension, whichever thread it runs on.
                val pkg = params.optString("pkg") ?: packages[params.optString("source")?.toLongOrNull()]
                if (pkg == null) call(method, params) else withContext(eu.kanade.tachiyomi.network.NetworkUse.For(pkg)) { call(method, params) }
            }
        }

    fun unload(pkg: String) {
        loaded.remove(pkg)
        loadedFrom.remove(pkg)
    }

    // Which extension each source came in.
    private val packages = ConcurrentHashMap<Long, String>()

    // BACAKOMIK: the APK each package was loaded from. A call naming another
    // file (an update being inspected or installed) loads that one instead
    // of getting the old version's sources.
    private val loadedFrom = ConcurrentHashMap<String, String>()

    private suspend fun sources(params: JsonObject): Map<Long, Source> {
        val pkg = params.string("pkg")
        val apk = params.string("apk")
        fun current() = loaded[pkg]?.takeIf { loadedFrom[pkg] == apk }
        current()?.let { return it }
        val lock = locks.getOrPut(pkg) { Mutex() }
        return lock.withLock {
            current() ?: eu.kanade.tachiyomi.network.NetworkUse
                .during(pkg) { loader.load(pkg, apk, params.optString("signer")) }
                .sources
                .associateBy { s -> s.id }
                .also {
                    loaded[pkg] = it
                    loadedFrom[pkg] = apk
                    for (id in it.keys) packages[id] = pkg
                }
        }
    }

    private fun describe(sources: Map<Long, Source>) =
        buildJsonArray {
            for (source in sources.values) {
                add(
                    buildJsonObject {
                        put("id", source.id.toString())
                        put("name", source.name)
                        put("lang", source.lang)
                        put("baseUrl", (source as? HttpSource)?.baseUrl)
                        put("supportsLatest", (source as? CatalogueSource)?.supportsLatest ?: false)
                        put("configurable", source is ConfigurableSource)
                    },
                )
            }
        }

    // The source a call names (params: pkg, apk, signer, source).
    suspend fun source(params: JsonObject): Source {
        val id = params.string("source").toLongOrNull() ?: throw HostError("That is not a source id.", 400)
        return sources(params)[id] ?: throw HostError("The extension has no source $id. It may need updating.", 404)
    }

    private fun base(source: Source) = (source as? HttpSource)?.baseUrl

    // Calls that start with the site itself, rather than images.
    private val browsing = setOf("popular", "latest", "search", "details", "chapters", "pages")

    // Sites whose home page went through the Cloudflare check this session.
    private val warmed = ConcurrentHashMap.newKeySet<String>()

    // Some extensions (Comix) open the site in a web view of their own, where
    // a Cloudflare check is never seen by CloudflareInterceptor: they wait
    // minutes and fail. So the first call to a site in a session loads its
    // home page through the default client first, which passes a check
    // there (hidden, else with the reader's tap) and leaves the clearance
    // in the cookies those web views share. One request per site per
    // session; any other failure is the extension's own business.
    private suspend fun warmUp(source: Source) {
        if (source !is HttpSource) return
        val url = source.baseUrl.toHttpUrlOrNull() ?: return
        if (url.host in warmed) return
        kotlinx.coroutines.runInterruptible(Dispatchers.IO) {
            try {
                val request = okhttp3.Request.Builder().url(url).headers(source.headers).build()
                Injekt.get<NetworkHelper>().client.newCall(request).execute().close()
                warmed += url.host
            } catch (e: eu.kanade.tachiyomi.network.BrowserCheckException) {
                throw e
            } catch (_: Exception) {
                warmed += url.host
            }
        }
    }

    private fun catalogue(source: Source) = source as? CatalogueSource ?: throw HostError("${source.name} cannot be browsed.", 501)

    // A series' details and chapters come from one getMangaUpdate, and
    // Keiyoushi's sources refuse a second one for the same series while one
    // runs ("must not be called concurrently for same manga"): the series
    // page asks for details and chapters at once, so every such source
    // failed there. Calls for a series that arrive within a moment of each
    // other are made into one asking for all they want (as Mihon does);
    // later ones wait their turn. The fetch runs on its own, so one caller
    // giving up does not leave the others without an answer.
    private class MangaUpdateJob(
        var details: Boolean,
        var chapters: Boolean,
    ) {
        val result = CompletableDeferred<SMangaUpdate>()
        var started = false
    }

    private val updateJobs = HashMap<String, MangaUpdateJob>()
    private val updateLocks = ConcurrentHashMap<String, Mutex>()
    private val updateScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // BACAKOMIK: details and chapters are separate jobs, details first, so a
    // source that reads its chapter list slowly (page by page in a web view)
    // shows the series at once. Asks of the same kind still share one call.
    private suspend fun mangaUpdate(
        source: Source,
        url: String,
        details: Boolean,
        chapters: Boolean,
    ): SMangaUpdate {
        val key = "${source.id}|$url"
        val jobKey = "$key|${if (details) "d" else ""}${if (chapters) "c" else ""}"
        val (job, first) =
            synchronized(updateJobs) {
                val waiting = updateJobs[jobKey]?.takeIf { !it.started }
                waiting?.let { it to false } ?: (MangaUpdateJob(details, chapters).also { updateJobs[jobKey] = it } to true)
            }
        if (first) {
            updateScope.launch(coroutineContext[eu.kanade.tachiyomi.network.NetworkUse.For] ?: kotlin.coroutines.EmptyCoroutineContext) {
                delay(UPDATE_GATHER_MS)
                // A chapter walk lets waiting details go first.
                if (!details) {
                    while (synchronized(updateJobs) { updateJobs["$key|d"]?.started == false }) delay(UPDATE_GATHER_MS)
                }
                updateLocks.getOrPut(key) { Mutex() }.withLock {
                    synchronized(updateJobs) {
                        job.started = true
                        if (updateJobs[jobKey] === job) updateJobs.remove(jobKey)
                    }
                    try {
                        val known = if (job.chapters) knownChapters(source, url) else emptyList()
                        val update = source.getMangaUpdate(manga(source, url), known, job.details, job.chapters)
                        if (job.chapters) saveChapters(source, url, update.chapters)
                        job.result.complete(update)
                    } catch (e: Throwable) {
                        job.result.completeExceptionally(e)
                    }
                }
            }
        }
        return job.result.await()
    }

    private fun chapterFile(
        source: Source,
        url: String,
    ): java.io.File? {
        val dir = chapterDir ?: return null
        val hash = java.security.MessageDigest.getInstance("SHA-1").digest("${source.id}|$url".toByteArray()).joinToString("") { "%02x".format(it) }
        return java.io.File(dir, "$hash.json")
    }

    // The last list, newest first, with each chapter's memo, as the source
    // gave it.
    private fun knownChapters(
        source: Source,
        url: String,
    ): List<SChapter> =
        runCatching {
            val file = chapterFile(source, url)?.takeIf { it.isFile } ?: return emptyList()
            kotlinx.serialization.json.Json.parseToJsonElement(file.readText()).let { it as JsonArray }.map { element ->
                val o = element.jsonObject
                SChapter.create().also { c ->
                    c.url = o["url"]!!.jsonPrimitive.content
                    c.name = o["name"]?.jsonPrimitive?.content.orEmpty()
                    c.chapter_number = o["number"]?.jsonPrimitive?.content?.toFloatOrNull() ?: -1f
                    c.date_upload = o["uploaded"]?.jsonPrimitive?.content?.toLongOrNull() ?: 0L
                    c.scanlator = o["scanlator"]?.jsonPrimitive?.content
                    memos.chapter(source.id, c.url)?.let { c.memo = it }
                }
            }
        }.getOrDefault(emptyList())

    private fun saveChapters(
        source: Source,
        url: String,
        chapters: List<SChapter>,
    ) {
        runCatching {
            for (c in chapters) if (c.memo.isNotEmpty()) memos.putChapter(source.id, c.url, c.memo)
            val file = chapterFile(source, url) ?: return
            file.parentFile?.mkdirs()
            val temp = java.io.File(file.path + ".tmp")
            temp.writeText(Codec.chapters(chapters).toString())
            temp.renameTo(file)
        }
    }

    fun manga(
        source: Source,
        url: String,
    ): SManga =
        SManga.create().also {
            it.url = url
            memos.manga(source.id, url)?.let { memo -> it.memo = memo }
        }

    private fun chapter(
        source: Source,
        url: String,
    ): SChapter =
        SChapter.create().also {
            it.url = url
            memos.chapter(source.id, url)?.let { memo -> it.memo = memo }
        }

    private suspend fun call(
        method: String,
        params: JsonObject,
    ): JsonElement {
        val source = source(params)
        if (method in browsing) warmUp(source)
        val page = params.int("page", 1)
        return when (method) {
            "popular" -> Codec.mangas(catalogue(source).getPopularManga(page).also { remember(source, it.mangas) }, base(source))
            "latest" -> Codec.mangas(catalogue(source).getLatestUpdates(page).also { remember(source, it.mangas) }, base(source))
            "search" -> {
                val filters = Codec.applyFilters(source.getFilterList(), params["filters"] as? JsonArray ?: JsonArray(emptyList()))
                Codec.mangas(
                    catalogue(source).getSearchManga(page, params.optString("query").orEmpty(), filters).also { remember(source, it.mangas) },
                    base(source),
                )
            }
            "details" -> {
                val update = mangaUpdate(source, params.string("url"), details = true, chapters = false)
                remember(source, listOf(update.manga))
                Codec.details(update.manga, base(source))
            }
            "chapters" -> {
                val update = mangaUpdate(source, params.string("url"), details = false, chapters = true)
                Codec.chapters(update.chapters)
            }
            "pages" -> Codec.pages(source.getPageList(chapter(source, params.string("url"))))
            "filters" -> Codec.filters(source.getFilterList())
            "preferences" -> (source as? ConfigurableSource)?.let { settings.describe(Configurable.of(it)) } ?: JsonArray(emptyList())
            "setPreference" -> {
                settings.set(configurable(source), params.string("key"), params["value"] ?: JsonNull)
                JsonNull
            }
            else -> throw HostError("The host does not know \"$method\".", 400)
        }
    }

    // A page image through the source's own client (its rate limits, headers
    // and any interceptor that unscrambles pages). The caller closes it.
    suspend fun image(
        source: Source,
        page: JsonObject,
    ): Response {
        val http = source as? HttpSource ?: throw HostError("${source.name} has no images.", 501)
        val p: Page = Codec.page(page)
        if (p.imageUrl.isNullOrEmpty()) p.imageUrl = http.getImageUrl(p)
        return http.getImage(p)
    }

    // A cover with the source's headers and client, as Mihon fetches them.
    suspend fun cover(
        source: Source,
        url: String,
    ): Response {
        val http = source as? HttpSource ?: throw HostError("${source.name} has no images.", 501)
        return http.client.newCall(GET(url, http.headers)).awaitSuccess()
    }

    private fun configurable(source: Source) =
        (source as? ConfigurableSource)?.let(Configurable::of) ?: throw HostError("${source.name} has no settings.", 501)

    private fun remember(
        source: Source,
        mangas: List<SManga>,
    ) {
        for (m in mangas) if (m.memo.isNotEmpty()) memos.putManga(source.id, m.url, m.memo)
    }
}

// How long a series' first details or chapters call waits for the other.
private const val UPDATE_GATHER_MS = 150L

// A source's settings screen: Mihon's ConfigurableSource keeps its values in
// the SharedPreferences named by `preferenceKey` ("source_<id>").
class Configurable(
    val name: String,
    val preferenceKey: String,
    val preferences: () -> SharedPreferences,
    val setup: (PreferenceScreen) -> Unit,
) {
    companion object {
        fun of(source: ConfigurableSource) =
            Configurable(source.name, "source_${source.id}", { source.getSourcePreferences() }, source::setupPreferenceScreen)
    }
}

// A source's settings screen as JSON, and changes to it, with androidx's
// preference classes.
//   [{key, title, summary, enabled, type: switch|list|multiselect|text|info,
//     entries, values, value}]
interface SettingsBridge {
    fun describe(source: Configurable): JsonArray

    fun set(
        source: Configurable,
        key: String,
        value: JsonElement,
    )
}
