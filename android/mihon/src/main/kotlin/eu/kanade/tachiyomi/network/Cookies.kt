// SCANCORE: cookie jars for the host. The persistent one saves to a file so
// a passed browser check survives restarts; SCANCORE adds cookies to it from
// its own browser-check window.
package eu.kanade.tachiyomi.network

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import java.io.File
import java.util.concurrent.ConcurrentHashMap

open class MemoryCookieJar : CookieJar {
    protected val cookies = ConcurrentHashMap<String, Cookie>()

    private fun key(cookie: Cookie) = "${cookie.domain}|${cookie.path}|${cookie.name}"

    override fun saveFromResponse(
        url: HttpUrl,
        cookies: List<Cookie>,
    ) {
        add(cookies)
    }

    open fun add(list: List<Cookie>) {
        val now = System.currentTimeMillis()
        for (cookie in list) {
            if (cookie.expiresAt < now) {
                this.cookies.remove(key(cookie))
            } else {
                this.cookies[key(cookie)] = cookie
            }
        }
    }

    override fun loadForRequest(url: HttpUrl): List<Cookie> {
        val now = System.currentTimeMillis()
        return cookies.values.filter { it.expiresAt >= now && it.matches(url) }
    }

    fun all(): List<Cookie> = cookies.values.toList()

    fun clear() = cookies.clear()
}

open class PersistentCookieJar(
    private val file: File,
) : MemoryCookieJar() {
    @Serializable
    private data class Stored(
        val name: String,
        val value: String,
        val domain: String,
        val path: String,
        val expiresAt: Long,
        val secure: Boolean,
        val httpOnly: Boolean,
        val hostOnly: Boolean,
    )

    private val json = Json { ignoreUnknownKeys = true }

    init {
        runCatching {
            if (file.exists()) {
                val stored = json.decodeFromString<List<Stored>>(file.readText())
                super.add(
                    stored.map {
                        Cookie
                            .Builder()
                            .name(it.name)
                            .value(it.value)
                            .apply { if (it.hostOnly) hostOnlyDomain(it.domain) else domain(it.domain) }
                            .path(it.path)
                            .expiresAt(it.expiresAt)
                            .apply {
                                if (it.secure) secure()
                                if (it.httpOnly) httpOnly()
                            }.build()
                    },
                )
            }
        }
    }

    override fun add(list: List<Cookie>) {
        super.add(list)
        save()
    }

    @Synchronized
    private fun save() {
        val persistent = cookies.values.filter { it.persistent }
        val text =
            json.encodeToString(
                persistent.map { Stored(it.name, it.value, it.domain, it.path, it.expiresAt, it.secure, it.httpOnly, it.hostOnly) },
            )
        file.parentFile?.mkdirs()
        val temp = File(file.path + ".tmp")
        temp.writeText(text)
        temp.renameTo(file)
    }
}
