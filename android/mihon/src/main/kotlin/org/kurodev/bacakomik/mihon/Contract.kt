package org.kurodev.bacakomik.mihon

import android.content.SharedPreferences
import com.mediumdev.scancore.host.ExtensionHost
import com.mediumdev.scancore.host.HostError
import eu.kanade.tachiyomi.source.CatalogueSource
import eu.kanade.tachiyomi.source.online.HttpSource
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.floatOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs

/**
 * A Mihon source speaking the app's extension contract (the JS one in
 * bacakomik-ext `types/bridge.d.ts`): `browse`, `series`, `chapters`,
 * `chapter`, `webUrl`, `features`. [ExtensionHost] gives Mihon's models as
 * JSON (Codec); this turns them into the contract's shapes.
 *
 * - Series slugs are [Slugs] of the Mihon URL.
 * - Chapters are addressed by number (see [chapters]).
 * - Images are `mihon://` URLs the app fetches through [MihonHost.image].
 */
class Contract(
    private val host: ExtensionHost,
    /** The scanlator picked per comic (`<sourceId>|<url>`), on this device only. */
    private val scanlators: SharedPreferences,
) {
    /** Last chapter list per `<sourceId>|<url>`, newest first, one per number. */
    private val chapterLists = ConcurrentHashMap<String, List<JsonObject>>()

    /** Series titles by `<sourceId>|<url>`, to find chapter numbers ([ChapterRecognition]). */
    private val titles = ConcurrentHashMap<String, String>()

    /** Every chapter's scanlator in the last list per `<sourceId>|<url>`. */
    private val scanlatorLists = ConcurrentHashMap<String, List<String>>()

    /** Sources that made a request this run (see [features]). */
    private val browsed = ConcurrentHashMap.newKeySet<String>()

    suspend fun call(
        params: JsonObject,
        method: String,
        args: JsonArray,
    ): JsonElement =
        when (method) {
            "browse" -> browse(params, args.getOrNull(0) as? JsonObject ?: JsonObject(emptyMap()))
            "series" -> series(params, slug(args))
            "chapters" -> chapters(params, slug(args), refresh = true)
            "chapter" -> chapter(params, slug(args), args.getOrNull(1)?.jsonPrimitive?.doubleOrNull ?: throw HostError("No chapter number.", 400))
            "webUrl" -> JsonPrimitive(webUrl(params, slug(args)))
            "scanlators" -> scanlatorsOf(params, slug(args))
            "setScanlator" -> {
                val key = "${sourceId(params)}|${Slugs.decode(slug(args))}"
                val name = args.getOrNull(1)?.jsonPrimitive?.contentOrNull
                scanlators.edit().apply { if (name.isNullOrBlank()) remove(key) else putString(key, name) }.apply()
                chapterLists.remove(key)
                JsonNull
            }
            "features" -> features(params)
            else -> throw HostError("Mihon sources have no \"$method\".", 400)
        }

    private fun slug(args: JsonArray) = args.getOrNull(0)?.jsonPrimitive?.contentOrNull ?: throw HostError("No series.", 400)

    private fun sourceId(params: JsonObject) = params["source"]!!.jsonPrimitive.content

    private fun with(
        params: JsonObject,
        vararg extra: Pair<String, JsonElement>,
    ) = JsonObject(params + extra)

    // ------------------------------------------------------------------ browse

    private suspend fun browse(
        params: JsonObject,
        args: JsonObject,
    ): JsonElement {
        val page = args["page"]?.jsonPrimitive?.intOrNull ?: 1
        val query = args["query"]?.jsonPrimitive?.contentOrNull?.trim().orEmpty()
        val values = (args["filters"] as? JsonObject).orEmpty()
        val list = values["_list"]?.jsonArray?.firstOrNull()?.jsonPrimitive?.contentOrNull
        browsed += sourceId(params)
        val fresh = host.handle("filters", params).jsonArray
        val states = Filters.apply(fresh, values)
        val result =
            if (query.isEmpty() && states == fresh) {
                val latest = list == "latest" && (host.source(params) as? CatalogueSource)?.supportsLatest == true
                host.handle(if (latest) "latest" else "popular", with(params, "page" to JsonPrimitive(page)))
            } else {
                host.handle(
                    "search",
                    with(params, "page" to JsonPrimitive(page), "query" to JsonPrimitive(query), "filters" to states),
                )
            }.jsonObject
        val id = sourceId(params)
        return buildJsonObject {
            put(
                "items",
                buildJsonArray {
                    for (item in result["items"]!!.jsonArray) {
                        val m = item.jsonObject
                        val url = m["url"]?.jsonPrimitive?.contentOrNull ?: continue
                        m["title"]?.jsonPrimitive?.contentOrNull?.let { titles["$id|$url"] = it }
                        add(
                            buildJsonObject {
                                put("slug", Slugs.encode(url))
                                put("title", m["title"]?.jsonPrimitive?.contentOrNull.orEmpty())
                                put("cover", Images.cover(id, m["cover"]?.jsonPrimitive?.contentOrNull))
                                put("format", JsonNull)
                                put("status", JsonNull)
                                put("rating", JsonNull)
                                put("totalChapters", JsonNull)
                            },
                        )
                    }
                },
            )
            put("hasNext", result["hasNextPage"]?.jsonPrimitive?.booleanOrNull ?: false)
        }
    }

    /**
     * Many extensions fetch their genre list from the site with their first
     * request and offer it in getFilterList only then ("Press 'Reset' to
     * load genres" until). So a source asked for its filters first makes one
     * popular request, and a list still showing such a hint is read again a
     * moment later.
     */
    private suspend fun features(params: JsonObject): JsonElement {
        val latest = (host.source(params) as? CatalogueSource)?.supportsLatest == true
        if (browsed.add(sourceId(params))) {
            runCatching { host.handle("popular", with(params, "page" to JsonPrimitive(1))) }
        }
        var tree = host.handle("filters", params).jsonArray
        if (Filters.waitsForGenres(tree)) {
            kotlinx.coroutines.delay(GENRE_WAIT_MS)
            tree = host.handle("filters", params).jsonArray
        }
        return buildJsonObject {
            put("filters", Filters.groups(tree))
            put(
                "home",
                // Home's two sections, never the same list twice: "New series"
                // is the source's newest-first order, else its popular list
                // (titled so); without latest updates the second section is
                // popular, and a first one only if newest exists.
                buildJsonObject {
                    val newest = Filters.newest(tree)
                    when {
                        newest != null -> put("featured", newest)
                        latest -> {
                            put("featured", list("popular"))
                            put("featuredLabel", POPULAR)
                        }
                        else -> put("featured", JsonNull)
                    }
                    put("latest", list(if (latest) "latest" else "popular"))
                    if (!latest) put("latestLabel", POPULAR)
                },
            )
        }
    }

    private fun list(name: String) = buildJsonObject { put("_list", buildJsonArray { add(JsonPrimitive(name)) }) }

    // ------------------------------------------------------------------ series

    private suspend fun series(
        params: JsonObject,
        slug: String,
    ): JsonElement {
        val url = Slugs.decode(slug)
        val d = host.handle("details", with(params, "url" to JsonPrimitive(url))).jsonObject
        fun text(key: String) = d[key]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null }
        text("title")?.let { titles["${sourceId(params)}|$url"] = it }
        val description = Description.parse(d["description"]?.jsonPrimitive?.contentOrNull)
        val people =
            listOfNotNull(text("author"), text("artist"))
                .flatMap { it.split(',') }
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .distinct()
        return buildJsonObject {
            put("slug", slug)
            put("title", text("title").orEmpty())
            put("cover", Images.cover(sourceId(params), text("cover")))
            put("format", JsonNull)
            put("status", status(d["status"]?.jsonPrimitive?.intOrNull))
            put("rating", description.rating)
            put("totalChapters", JsonNull)
            put("altTitles", buildJsonArray { description.altTitles.forEach { add(JsonPrimitive(it)) } })
            put("nativeTitle", JsonNull)
            put("releaseDate", JsonNull)
            put("author", if (people.isEmpty()) null else people.joinToString(", "))
            put("synopsis", description.synopsis)
            put(
                "genres",
                buildJsonArray {
                    d["genres"]?.jsonArray?.map { it.jsonPrimitive.content.trim() }?.filter { it.isNotEmpty() }?.distinct()?.forEach {
                        add(
                            buildJsonObject {
                                put("id", it)
                                put("name", it)
                            },
                        )
                    }
                },
            )
        }
    }

    // SManga's status constants as the app's words.
    private fun status(code: Int?): String? =
        when (code) {
            1 -> "ongoing"
            2, 4 -> "completed"
            3 -> "licensed"
            5 -> "cancelled"
            6 -> "hiatus"
            else -> null
        }

    private suspend fun webUrl(
        params: JsonObject,
        slug: String,
    ): String {
        val source = host.source(params)
        val url = Slugs.decode(slug)
        return (source as? HttpSource)?.getMangaUrl(host.manga(source, url)) ?: url
    }

    // ---------------------------------------------------------------- chapters

    /**
     * The app keys chapters by number; Mihon by URL. A chapter's number is
     * the extension's `chapter_number`, else the one in its name, as Mihon
     * finds it ([ChapterRecognition]). One chapter per number, the first in
     * Mihon's order (newest first) when several scanlators have it.
     * A chapter without a number ("Extra", "Side story") gets one just above
     * the numbered chapter before it, in 0.001 steps ([ChapterRecognition.placeNumbers]); with
     * no number anywhere (a gallery's one "Chapter", nhentai) they are
     * numbered 1, 2, … from the oldest. Those keep their name as `title`
     * for the app to show. A comic with one chapter (a gallery, a oneshot)
     * is always chapter 1, without a title, whatever its name says. The
     * list is kept so [chapter] finds a number's URL.
     */
    private suspend fun chapterList(
        params: JsonObject,
        url: String,
    ): List<JsonObject> {
        // Names often repeat the title ("Kaiju No. 8 Chapter 12"): without it
        // every chapter would read as 8. Not known on a cold start (a
        // bookmark refresh), so the details are asked for alongside; asked
        // at once, both come from one getMangaUpdate (ExtensionHost).
        val key = "${sourceId(params)}|$url"
        val request = with(params, "url" to JsonPrimitive(url))
        val all =
            coroutineScope {
                val details = if (titles[key] == null) async { runCatching { host.handle("details", request) }.getOrNull() } else null
                val chapters = host.handle("chapters", request).jsonArray
                details?.await()?.jsonObject?.get("title")?.jsonPrimitive?.contentOrNull?.let { titles[key] = it }
                chapters
            }
        val title = titles[key].orEmpty()
        val chapters = all.map { it.jsonObject }
        val numbers =
            chapters.map {
                val given = number(it["number"]?.jsonPrimitive?.floatOrNull ?: -1f)
                val name = it["name"]?.jsonPrimitive?.contentOrNull.orEmpty()
                ChapterRecognition.parseChapterNumber(title, name, given)
            }
        val single = chapters.size == 1
        val placed = if (single) listOf(1.0) else ChapterRecognition.placeNumbers(numbers)
        scanlatorLists[key] = chapters.mapNotNull { it["scanlator"]?.jsonPrimitive?.contentOrNull?.trim()?.ifEmpty { null } }
        // One chapter per number: the picked scanlator's when it has that
        // number, else the first in Mihon's order.
        val picked = scanlators.getString(key, null)
        val chosen = HashMap<Double, Int>()
        for (i in chapters.indices) {
            val n = placed[i]
            val mine = picked != null && chapters[i]["scanlator"]?.jsonPrimitive?.contentOrNull?.trim() == picked
            val seen = chosen[n]
            if (seen == null || (mine && chapters[seen]["scanlator"]?.jsonPrimitive?.contentOrNull?.trim() != picked)) chosen[n] = i
        }
        val keep = chosen.values.toHashSet()
        val list =
            chapters.indices.mapNotNull { i ->
                val n = placed[i]
                if (i !in keep) return@mapNotNull null
                val name = chapters[i]["name"]?.jsonPrimitive?.contentOrNull
                val extra = if (!single && numbers[i] < 0 && !name.isNullOrBlank()) listOf("title" to JsonPrimitive(name)) else emptyList()
                JsonObject(chapters[i] + ("number" to JsonPrimitive(n)) + extra)
            }
        chapterLists["${sourceId(params)}|$url"] = list
        return list
    }

    /**
     * The comic's scanlators, most chapters first, and the one picked
     * (null: the source's order decides). Fewer than two: nothing to pick.
     */
    private suspend fun scanlatorsOf(
        params: JsonObject,
        slug: String,
    ): JsonElement {
        val url = Slugs.decode(slug)
        val key = "${sourceId(params)}|$url"
        if (scanlatorLists[key] == null) chapterList(params, url)
        val names =
            scanlatorLists[key]
                .orEmpty()
                .groupingBy { it }
                .eachCount()
                .entries
                .sortedByDescending { it.value }
                .map { it.key }
        return buildJsonObject {
            put("names", buildJsonArray { names.forEach { add(JsonPrimitive(it)) } })
            put("picked", scanlators.getString(key, null))
        }
    }

    private suspend fun chapters(
        params: JsonObject,
        slug: String,
        refresh: Boolean,
    ): JsonElement {
        val url = Slugs.decode(slug)
        val list = (if (refresh) null else chapterLists["${sourceId(params)}|$url"]) ?: chapterList(params, url)
        return buildJsonArray {
            for (c in list) {
                add(
                    buildJsonObject {
                        put("number", numberJson(c))
                        put("createdAt", iso(c["uploaded"]?.jsonPrimitive?.longOrNull ?: 0))
                        c["title"]?.let { put("title", it) }
                    },
                )
            }
        }
    }

    private suspend fun chapter(
        params: JsonObject,
        slug: String,
        number: Double,
    ): JsonElement {
        val url = Slugs.decode(slug)
        val key = "${sourceId(params)}|$url"
        fun find(list: List<JsonObject>?) = list?.indexOfFirst { abs(numberOf(it) - number) < 1e-6 }?.takeIf { it >= 0 }
        var list = chapterLists[key]
        var i = find(list)
        if (i == null) {
            list = chapterList(params, url)
            i = find(list) ?: throw HostError("404 Chapter $number not found.", 404)
        }
        val c = list!![i]
        val pages = host.handle("pages", with(params, "url" to JsonPrimitive(c["url"]!!.jsonPrimitive.content))).jsonArray
        val id = sourceId(params)
        return buildJsonObject {
            put("number", numberJson(c))
            put("title", c["name"]?.jsonPrimitive?.contentOrNull)
            // By number, not by place: some extensions list oldest first.
            val n = numberOf(c)
            put("prev", list.filter { numberOf(it) < n }.maxByOrNull(::numberOf)?.let(::numberJson) ?: JsonNull)
            put("next", list.filter { numberOf(it) > n }.minByOrNull(::numberOf)?.let(::numberJson) ?: JsonNull)
            put("images", buildJsonArray { pages.forEach { add(JsonPrimitive(Images.page(id, it.jsonObject))) } })
        }
    }

    private fun numberOf(c: JsonObject) = c["number"]?.jsonPrimitive?.doubleOrNull ?: -1.0

    // Through its decimal text, so 10.1f is 10.1, not 10.100000381.
    private fun number(n: Float) = n.toString().toDouble()

    // Whole numbers as integers, as JS sources send them ("10", not "10.0").
    private fun numberJson(c: JsonObject): JsonPrimitive {
        val n = numberOf(c)
        return if (n == Math.floor(n) && abs(n) < 1e15) JsonPrimitive(n.toLong()) else JsonPrimitive(n)
    }

    private fun iso(ms: Long): String? {
        if (ms <= 0) return null
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(java.util.Date(ms))
    }

    private fun JsonObject?.orEmpty() = this ?: JsonObject(emptyMap())

    private companion object {
        /** How long a genre list being fetched gets before filters are read again. */
        const val GENRE_WAIT_MS = 2_000L

        /** Home section title for a source's popular list. */
        const val POPULAR = "Popular"
    }
}
