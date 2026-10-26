package org.kurodev.bacakomik.mihon

import android.content.Context
import org.kurodev.bacakomik.mihon.host.describeFailure
import kotlinx.coroutines.runBlocking
import java.io.BufferedOutputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.URLDecoder
import java.security.SecureRandom
import java.util.concurrent.Executors

/**
 * Serves `mihon://` images ([Images]) over HTTP on this device only, so the
 * app's background downloader (which runs outside Dart and only speaks
 * HTTP) can save Mihon chapter pages while the app is closed:
 *
 *   `http://127.0.0.1:<port>/<token>/image?u=<encoded mihon:// URL>`
 *
 * Started with the process ([start] from the app's Application), it starts
 * the host by itself when Dart isn't running ([MihonHost.ensureStarted]).
 * The port is kept across runs so queued downloads still reach it; the
 * random token keeps other apps on the phone out.
 */
object MihonProxy {
    private const val PREFS = "bacakomik_mihon_proxy"

    @Volatile
    private var base: String? = null

    private val workers = Executors.newFixedThreadPool(3) { r -> Thread(r, "mihon-proxy").apply { isDaemon = true } }

    /** `http://127.0.0.1:<port>/<token>`; starts the server on first use. */
    @Synchronized
    fun start(context: Context): String {
        base?.let { return it }
        val app = context.applicationContext
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val token =
            prefs.getString("token", null) ?: ByteArray(16)
                .also { SecureRandom().nextBytes(it) }
                .joinToString("") { "%02x".format(it) }
                .also { prefs.edit().putString("token", it).apply() }
        val loopback = InetAddress.getByName("127.0.0.1")
        val server =
            runCatching { ServerSocket(prefs.getInt("port", 0), 16, loopback) }
                .getOrElse { ServerSocket(0, 16, loopback) }
        prefs.edit().putInt("port", server.localPort).apply()
        Thread({ serve(app, server, token) }, "mihon-proxy-accept").apply { isDaemon = true }.start()
        return "http://127.0.0.1:${server.localPort}/$token".also { base = it }
    }

    private fun serve(
        context: Context,
        server: ServerSocket,
        token: String,
    ) {
        while (true) {
            val socket = runCatching { server.accept() }.getOrNull() ?: continue
            workers.execute { runCatching { socket.use { answer(context, it, token) } } }
        }
    }

    private fun answer(
        context: Context,
        socket: Socket,
        token: String,
    ) {
        socket.soTimeout = 120_000
        val input = socket.getInputStream().bufferedReader(Charsets.ISO_8859_1)
        val request = input.readLine() ?: return
        // The rest of the request head; nothing in it is needed.
        while (!input.readLine().isNullOrEmpty()) Unit
        val out = BufferedOutputStream(socket.getOutputStream())
        val target = request.split(' ').getOrNull(1).orEmpty()
        val path = target.substringBefore('?')
        if (request.substringBefore(' ') != "GET" || path != "/$token/image") return reply(out, 403, "Forbidden")
        val url =
            target
                .substringAfter('?', "")
                .split('&')
                .firstOrNull { it.startsWith("u=") }
                ?.let { URLDecoder.decode(it.removePrefix("u="), "UTF-8") }
                ?: return reply(out, 400, "No image")
        try {
            MihonHost.ensureStarted(context)
            val (bytes, type) = runBlocking { MihonHost.image(url) }
            out.write(
                (
                    "HTTP/1.1 200 OK\r\nContent-Type: ${type ?: "application/octet-stream"}\r\n" +
                        "Content-Length: ${bytes.size}\r\nConnection: close\r\n\r\n"
                ).toByteArray(Charsets.ISO_8859_1),
            )
            out.write(bytes)
            out.flush()
        } catch (e: Throwable) {
            val failure = describeFailure(e)
            reply(out, failure.status.coerceIn(400, 599), failure.message)
        }
    }

    private fun reply(
        out: OutputStream,
        status: Int,
        message: String,
    ) {
        val body = message.toByteArray(Charsets.UTF_8)
        out.write(
            "HTTP/1.1 $status Error\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: ${body.size}\r\nConnection: close\r\n\r\n"
                .toByteArray(Charsets.ISO_8859_1),
        )
        out.write(body)
        out.flush()
    }
}
