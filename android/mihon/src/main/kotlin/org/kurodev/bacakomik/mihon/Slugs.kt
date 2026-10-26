package org.kurodev.bacakomik.mihon

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import org.kurodev.bacakomik.mihon.host.HostError
import java.security.MessageDigest

/**
 * Mihon addresses series and chapters by their path on the site
 * (`/manga/123?x=y`). The app keys comics by `<sourceId>:<slug>` and stores
 * the key in Hive, download folders and links, so the path becomes an
 * ASCII, slash-free slug: base64url without padding.
 *
 * A path whose slug would be over [MAX] characters (the app's keys stop at
 * 240) gets `~` + its SHA-1 instead (`~` is not in base64url), and the path
 * is remembered on this device to read it back. Another device learns it
 * when the comic shows up there (a list, a search, an import).
 */
object Slugs {
    private const val FLAGS = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP

    /** Longest base64url slug; `ExtensionMeta.mihonSlug` in Dart uses the same. */
    const val MAX = 200

    private const val HASHED = '~'

    @Volatile
    private var paths: SharedPreferences? = null

    fun init(context: Context) {
        paths = context.getSharedPreferences("bacakomik_mihon_slugs", Context.MODE_PRIVATE)
    }

    fun encode(text: String): String {
        val slug = Base64.encodeToString(text.toByteArray(Charsets.UTF_8), FLAGS)
        if (slug.length <= MAX) return slug
        return remember(text)
    }

    /** The hashed slug of [text], remembered so [decode] can read it back. */
    fun remember(text: String): String {
        val slug = HASHED + sha1(text)
        paths?.let { if (it.getString(slug, null) != text) it.edit().putString(slug, text).apply() }
        return slug
    }

    /** Plain base64url both ways, for image URLs (values, not keys). */
    fun encodeRaw(text: String): String = Base64.encodeToString(text.toByteArray(Charsets.UTF_8), FLAGS)

    fun decodeRaw(data: String): String =
        runCatching { String(Base64.decode(data, FLAGS), Charsets.UTF_8) }
            .getOrElse { throw HostError("Not a Mihon image.", 400) }

    fun decode(slug: String): String {
        if (slug.startsWith(HASHED)) {
            return paths?.getString(slug, null)
                ?: throw HostError("Open this comic from its source once on this device; its link is too long to keep in the library.", 409)
        }
        return runCatching { String(Base64.decode(slug, FLAGS), Charsets.UTF_8) }
            .getOrElse { throw HostError("Not a series of this source: $slug", 400) }
    }

    private fun sha1(text: String) =
        MessageDigest.getInstance("SHA-1").digest(text.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
}
