package org.kurodev.yoru.mihon.desktop

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import org.kurodev.yoru.mihon.host.describeFailure
import java.io.BufferedReader
import java.io.Writer
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * The line protocol between the app and this process: one JSON object per
 * line, UTF-8, on stdin and stdout.
 *
 * - App → host: `{"id", "method", "params"}`, answered with `{"id", "result"}`
 *   or `{"id", "error": {message, status, verifyUrl, verifyAgent}}`. Calls run
 *   at the same time and are answered in any order.
 * - Host → app: `{"ask", "method", "params"}` (a browser check), answered by
 *   the app with `{"answer", "result"}`.
 */
class LineServer(
    private val out: Writer,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val asks = ConcurrentHashMap<Int, CompletableFuture<JsonElement>>()
    private val nextAsk = AtomicInteger()

    fun send(message: JsonObject) {
        val line = message.toString()
        synchronized(out) {
            out.write(line)
            out.write("\n")
            out.flush()
        }
    }

    /**
     * Asks the app [method] and waits up to [timeoutMs] for its answer; null
     * when it answers null, does not answer in time, or the app has gone.
     * Blocks: never on a thread that reads stdin.
     */
    fun ask(
        method: String,
        params: JsonObject,
        timeoutMs: Long,
    ): JsonElement? {
        val id = nextAsk.incrementAndGet()
        val answer = CompletableFuture<JsonElement>()
        asks[id] = answer
        return try {
            send(
                buildJsonObject {
                    put("ask", id)
                    put("method", method)
                    put("params", params)
                },
            )
            answer.get(timeoutMs, TimeUnit.MILLISECONDS).takeUnless { it is JsonNull }
        } catch (_: Exception) {
            null
        } finally {
            asks.remove(id)
        }
    }

    /**
     * Reads calls until stdin closes or [stop] says to, answering each from
     * [handle] on its own coroutine. [stop] runs on the reading thread, for a
     * call that ends the process.
     */
    fun serve(
        input: BufferedReader,
        handle: suspend (method: String, params: JsonObject) -> JsonElement,
        stop: (method: String) -> Boolean,
    ) {
        while (true) {
            val line = input.readLine() ?: return
            if (line.isBlank()) continue
            val message =
                try {
                    Json.parseToJsonElement(line) as? JsonObject
                } catch (_: Exception) {
                    null
                } ?: continue
            val answer = message["answer"]
            if (answer != null) {
                answer.jsonPrimitive.content.toIntOrNull()?.let { asks[it] }?.complete(message["result"] ?: JsonNull)
                continue
            }
            val id = message["id"] ?: continue
            val method = (message["method"] as? JsonPrimitive)?.content ?: continue
            if (stop(method)) {
                send(buildJsonObject { put("id", id); put("result", JsonNull) })
                return
            }
            val params = message["params"] as? JsonObject ?: JsonObject(emptyMap())
            scope.launch {
                val reply =
                    try {
                        val result = handle(method, params)
                        buildJsonObject {
                            put("id", id)
                            put("result", result)
                        }
                    } catch (e: Throwable) {
                        val failure = describeFailure(e)
                        buildJsonObject {
                            put("id", id)
                            put(
                                "error",
                                buildJsonObject {
                                    put("message", failure.message)
                                    put("status", failure.status)
                                    put("verifyUrl", failure.verifyUrl)
                                    put("verifyAgent", failure.verifyAgent)
                                },
                            )
                        }
                    }
                send(reply)
            }
        }
    }
}
