package org.kurodev.yoru.mihon

import android.content.Context
import okhttp3.Dns
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.dnsoverhttps.DnsOverHttps
import java.net.InetAddress
import java.net.UnknownHostException

/**
 * DNS for Mihon extensions (`HostNetwork.dns`): the system's, or the DNS over
 * HTTPS server picked in the app's settings. Kept in preferences, so a start
 * without Dart (background downloads, MihonProxy) uses it too. When the
 * server cannot answer, the system DNS is asked, as the app's own requests do.
 */
object HostDns : Dns {
    private const val PREFS = "bacakomik_mihon"

    @Volatile
    private var doh: Dns? = null

    override fun lookup(hostname: String): List<InetAddress> {
        val server = doh ?: return Dns.SYSTEM.lookup(hostname)
        return try {
            server.lookup(hostname)
        } catch (e: UnknownHostException) {
            Dns.SYSTEM.lookup(hostname)
        }
    }

    /** Uses [url] (null or blank: off), reaching its host by [bootstrap] IPs when given. */
    fun set(
        context: Context,
        url: String?,
        bootstrap: List<String>,
    ) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString("dohUrl", url ?: "")
            .putString("dohBootstrap", bootstrap.joinToString(","))
            .apply()
        apply(url, bootstrap)
    }

    /** Applies the server saved by the last [set]. */
    fun restore(context: Context) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val bootstrap = prefs.getString("dohBootstrap", "").orEmpty().split(',').filter { it.isNotBlank() }
        apply(prefs.getString("dohUrl", null), bootstrap)
    }

    private fun apply(
        url: String?,
        bootstrap: List<String>,
    ) {
        doh =
            if (url.isNullOrBlank()) {
                null
            } else {
                runCatching {
                    DnsOverHttps
                        .Builder()
                        .client(OkHttpClient())
                        .url(url.toHttpUrl())
                        .apply {
                            // IP literals: no lookup happens here.
                            if (bootstrap.isNotEmpty()) bootstrapDnsHosts(bootstrap.map(InetAddress::getByName))
                        }.includeIPv6(true)
                        .build()
                }.getOrNull()
            }
    }
}
