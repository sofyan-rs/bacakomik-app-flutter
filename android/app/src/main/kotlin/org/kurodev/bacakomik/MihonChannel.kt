package org.kurodev.bacakomik

import android.content.Context
import org.kurodev.bacakomik.mihon.host.describeFailure
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.kurodev.bacakomik.mihon.MihonHost
import org.kurodev.bacakomik.mihon.MihonProxy

/**
 * `bacakomik/mihon`: Dart's way to [MihonHost].
 *
 * - `supported` → bool.
 * - `start` {userAgent, appVersion}.
 * - `handle` {method, args: JSON text} → JSON text.
 * - `image` {url} → {bytes, type}.
 * - `proxyBase` → `http://127.0.0.1:<port>/<token>` ([MihonProxy]), or null.
 *
 * Failures come back as a PlatformException: code = HTTP-like status,
 * message, details = {verifyUrl, verifyAgent} for a browser check.
 */
class MihonChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        MethodChannel(messenger, "bacakomik/mihon").setMethodCallHandler { call, result ->
            if (call.method == "supported") return@setMethodCallHandler result.success(MihonHost.supported)
            if (call.method == "proxyBase") {
                return@setMethodCallHandler result.success(if (MihonHost.supported) runCatching { MihonProxy.start(context) }.getOrNull() else null)
            }
            scope.launch {
                try {
                    val value: Any? =
                        when (call.method) {
                            "start" -> {
                                MihonHost.start(context, call.argument("userAgent"), call.argument<String>("appVersion") ?: "")
                                null
                            }
                            "handle" -> {
                                val args = call.argument<String>("args")?.let { Json.parseToJsonElement(it).jsonObject } ?: JsonObject(emptyMap())
                                MihonHost.handle(call.argument<String>("method")!!, args).toString()
                            }
                            "image" -> {
                                val (bytes, type) = MihonHost.image(call.argument<String>("url")!!)
                                mapOf("bytes" to bytes, "type" to type)
                            }
                            else -> {
                                withContext(Dispatchers.Main) { result.notImplemented() }
                                return@launch
                            }
                        }
                    withContext(Dispatchers.Main) { result.success(value) }
                } catch (e: Throwable) {
                    val failure = describeFailure(e)
                    withContext(Dispatchers.Main) {
                        result.error(
                            failure.status.toString(),
                            failure.message,
                            mapOf("verifyUrl" to failure.verifyUrl, "verifyAgent" to failure.verifyAgent),
                        )
                    }
                }
            }
        }
    }
}
