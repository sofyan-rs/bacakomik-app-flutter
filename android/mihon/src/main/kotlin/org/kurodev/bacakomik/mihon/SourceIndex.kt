package org.kurodev.bacakomik.mihon

import android.content.Context
import com.mediumdev.scancore.host.HostError
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.Json

/**
 * Installed extensions and the sources they hold, kept on the Kotlin side so
 * a call naming only a source id (a cover shown at start, before Dart loaded
 * anything) finds its APK and trusted signer.
 *
 *   `pkg:<pkg>` → `{apk, signer, sources: [ids]}`
 *   `src:<id>`  → pkg
 */
class SourceIndex(
    context: Context,
) {
    private val prefs = context.getSharedPreferences("bacakomik_mihon_index", Context.MODE_PRIVATE)

    @Synchronized
    fun put(
        pkg: String,
        apk: String,
        signer: String,
        sources: List<String>,
    ) {
        val edit = prefs.edit()
        entry(pkg)?.sources()?.forEach { if (pkgOf(it) == pkg) edit.remove("src:$it") }
        edit.putString(
            "pkg:$pkg",
            buildJsonObject {
                put("apk", apk)
                put("signer", signer)
                put("sources", JsonArray(sources.map(::JsonPrimitive)))
            }.toString(),
        )
        for (id in sources) edit.putString("src:$id", pkg)
        edit.apply()
    }

    /** The source ids [pkg] held and no other package holds now. */
    @Synchronized
    fun remove(pkg: String): List<String> {
        // Another package (a fork keeping the ids) may hold a source now.
        val ids = entry(pkg)?.sources().orEmpty().filter { pkgOf(it) == pkg }
        val edit = prefs.edit().remove("pkg:$pkg")
        for (id in ids) edit.remove("src:$id")
        edit.apply()
        return ids
    }

    /** What ExtensionHost needs to find [sourceId]: pkg, apk, signer, source. */
    fun params(sourceId: String): JsonObject {
        val pkg = prefs.getString("src:$sourceId", null) ?: throw HostError("Source $sourceId is not installed.", 404)
        return params(pkg, sourceId)
    }

    fun params(
        pkg: String,
        sourceId: String?,
    ): JsonObject {
        val entry = entry(pkg) ?: throw HostError("$pkg is not installed.", 404)
        return buildJsonObject {
            put("pkg", pkg)
            put("apk", entry["apk"]!!.jsonPrimitive.content)
            put("signer", entry["signer"]!!.jsonPrimitive.content)
            if (sourceId != null) put("source", sourceId)
        }
    }

    fun pkgOf(sourceId: String): String? = prefs.getString("src:$sourceId", null)

    private fun entry(pkg: String): JsonObject? = prefs.getString("pkg:$pkg", null)?.let { Json.parseToJsonElement(it).jsonObject }

    private fun JsonObject.sources() = this["sources"]?.jsonArray?.map { it.jsonPrimitive.content }.orEmpty()
}
