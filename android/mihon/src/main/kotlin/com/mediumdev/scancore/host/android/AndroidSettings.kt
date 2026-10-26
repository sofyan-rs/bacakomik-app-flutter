package com.mediumdev.scancore.host.android

import android.content.Context
import androidx.preference.EditTextPreference
import androidx.preference.ListPreference
import androidx.preference.MultiSelectListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceManager
import androidx.preference.PreferenceScreen
import androidx.preference.TwoStatePreference
import com.mediumdev.scancore.host.Configurable
import com.mediumdev.scancore.host.HostError
import com.mediumdev.scancore.host.SettingsBridge
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

// Settings screens with androidx.preference, saved in the source's own
// SharedPreferences as in Mihon.
class AndroidSettings(
    private val context: Context,
) : SettingsBridge {
    private fun screen(source: Configurable): PreferenceScreen {
        val manager = PreferenceManager(context)
        manager.sharedPreferencesName = source.preferenceKey
        val screen = manager.createPreferenceScreen(context)
        source.setup(screen)
        return screen
    }

    private fun PreferenceScreen.all() = (0 until preferenceCount).map { getPreference(it) }

    override fun describe(source: Configurable): JsonArray =
        buildJsonArray {
            for (p in screen(source).all()) {
                if (!p.isVisible) continue
                add(
                    buildJsonObject {
                        put("key", p.key)
                        put("title", p.title?.toString())
                        put("summary", p.summary?.toString())
                        put("enabled", p.isEnabled)
                        when (p) {
                            is TwoStatePreference -> {
                                put("type", "switch")
                                put("value", p.isChecked)
                            }
                            is MultiSelectListPreference -> {
                                put("type", "multiselect")
                                put("entries", strings(p.entries))
                                put("values", strings(p.entryValues))
                                put("value", buildJsonArray { p.values.forEach { add(JsonPrimitive(it)) } })
                            }
                            is ListPreference -> {
                                put("type", "list")
                                put("entries", strings(p.entries))
                                put("values", strings(p.entryValues))
                                put("value", p.value)
                            }
                            is EditTextPreference -> {
                                put("type", "text")
                                put("dialogTitle", p.dialogTitle?.toString())
                                put("value", p.text)
                            }
                            else -> {
                                put("type", "info")
                                put("value", JsonNull)
                            }
                        }
                    },
                )
            }
        }

    override fun set(
        source: Configurable,
        key: String,
        value: JsonElement,
    ) {
        val p: Preference = screen(source).all().firstOrNull { it.key == key } ?: throw HostError("${source.name} has no setting $key.", 404)
        when (p) {
            is TwoStatePreference -> value.jsonPrimitive.boolean.let { if (p.callChangeListener(it)) p.isChecked = it }
            is MultiSelectListPreference ->
                (value as? JsonArray).orEmpty().map { it.jsonPrimitive.content }.toSet().let { if (p.callChangeListener(it)) p.values = it }
            is ListPreference -> value.jsonPrimitive.contentOrNull.let { if (p.callChangeListener(it)) p.value = it }
            is EditTextPreference -> value.jsonPrimitive.contentOrNull.let { if (p.callChangeListener(it)) p.text = it }
            else -> throw HostError("That setting cannot be changed.", 400)
        }
    }

    private fun strings(values: Array<CharSequence>?) = buildJsonArray { values?.forEach { add(JsonPrimitive(it.toString())) } }
}
