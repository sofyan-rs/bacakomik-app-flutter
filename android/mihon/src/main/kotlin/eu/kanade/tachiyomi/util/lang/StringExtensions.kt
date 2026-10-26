// Copied from Mihon (Apache-2.0); SCANCORE replaced the natsort and androidx
// helpers with plain code.
package eu.kanade.tachiyomi.util.lang

import android.text.Html
import java.nio.charset.StandardCharsets
import kotlin.math.floor

/**
 * Replaces the given string to have at most [count] characters using [replacement] at its end.
 * If [replacement] is longer than [count] an exception will be thrown when `length > count`.
 */
fun String.chop(count: Int, replacement: String = "…"): String {
    return if (length > count) {
        take(count - replacement.length) + replacement
    } else {
        this
    }
}

/**
 * Replaces the given string to have at most [count] characters using [replacement] near the center.
 * If [replacement] is longer than [count] an exception will be thrown when `length > count`.
 */
fun String.truncateCenter(count: Int, replacement: String = "..."): String {
    if (length <= count) {
        return this
    }

    val pieceLength: Int = floor((count - replacement.length).div(2.0)).toInt()

    return "${take(pieceLength)}$replacement${takeLast(pieceLength)}"
}

/**
 * Case-insensitive natural comparator for strings.
 */
fun String.compareToCaseInsensitiveNaturalOrder(other: String): Int {
    // SCANCORE: runs of digits compare as numbers, the rest case-insensitively
    // (in place of the natsort library).
    var i = 0
    var j = 0
    while (i < length && j < other.length) {
        val a = this[i]
        val b = other[j]
        if (a.isDigit() && b.isDigit()) {
            val startA = i
            val startB = j
            while (i < length && this[i].isDigit()) i++
            while (j < other.length && other[j].isDigit()) j++
            val numberA = substring(startA, i).trimStart('0')
            val numberB = other.substring(startB, j).trimStart('0')
            if (numberA.length != numberB.length) return numberA.length - numberB.length
            val compared = numberA.compareTo(numberB)
            if (compared != 0) return compared
        } else {
            val compared = a.lowercaseChar().compareTo(b.lowercaseChar())
            if (compared != 0) return compared
            i++
            j++
        }
    }
    return (length - i) - (other.length - j)
}

/**
 * Returns the size of the string as the number of bytes.
 */
fun String.byteSize(): Int {
    return toByteArray(StandardCharsets.UTF_8).size
}

/**
 * Returns a string containing the first [n] bytes from this string, or the entire string if this
 * string is shorter.
 */
fun String.takeBytes(n: Int): String {
    val bytes = toByteArray(StandardCharsets.UTF_8)
    return if (bytes.size <= n) {
        this
    } else {
        bytes.decodeToString(endIndex = n).replace("\uFFFD", "")
    }
}

/**
 * HTML-decode the string
 */
fun String.htmlDecode(): String {
    @Suppress("DEPRECATION")
    return Html.fromHtml(this).toString()
}
