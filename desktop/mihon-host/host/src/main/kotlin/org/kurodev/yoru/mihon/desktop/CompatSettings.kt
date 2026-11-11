// From SCANCORE's desktop/CompatSettings.kt (MIT).
package org.kurodev.yoru.mihon.desktop

import android.content.Context
import androidx.preference.EditTextPreference
import androidx.preference.ListPreference
import androidx.preference.MultiSelectListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceScreen
import androidx.preference.TwoStatePreference
import org.kurodev.yoru.mihon.host.Configurable
import org.kurodev.yoru.mihon.host.HostError
import org.kurodev.yoru.mihon.host.SettingsBridge
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

// Settings screens with AndroidCompat's preference classes, which read and
// write the source's SharedPreferences directly.
class CompatSettings(
    private val context: Context,
) : SettingsBridge {
    private fun screen(source: Configurable): List<Preference> {
        val screen = PreferenceScreen(context)
        screen.sharedPreferences = source.preferences()
        source.setup(screen)
        return screen.preferences
    }

    override fun describe(source: Configurable): JsonArray = preferences(screen(source))

    override fun set(
        source: Configurable,
        key: String,
        value: JsonElement,
    ) {
        val preference = screen(source).firstOrNull { it.key == key } ?: throw HostError("${source.name} has no setting $key.", 404)
        setPreference(preference, value)
    }

    fun preferences(list: List<Preference>): JsonArray =
        buildJsonArray {
            for (p in list) {
                if (!p.visible) continue
                add(
                    buildJsonObject {
                        put("key", p.key)
                        put("title", p.title?.toString())
                        put("summary", p.summary?.toString())
                        put("enabled", p.isEnabled)
                        when (p) {
                            is TwoStatePreference -> put("type", "switch")
                            is MultiSelectListPreference -> {
                                put("type", "multiselect")
                                put("entries", strings(p.entries))
                                put("values", strings(p.entryValues))
                            }
                            is ListPreference -> {
                                put("type", "list")
                                put("entries", strings(p.entries))
                                put("values", strings(p.entryValues))
                            }
                            is EditTextPreference -> {
                                put("type", "text")
                                put("dialogTitle", p.dialogTitle?.toString())
                            }
                            else -> put("type", "info")
                        }
                        put("value", value(runCatching { p.currentValue }.getOrNull()))
                    },
                )
            }
        }

    // Saves a value and tells the source, as a settings screen would.
    fun setPreference(
        p: Preference,
        value: JsonElement,
    ) {
        val newValue: Any? =
            when (p) {
                is TwoStatePreference -> value.jsonPrimitive.boolean
                // Nothing chosen may come as null (#21).
                is MultiSelectListPreference -> (value as? JsonArray).orEmpty().map { it.jsonPrimitive.content }.toSet()
                else -> value.jsonPrimitive.contentOrNull
            }
        if (p.callChangeListener(newValue)) p.saveNewValue(newValue)
    }

    private fun strings(values: Array<CharSequence>?) = buildJsonArray { values?.forEach { add(JsonPrimitive(it.toString())) } }

    private fun value(value: Any?): JsonElement =
        when (value) {
            null -> JsonNull
            is Boolean -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value)
            is Collection<*> -> buildJsonArray { value.forEach { add(JsonPrimitive(it.toString())) } }
            else -> JsonPrimitive(value.toString())
        }
}
