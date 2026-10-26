// Aniyomi's source API names the Rx bridge here too. (SCANCORE: its Android
// "actual", for both hosts.)
package eu.kanade.tachiyomi.util

import rx.Observable
import tachiyomi.core.common.util.lang.awaitSingle

suspend fun <T> Observable<T>.awaitSingle(): T = awaitSingle()
