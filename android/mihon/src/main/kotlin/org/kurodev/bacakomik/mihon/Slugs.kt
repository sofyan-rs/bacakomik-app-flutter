package org.kurodev.bacakomik.mihon

import android.util.Base64
import com.mediumdev.scancore.host.HostError

/**
 * Mihon addresses series and chapters by their path on the site
 * (`/manga/123?x=y`). The app keys comics by `<sourceId>:<slug>` and stores
 * the key in Hive, download folders and links, so the path becomes an
 * ASCII, slash-free slug: base64url without padding.
 */
object Slugs {
    private const val FLAGS = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP

    fun encode(text: String): String = Base64.encodeToString(text.toByteArray(Charsets.UTF_8), FLAGS)

    fun decode(slug: String): String =
        runCatching { String(Base64.decode(slug, FLAGS), Charsets.UTF_8) }
            .getOrElse { throw HostError("Not a series of this source: $slug", 400) }
}
