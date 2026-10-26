package com.mediumdev.scancore.host

import eu.kanade.tachiyomi.source.model.Filter
import eu.kanade.tachiyomi.source.model.FilterList
import eu.kanade.tachiyomi.source.model.MangasPage
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

// Mihon's models as the JSON SCANCORE reads (see ExtensionSource.h).
object Codec {
    // Covers as full links: a few sources give them relative to the site.
    private fun cover(
        url: String?,
        base: String?,
    ): String? {
        if (url.isNullOrEmpty() || base.isNullOrEmpty() || url.contains("://")) return url
        return base.toHttpUrlOrNull()?.resolve(url)?.toString() ?: url
    }

    fun mangas(
        page: MangasPage,
        base: String? = null,
    ): JsonObject =
        buildJsonObject {
            put(
                "items",
                buildJsonArray {
                    for (manga in page.mangas) {
                        add(
                            buildJsonObject {
                                put("url", manga.url)
                                put("title", manga.title)
                                put("cover", cover(manga.thumbnail_url, base))
                            },
                        )
                    }
                },
            )
            put("hasNextPage", page.hasNextPage)
        }

    fun details(
        manga: SManga,
        base: String? = null,
    ): JsonObject =
        buildJsonObject {
            put("title", manga.title)
            put("cover", cover(manga.thumbnail_url, base))
            put("description", manga.description)
            put("author", manga.author)
            put("artist", manga.artist)
            put("status", manga.status)
            put("genres", buildJsonArray { manga.getGenres()?.forEach { add(JsonPrimitive(it)) } })
        }

    fun chapters(list: List<SChapter>): JsonArray =
        buildJsonArray {
            for (chapter in list) {
                add(
                    buildJsonObject {
                        put("url", chapter.url)
                        put("name", chapter.name)
                        put("number", chapter.chapter_number)
                        put("uploaded", chapter.date_upload)
                        put("scanlator", chapter.scanlator)
                    },
                )
            }
        }

    fun pages(list: List<Page>): JsonArray =
        buildJsonArray {
            list.forEachIndexed { i, page ->
                add(
                    buildJsonObject {
                        // The order is what counts; extensions' own indexes can repeat.
                        put("index", i)
                        put("url", page.url)
                        put("imageUrl", page.imageUrl ?: "")
                    },
                )
            }
        }

    fun page(json: JsonObject): Page =
        Page(
            json["index"]?.jsonPrimitive?.intOrNull ?: 0,
            json["url"]?.jsonPrimitive?.contentOrNull.orEmpty(),
            json["imageUrl"]?.jsonPrimitive?.contentOrNull?.ifEmpty { null },
        )

    // ---------------------------------------------------------------- filters

    fun filters(list: FilterList): JsonArray = buildJsonArray { list.forEach { add(filter(it)) } }

    private fun filter(filter: Filter<*>): JsonObject =
        buildJsonObject {
            put("name", filter.name)
            when (filter) {
                is Filter.Header -> put("type", "header")
                is Filter.Separator -> put("type", "separator")
                is Filter.Select<*> -> {
                    put("type", "select")
                    put("values", buildJsonArray { filter.values.forEach { add(JsonPrimitive(it.toString())) } })
                    put("state", filter.state)
                }
                is Filter.Text -> {
                    put("type", "text")
                    put("state", filter.state)
                }
                is Filter.CheckBox -> {
                    put("type", "checkbox")
                    put("state", filter.state)
                }
                is Filter.TriState -> {
                    put("type", "tristate")
                    put("state", filter.state)
                }
                is Filter.Sort -> {
                    put("type", "sort")
                    put("values", buildJsonArray { filter.values.forEach { add(JsonPrimitive(it)) } })
                    val selection = filter.state
                    put(
                        "state",
                        if (selection == null) {
                            JsonNull
                        } else {
                            buildJsonObject {
                                put("index", selection.index)
                                put("ascending", selection.ascending)
                            }
                        },
                    )
                }
                is Filter.Group<*> -> {
                    put("type", "group")
                    put(
                        "filters",
                        buildJsonArray {
                            filter.state.forEach { child -> if (child is Filter<*>) add(filter(child)) else add(JsonNull) }
                        },
                    )
                }
            }
        }

    // Applies states SCANCORE sends to a fresh list from the source, by
    // position (the same list the user saw).
    fun applyFilters(
        list: FilterList,
        states: JsonArray,
    ): FilterList {
        list.forEachIndexed { i, filter -> states.getOrNull(i)?.let { apply(filter, it) } }
        return list
    }

    @Suppress("UNCHECKED_CAST")
    private fun apply(
        filter: Filter<*>,
        json: JsonElement,
    ) {
        val o = json as? JsonObject ?: return
        val state = o["state"]
        when (filter) {
            is Filter.Select<*> -> state?.jsonPrimitive?.intOrNull?.let { filter.state = it.coerceIn(0, (filter.values.size - 1).coerceAtLeast(0)) }
            is Filter.Text -> state?.jsonPrimitive?.contentOrNull?.let { filter.state = it }
            is Filter.CheckBox -> state?.jsonPrimitive?.booleanOrNull?.let { filter.state = it }
            is Filter.TriState -> state?.jsonPrimitive?.intOrNull?.let { filter.state = it.coerceIn(0, 2) }
            is Filter.Sort ->
                filter.state =
                    (state as? JsonObject)?.let {
                        Filter.Sort.Selection(
                            it["index"]?.jsonPrimitive?.intOrNull ?: 0,
                            it["ascending"]?.jsonPrimitive?.booleanOrNull ?: true,
                        )
                    }
            is Filter.Group<*> -> {
                val children = o["filters"] as? JsonArray ?: return
                (filter.state as List<Any?>).forEachIndexed { i, child ->
                    if (child is Filter<*>) children.getOrNull(i)?.let { apply(child, it) }
                }
            }
            else -> {}
        }
    }

    fun JsonObject.child(key: String): JsonObject? = this[key] as? JsonObject

    fun JsonObject.array(key: String): JsonArray = (this[key] as? JsonArray) ?: JsonArray(emptyList())

    fun obj(element: JsonElement?): JsonObject = element?.jsonObject ?: JsonObject(emptyMap())
}
