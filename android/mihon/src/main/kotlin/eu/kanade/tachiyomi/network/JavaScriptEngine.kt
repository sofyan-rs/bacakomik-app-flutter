// Mihon's JavaScriptEngine, on whichever QuickJs class the host provides
// (QuickJS on Android, Rhino on desktop).
package eu.kanade.tachiyomi.network

import android.content.Context
import app.cash.quickjs.QuickJs
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Suppress("UNUSED", "UNCHECKED_CAST")
class JavaScriptEngine(
    @Suppress("UNUSED_PARAMETER") context: Context,
) {
    suspend fun <T> evaluate(script: String): T =
        withContext(Dispatchers.Default) {
            QuickJs.create().use {
                it.evaluate(script) as T
            }
        }
}
