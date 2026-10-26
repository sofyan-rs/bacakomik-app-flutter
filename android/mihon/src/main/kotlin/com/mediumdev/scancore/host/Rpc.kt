// From SCANCORE's Rpc.kt (MIT). BACAKOMIK: the line protocol (RpcServer) is
// left out; the app calls ExtensionHost over a MethodChannel instead. What
// stays: HostError, the parameter helpers and the error wording.
package com.mediumdev.scancore.host

import eu.kanade.tachiyomi.network.BrowserCheckException
import eu.kanade.tachiyomi.network.HttpException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonPrimitive
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

// A failure with a message for the user.
class HostError(
    override val message: String,
    val status: Int = 500,
    val verifyUrl: String? = null,
) : Exception(message)

// A failure as the app shows it: a message, an HTTP-like status, and for a
// browser check the page to open and the user agent to open it with.
class HostFailure(
    val message: String,
    val status: Int,
    val verifyUrl: String? = null,
    val verifyAgent: String? = null,
)

// Errors in words the user can act on; never a stack trace.
fun describeFailure(e: Throwable): HostFailure {
    // The first cause of a kind anywhere in the chain: on Android a
    // failed lookup is a GaiException under the UnknownHostException.
    val chain = generateSequence(e) { it.cause }.toList()
    val root = chain.last()
    val browserCheck = chain.firstNotNullOfOrNull { it as? BrowserCheckException }
    val http = chain.firstNotNullOfOrNull { it as? HttpException }
    val unknownHost = chain.firstNotNullOfOrNull { it as? UnknownHostException }
    val io = chain.firstNotNullOfOrNull { it as? IOException }
    return when {
        e is HostError -> HostFailure(e.message, e.status, e.verifyUrl)
        browserCheck != null -> HostFailure(browserCheck.message ?: "Browser check", 403, browserCheck.url, browserCheck.userAgent)
        http != null -> HostFailure("The site answered HTTP ${http.code}.", http.code)
        e is TimeoutCancellationException || chain.any { it is SocketTimeoutException } -> HostFailure("The site took too long to respond.", 504)
        unknownHost != null -> HostFailure("Could not find ${hostName(unknownHost.message)}. Check your connection.", 502)
        // BACAKOMIK: a bare IOException is how extensions report their own
        // problems ("log in to read this"): its message as is.
        io != null && io.javaClass == IOException::class.java && !io.message.isNullOrBlank() -> HostFailure(io.message!!, 502)
        io != null -> HostFailure("Could not reach the site (${io.message ?: io.javaClass.simpleName}).", 502)
        root is UnsupportedOperationException -> HostFailure(root.message ?: "The extension cannot do that.", 501)
        else -> {
            // Not something the reader can act on: the trace goes to the log.
            e.printStackTrace()
            HostFailure("The extension failed: ${root.message ?: root.javaClass.simpleName}", 500)
        }
    }
}

// "fixture.test: Name or service not known" (Java) or 'Unable to resolve
// host "fixture.test": …' (Android).
private fun hostName(message: String?): String =
    message?.let { Regex("\"([^\"]+)\"").find(it)?.groupValues?.get(1) ?: it.substringBefore(':').trim() }
        ?.ifEmpty { null } ?: "the site"

fun JsonObject.string(key: String): String =
    this[key]?.jsonPrimitive?.content ?: throw HostError("The request has no $key.", 400)

fun JsonObject.optString(key: String): String? = (this[key] as? kotlinx.serialization.json.JsonPrimitive)?.content

fun JsonObject.int(
    key: String,
    fallback: Int,
): Int = runCatching { this[key]!!.jsonPrimitive.int }.getOrDefault(fallback)
