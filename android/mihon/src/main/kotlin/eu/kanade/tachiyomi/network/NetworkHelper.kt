// SCANCORE's NetworkHelper, with the members Mihon's has (client,
// cloudflareClient, defaultUserAgentProvider) so extensions work unchanged.
// The default client is built as Mihon's (0.20.1 and later): exactly
// UncaughtException, UserAgent and Cloudflare interceptors, no Brotli or
// IgnoreGzip, because Keiyoushi's extensions check it by class name before
// they make a request ("CloudflareInterceptor must be present in default
// client") and add their own decompression (Brotli, Gzip and Zstd).
package eu.kanade.tachiyomi.network

import android.content.Context
import eu.kanade.tachiyomi.network.interceptor.CloudflareInterceptor
import eu.kanade.tachiyomi.network.interceptor.UncaughtExceptionInterceptor
import eu.kanade.tachiyomi.network.interceptor.UserAgentInterceptor
import okhttp3.Cache
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import java.io.File
import java.util.concurrent.TimeUnit

class NetworkHelper(
    @Suppress("UNUSED_PARAMETER") context: Context,
) {
    val cookieJar get() = HostNetwork.cookieJar

    // The extension asking (NetworkUse) gets its own copy, which counts
    // the sites it contacts; it shares the connections, cache and cookies.
    val client: OkHttpClient
        get() {
            val pkg = NetworkUse.current.get() ?: return base
            return clients.getOrPut(pkg) { base.newBuilder().addNetworkInterceptor(NetworkUseInterceptor(pkg)).build() }
        }

    private val clients = java.util.concurrent.ConcurrentHashMap<String, OkHttpClient>()

    private val base: OkHttpClient by lazy {
        OkHttpClient
            .Builder()
            .cookieJar(HostNetwork.cookieJar)
            .dns(HostNetwork.dns)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .callTimeout(2, TimeUnit.MINUTES)
            .apply {
                HostNetwork.cacheDir?.let { cache(Cache(File(it, "network_cache"), 5L * 1024 * 1024)) }
            }.addInterceptor(UncaughtExceptionInterceptor())
            .addInterceptor(UserAgentInterceptor(::defaultUserAgentProvider))
            .addInterceptor(CloudflareInterceptor())
            .addNetworkInterceptor(ReadableImagesInterceptor())
            .build()
    }

    @Deprecated("The regular client handles Cloudflare by default")
    @Suppress("UNUSED")
    val cloudflareClient: OkHttpClient get() = client

    fun defaultUserAgentProvider() = HostNetwork.userAgent
}

// SCANCORE shows images with Qt, which reads JPEG, PNG, GIF and WebP but not
// AVIF, JPEG XL or HEIF. Image servers that pick the format from the Accept
// header (many CDNs and image proxies do) then send one SCANCORE can show.
// A network interceptor, so it also sees headers extensions add.
class ReadableImagesInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val accept = request.header("Accept") ?: return chain.proceed(request)
        val kept = accept.split(',').filterNot { part -> unreadable.any { part.trim().startsWith(it, ignoreCase = true) } }
        if (kept.size == accept.split(',').size) return chain.proceed(request)
        return chain.proceed(request.newBuilder().header("Accept", kept.joinToString(",").ifEmpty { "*/*" }).build())
    }

    private val unreadable = listOf("image/avif", "image/jxl", "image/heif", "image/heic")
}
