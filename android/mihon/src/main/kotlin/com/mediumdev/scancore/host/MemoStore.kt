package com.mediumdev.scancore.host

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

// Extensions on lib 1.6 (Aniyomi: 17) keep notes on a manga or chapter
// (anime or episode, "memo") that the app must hand back with it. SCANCORE
// knows series and chapters by link, so the host keeps the notes, by source
// and link, in one file it writes a moment after the last change. Most
// extensions never set one. Anime notes share the maps under an "anime:"
// prefix, as an anime and a manga source can have the same id.
class MemoStore(
    private val file: File?,
) {
    private val mangas = ConcurrentHashMap<String, JsonObject>()
    private val chapters = ConcurrentHashMap<String, JsonObject>()
    private val dirty = AtomicBoolean(false)
    private val writer =
        Executors.newSingleThreadScheduledExecutor { r -> Thread(r, "memo-writer").apply { isDaemon = true } }

    init {
        runCatching {
            if (file != null && file.exists()) {
                val root = Json.parseToJsonElement(file.readText()).jsonObject
                root["mangas"]?.jsonObject?.forEach { (k, v) -> mangas[k] = v.jsonObject }
                root["chapters"]?.jsonObject?.forEach { (k, v) -> chapters[k] = v.jsonObject }
            }
        }
    }

    private fun key(
        source: Long,
        url: String,
    ) = "$source|$url"

    fun manga(
        source: Long,
        url: String,
    ) = mangas[key(source, url)]

    fun chapter(
        source: Long,
        url: String,
    ) = chapters[key(source, url)]

    fun putManga(
        source: Long,
        url: String,
        memo: JsonObject,
    ) {
        if (mangas.put(key(source, url), memo) != memo) scheduleSave()
    }

    fun putChapter(
        source: Long,
        url: String,
        memo: JsonObject,
    ) {
        if (chapters.put(key(source, url), memo) != memo) scheduleSave()
    }

    fun anime(
        source: Long,
        url: String,
    ) = mangas["anime:" + key(source, url)]

    fun episode(
        source: Long,
        url: String,
    ) = chapters["anime:" + key(source, url)]

    fun putAnime(
        source: Long,
        url: String,
        memo: JsonObject,
    ) {
        if (mangas.put("anime:" + key(source, url), memo) != memo) scheduleSave()
    }

    fun putEpisode(
        source: Long,
        url: String,
        memo: JsonObject,
    ) {
        if (chapters.put("anime:" + key(source, url), memo) != memo) scheduleSave()
    }

    private fun scheduleSave() {
        if (file == null || !dirty.compareAndSet(false, true)) return
        writer.schedule({ save() }, 2, TimeUnit.SECONDS)
    }

    fun save() {
        if (file == null) return
        dirty.set(false)
        val text =
            buildJsonObject {
                put("mangas", JsonObject(HashMap(mangas)))
                put("chapters", JsonObject(HashMap(chapters)))
            }.toString()
        file.parentFile?.mkdirs()
        val temp = File(file.path + ".tmp")
        temp.writeText(text)
        temp.renameTo(file)
    }
}
