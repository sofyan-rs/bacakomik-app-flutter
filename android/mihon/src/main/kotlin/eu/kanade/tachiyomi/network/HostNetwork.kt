// SCANCORE: what the host sets up before any extension loads: the browser
// identity SCANCORE uses (so cookies from its browser-check window stay
// valid), where cookies and the HTTP cache live.
package eu.kanade.tachiyomi.network

import okhttp3.CookieJar
import okhttp3.Dns
import okhttp3.Headers
import okhttp3.HttpUrl
import java.io.File
import java.net.InetAddress

object HostNetwork {
    @Volatile
    var userAgent: String =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"

    @Volatile
    var cookieJar: CookieJar = MemoryCookieJar()

    @Volatile
    var cacheDir: File? = null

    // Tests serve fixture sites on *.test from this machine.
    @Volatile
    var dns: Dns = Dns.SYSTEM

    // Passes browser checks without the reader where it can, as Mihon does:
    // Android's web view in the app, SCANCORE's own browser on desktop.
    // Null where there is none (tests); checks then go to the reader.
    @Volatile
    var browserCheckSolver: BrowserCheckSolver? = null

    // Shows the check to the reader when the hidden one cannot pass it.
    @Volatile
    var readerBrowserCheck: BrowserCheckSolver? = null

    val loopbackForTestDomains =
        Dns { host ->
            if (host.endsWith(".test")) listOf(InetAddress.getLoopbackAddress()) else Dns.SYSTEM.lookup(host)
        }
}

// Opens `url` in a hidden browser with the request's own user agent and
// headers (Cloudflare ties the clearance to the user agent) and returns true
// once the site has set a new clearance cookie, which is then in the cookie
// jar. False when the check needs the reader (an interactive challenge) or
// does not pass within about 30 seconds. Blocks; never on the main thread.
fun interface BrowserCheckSolver {
    fun solve(
        url: HttpUrl,
        userAgent: String,
        headers: Headers,
    ): Boolean
}

// Thrown when a site answers with a browser check that has to be passed in
// SCANCORE's window. `userAgent` is the one the extension sent: the window
// uses it, so the clearance it earns works for the extension.
class BrowserCheckException(
    val url: String,
    val userAgent: String = HostNetwork.userAgent,
) : java.io.IOException("$url asked for a browser check.")
