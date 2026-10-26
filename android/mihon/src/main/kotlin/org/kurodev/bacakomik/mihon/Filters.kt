package org.kurodev.bacakomik.mihon

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

/**
 * Mihon's filter tree (as Codec writes it: `[{name, type, values, state,
 * filters}]`) as the app's filter groups, and the app's values back onto a
 * fresh tree. Each top-level filter is the group `f<index>`:
 *
 * | Mihon | group | values |
 * |---|---|---|
 * | Select | select | option index |
 * | Sort | sort (a select shown as one chip per field) | `<index>:a` / `<index>:d`, `''` for the source's default |
 * | Group of CheckBox / TriState | multi | checked (included) children's indexes |
 * | CheckBox / TriState | multi, one option `1` | |
 *
 * Text, Header and Separator have no group. A group missing from the values
 * keeps the source's default.
 */
object Filters {
    fun groups(tree: JsonArray): JsonArray =
        buildJsonArray {
            tree.forEachIndexed { i, element ->
                val f = element as? JsonObject ?: return@forEachIndexed
                val name = f.text("name")
                val key = "f$i"
                when (f.text("type")) {
                    "select" -> {
                        val values = f.list("values")
                        if (values.isEmpty()) return@forEachIndexed
                        add(
                            // A blank option is the source's "any" (Asura's Creators).
                            group(key, name, "select", values.mapIndexed { j, v -> "$j" to v.ifBlank { ANY } }) {
                                put("default", "${f["state"]?.jsonPrimitive?.intOrNull ?: 0}")
                            },
                        )
                    }
                    "sort" -> {
                        val values = f.list("values")
                        if (values.isEmpty()) return@forEachIndexed
                        val state = f["state"] as? JsonObject
                        // The app shows one chip per field and the direction
                        // as an arrow (FilterGroup.sort).
                        val options =
                            buildList {
                                if (state == null) add("" to "Default")
                                values.forEachIndexed { j, v ->
                                    add("$j:a" to v)
                                    add("$j:d" to v)
                                }
                            }
                        add(group(key, name, "sort", options) { put("default", sortValue(state)) })
                    }
                    "group" -> {
                        val options =
                            f["filters"]?.jsonArray.orEmpty().mapIndexedNotNull { j, child ->
                                val c = child as? JsonObject ?: return@mapIndexedNotNull null
                                if (c.text("type") in toggles) "$j" to c.text("name") else null
                            }
                        if (options.isNotEmpty()) add(group(key, name, "multi", options))
                    }
                    in toggles -> add(group(key, name, "multi", listOf("1" to name)))
                }
            }
        }

    /**
     * Filter values that list [tree]'s source newest series first: a sort
     * field like "Newest", "Recently added" or "Date added", descending, or
     * such an option of a select named like a sort. Not "Latest update",
     * which orders by new chapters. Null when the source has none.
     */
    fun newest(tree: JsonArray): JsonObject? {
        tree.forEachIndexed { i, element ->
            val f = element as? JsonObject ?: return@forEachIndexed
            val values = f.list("values")
            val j = values.indexOfFirst { isNewest(it) }
            if (j < 0) return@forEachIndexed
            when (f.text("type")) {
                "sort" -> return value("f$i", "$j:d")
                "select" -> if (sortName.containsMatchIn(f.text("name"))) return value("f$i", "$j")
            }
        }
        return null
    }

    private val newestName =
        Regex(
            """^\s*(?:newest|new|new(?:est)?\s+(?:series|titles?|manga|comics?|releases?)|recent(?:ly)?\s+added|date\s+added|added|created(?:\s+at)?|creation\s+date|release\s+date|terbaru(?:\s+ditambahkan)?|baru)\s*$""",
            RegexOption.IGNORE_CASE,
        )

    private val sortName = Regex("""sort|order|urut""", RegexOption.IGNORE_CASE)

    private fun isNewest(label: String) = newestName.matches(label.trim())

    private fun value(
        key: String,
        v: String,
    ) = buildJsonObject { put(key, buildJsonArray { add(JsonPrimitive(v)) }) }

    /** Whether [tree] still asks the user to reset it to load genres. */
    fun waitsForGenres(tree: JsonArray): Boolean =
        tree.any {
            val f = it as? JsonObject ?: return@any false
            f.text("type") == "header" && f.text("name").contains("reset", ignoreCase = true)
        }

    /** [tree] with [values] applied; equal to [tree] when nothing changed. */
    fun apply(
        tree: JsonArray,
        values: JsonObject,
    ): JsonArray =
        JsonArray(
            tree.mapIndexed { i, element ->
                val f = element as? JsonObject ?: return@mapIndexed element
                val picked = values["f$i"]?.let { v -> (v as? JsonArray)?.map { it.jsonPrimitive.content } } ?: return@mapIndexed f
                when (f.text("type")) {
                    "select" -> {
                        val index = picked.firstOrNull()?.toIntOrNull() ?: return@mapIndexed f
                        f.with("state", JsonPrimitive(index.coerceIn(0, (f.list("values").size - 1).coerceAtLeast(0))))
                    }
                    "sort" -> f.with("state", sortState(picked.firstOrNull().orEmpty()))
                    "group" -> {
                        val children = f["filters"]?.jsonArray ?: return@mapIndexed f
                        f.with(
                            "filters",
                            JsonArray(
                                children.mapIndexed { j, child ->
                                    val c = child as? JsonObject ?: return@mapIndexed child
                                    toggle(c, "$j" in picked)
                                },
                            ),
                        )
                    }
                    in toggles -> toggle(f, "1" in picked)
                    else -> f
                }
            },
        )

    private val toggles = setOf("checkbox", "tristate")

    /** Label of a blank select option, as the app's own "All" filters. */
    private const val ANY = "All"

    // TriState: 0 ignore, 1 include, 2 exclude. Excluding is not offered;
    // an exclusion the source starts with stays unless the user checks it.
    private fun toggle(
        f: JsonObject,
        on: Boolean,
    ): JsonObject =
        when (f.text("type")) {
            "checkbox" -> if (f["state"]?.jsonPrimitive?.booleanOrNull == on) f else f.with("state", JsonPrimitive(on))
            "tristate" -> {
                val state = f["state"]?.jsonPrimitive?.intOrNull ?: 0
                val next = if (on) 1 else if (state == 1) 0 else state
                if (next == state) f else f.with("state", JsonPrimitive(next))
            }
            else -> f
        }

    private fun sortValue(state: JsonObject?): String {
        if (state == null) return ""
        val index = state["index"]?.jsonPrimitive?.intOrNull ?: 0
        val ascending = state["ascending"]?.jsonPrimitive?.booleanOrNull ?: true
        return "$index:${if (ascending) "a" else "d"}"
    }

    private fun sortState(value: String): JsonElement {
        val index = value.substringBefore(':').toIntOrNull() ?: return JsonNull
        return buildJsonObject {
            put("index", index)
            put("ascending", value.substringAfter(':') != "d")
        }
    }

    private fun group(
        key: String,
        label: String,
        type: String,
        options: List<Pair<String, String>>,
        extra: kotlinx.serialization.json.JsonObjectBuilder.() -> Unit = {},
    ) = buildJsonObject {
        put("key", key)
        put("label", label)
        put("type", type)
        put(
            "options",
            buildJsonArray {
                for ((value, text) in options) {
                    add(
                        buildJsonObject {
                            put("value", value)
                            put("label", text)
                        },
                    )
                }
            },
        )
        extra()
    }

    private fun JsonObject.text(key: String) = this[key]?.jsonPrimitive?.contentOrNull.orEmpty()

    private fun JsonObject.list(key: String) = (this[key] as? JsonArray)?.map { it.jsonPrimitive.content }.orEmpty()

    private fun JsonObject.with(
        key: String,
        value: JsonElement,
    ) = JsonObject(this + (key to value))
}
