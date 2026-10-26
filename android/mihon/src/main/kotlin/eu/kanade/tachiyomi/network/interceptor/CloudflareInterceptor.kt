package eu.kanade.tachiyomi.network.interceptor

import eu.kanade.tachiyomi.network.BrowserCheckException
import eu.kanade.tachiyomi.network.HostNetwork
import okhttp3.HttpUrl
import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.Response
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.locks.ReentrantReadWriteLock
import kotlin.concurrent.read
import kotlin.concurrent.write

// Named as Mihon's: Keiyoushi's extensions look for this class name in the
// default client (see NetworkHelper).
// A Cloudflare challenge, handled as Mihon's interceptor of this name does: the
// solver passes it in a hidden browser and the request is sent again with
// the clearance. Requests to a host share its lock while the challenge is
// solved, so concurrent ones wait for that one solve instead of each
// opening their own; one that waited finds the new clearance and goes
// straight on. A check the solver cannot pass goes to the reader
// (BrowserCheckException, the "Open browser check" button).
class CloudflareInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val lock = hostLocks.computeIfAbsent(request.url.host) { ReentrantReadWriteLock() }
        val (response, clearance) =
            lock.read {
                val response = chain.proceed(request)
                if (!isChallenge(response)) return response
                response to clearance(request.url)
            }
        // What actually went out, with the headers and user agent the
        // extension's own interceptors set.
        val sent = response.request
        val userAgent = sent.header("User-Agent") ?: HostNetwork.userAgent
        response.close()
        // write() lets go of this thread's read hold first, so a request made
        // from inside another to the same host cannot wait on itself.
        val solved =
            lock.write {
                isCleared(request.url, clearance) ||
                    listOfNotNull(HostNetwork.browserCheckSolver, HostNetwork.readerBrowserCheck).any { solver ->
                        runCatching { solver.solve(challengeUrl(request), userAgent, sent.headers) }.getOrDefault(false)
                    }
            }
        if (solved) {
            val again = chain.proceed(request)
            if (!isChallenge(again)) return again
            again.close()
        }
        throw BrowserCheckException(request.url.newBuilder().encodedPath("/").query(null).fragment(null).build().toString(), userAgent)
    }

    private fun clearance(url: HttpUrl): String? =
        HostNetwork.cookieJar.loadForRequest(url).firstOrNull { it.name == "cf_clearance" }?.value

    private fun isCleared(
        url: HttpUrl,
        previous: String?,
    ): Boolean = clearance(url).let { !it.isNullOrBlank() && it != previous }

    // A browser can only load a page with GET; the clearance covers the
    // whole site, so for other methods it is earned on the site's root.
    private fun challengeUrl(request: Request): HttpUrl =
        if (request.method == "GET") request.url else request.url.newBuilder().encodedPath("/").query(null).fragment(null).build()

    companion object {
        // One per host for every client, since extensions build their own
        // from the shared one.
        private val hostLocks = ConcurrentHashMap<String, ReentrantReadWriteLock>()

        // Cloudflare's own sign (cf-mitigated), or its challenge page on
        // servers that leave the header out.
        fun isChallenge(response: Response): Boolean {
            if (response.code !in setOf(403, 503, 429)) return false
            if (response.header("Server")?.startsWith("cloudflare", true) != true) return false
            return response.header("cf-mitigated") == "challenge" ||
                response.peekBody(8192).string().let { "Just a moment" in it || "challenge-platform" in it }
        }
    }
}
