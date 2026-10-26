// From SCANCORE's MemoStore.kt (MIT, LICENSE-SCANCORE).
package org.kurodev.bacakomik.mihon.host

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

// Extensions on lib 1.6 keep notes on a manga or chapter ("memo") that the
// app must hand back with it. The app knows series and chapters by link, so
// the host keeps the notes, by source and link, in one file it writes a
// moment after the last change. Most extensions never set one. BACAKOMIK:
// Aniyomi's anime and episode notes left out.
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
