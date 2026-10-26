// SCANCORE: which sites each extension contacts, for Extensions →
// Diagnostics ("what this extension contacts"). The host tags each call
// with the extension's package (and does while it loads one); a client
// asked for then is the extension's own copy of the default one, whose
// network interceptor counts the hosts it reaches, redirects included.
// Nothing is kept beyond host names, counts and when they were last seen.
package eu.kanade.tachiyomi.network

import kotlinx.coroutines.ThreadContextElement
import okhttp3.Interceptor
import okhttp3.Response
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

object NetworkUse {
    internal val current = ThreadLocal<String?>()

    // A coroutine running for an extension, on whatever thread it resumes.
    class For(
        val pkg: String,
    ) : AbstractCoroutineContextElement(Key),
        ThreadContextElement<String?> {
        companion object Key : CoroutineContext.Key<For>

        override fun updateThreadContext(context: CoroutineContext): String? = current.get().also { current.set(pkg) }

        override fun restoreThreadContext(
            context: CoroutineContext,
            oldState: String?,
        ) = current.set(oldState)
    }

    // Plain code for an extension (loading it), on this thread.
    fun <T> during(
        pkg: String,
        block: () -> T,
    ): T {
        val old = current.get()
        current.set(pkg)
        try {
            return block()
        } finally {
            current.set(old)
        }
    }

    class Seen {
        @Volatile var count = 0L

        @Volatile var last = 0L
    }

    private val seen = ConcurrentHashMap<String, ConcurrentHashMap<String, Seen>>()

    fun record(
        pkg: String,
        host: String,
    ) {
        val entry = seen.getOrPut(pkg) { ConcurrentHashMap() }.getOrPut(host) { Seen() }
        synchronized(entry) {
            entry.count++
            entry.last = System.currentTimeMillis()
        }
    }

    // package → host → (requests, last time in ms).
    fun report(): Map<String, Map<String, Pair<Long, Long>>> = seen.mapValues { (_, hosts) -> hosts.mapValues { (_, s) -> s.count to s.last } }

    fun forget(pkg: String) {
        seen.remove(pkg)
    }
}

class NetworkUseInterceptor(
    private val pkg: String,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        NetworkUse.record(pkg, chain.request().url.host)
        return chain.proceed(chain.request())
    }
}
