package org.kurodev.bacakomik.mihon

import com.mediumdev.scancore.host.HostError
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

/**
 * Image URLs of Mihon sources. Their images need the source's own OkHttp
 * client (headers, cookies, interceptors that unscramble pages), so the app
 * gets them through [MihonHost.image] rather than over HTTP:
 *
 *   `mihon://<sourceId>/cover/<base64url of the image URL>`
 *   `mihon://<sourceId>/page/<base64url of the page JSON {index, url, imageUrl}>`
 *
 * The same on every device, so stored covers survive sync and the URL works
 * as the image cache key.
 */
object Images {
    const val SCHEME = "mihon://"

    fun cover(
        sourceId: String,
        url: String?,
    ): String? = url?.takeIf { it.isNotBlank() }?.let { "$SCHEME$sourceId/cover/${Slugs.encodeRaw(it)}" }

    fun page(
        sourceId: String,
        page: JsonObject,
    ): String = "$SCHEME$sourceId/page/${Slugs.encodeRaw(page.toString())}"

    sealed interface Ref {
        val sourceId: String
    }

    class Cover(
        override val sourceId: String,
        val url: String,
    ) : Ref

    class Page(
        override val sourceId: String,
        val page: JsonObject,
    ) : Ref

    fun parse(url: String): Ref {
        if (!url.startsWith(SCHEME)) throw HostError("Not a Mihon image: $url", 400)
        val parts = url.removePrefix(SCHEME).split('/')
        if (parts.size != 3) throw HostError("Not a Mihon image: $url", 400)
        val (source, kind, data) = parts
        return when (kind) {
            "cover" -> Cover(source, Slugs.decodeRaw(data))
            "page" ->
                Page(
                    source,
                    runCatching { Json.parseToJsonElement(Slugs.decodeRaw(data)).jsonObject }
                        .getOrElse { throw HostError("Not a Mihon image: $url", 400) },
                )
            else -> throw HostError("Not a Mihon image: $url", 400)
        }
    }
}
