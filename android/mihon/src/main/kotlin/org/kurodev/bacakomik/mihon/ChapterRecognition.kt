// From Mihon's ChapterRecognition (Apache License 2.0,
// https://github.com/mihonapp/mihon). Mihon finds the number in a chapter's
// name when the extension leaves chapter_number unset (-1); many do.
package org.kurodev.bacakomik.mihon

object ChapterRecognition {
    private const val NUMBER_PATTERN = """([0-9]+)(\.[0-9]+)?(\.?[a-z]+)?"""

    /** All cases with v.a, vol.a, version.a, s.a, season.a: "Volume 1 Chapter 2". */
    private val unwanted = """\b(?:v|ver|vol|version|volume|season|s)[^a-z]?[0-9]+""".toRegex()

    /** "Ch.1 extra" → "Ch.1extra". */
    private val unwantedWhiteSpace = """\s(?=extra|special|omake)""".toRegex()

    /** "Ch.xx", "Ch. xx". */
    private val basic = """(?<=ch\.) *$NUMBER_PATTERN""".toRegex()

    private val number = NUMBER_PATTERN.toRegex()

    /** [chapterNumber] when the extension set one, else the number in [chapterName]; -1 when none. */
    fun parseChapterNumber(
        mangaTitle: String,
        chapterName: String,
        chapterNumber: Double? = null,
    ): Double {
        // A number the extension gave (or -2, "a chapter, not numbered") wins.
        if (chapterNumber != null && (chapterNumber == -2.0 || chapterNumber > -1.0)) return chapterNumber

        val clean =
            chapterName
                .lowercase()
                .let { if (mangaTitle.isBlank()) it else it.replace(mangaTitle.lowercase(), "") }
                .trim()
                .replace(',', '.')
                .replace('-', '.')
                .replace(unwantedWhiteSpace, "")

        val matches = number.findAll(clean)
        when {
            matches.none() -> return chapterNumber ?: -1.0
            matches.count() > 1 -> {
                // Drop volume and season numbers, then prefer "ch.x".
                unwanted.replace(clean, "").let { name ->
                    basic.find(name)?.let { return fromMatch(it) }
                    number.find(name)?.let { return fromMatch(it) }
                }
            }
        }
        return fromMatch(matches.first())
    }

    /**
     * BACAKOMIK: numbers for every chapter of a list in Mihon's order (newest
     * first), from [numbers] (-1 where none was found). The app keys
     * chapters by number, so one without a number gets one just above the
     * numbered chapter before it: "Extra" after chapter 9 is 9.001, a second
     * one 9.002 (0.001 above 0 before any numbered chapter). It depends only
     * on what comes before it, so it stays the same as new chapters come
     * out. A list with no number at all is numbered 1, 2, … from the oldest.
     */
    fun placeNumbers(numbers: List<Double>): List<Double> {
        if (numbers.none { it >= 0 }) return numbers.indices.map { (numbers.size - it).toDouble() }
        val out = numbers.toMutableList()
        // Steps taken above each number, so two scanlators' "Extra" after
        // their own chapter 9 are 9.001 and 9.002, not both 9.001.
        val steps = HashMap<Double, Int>()
        var before = 0.0
        for (i in numbers.indices.reversed()) {
            if (numbers[i] >= 0) {
                before = numbers[i]
            } else {
                val step = steps.merge(before, 1, Int::plus)!!
                out[i] = Math.round((before + step * 0.001) * 1000) / 1000.0
            }
        }
        return out
    }

    private fun fromMatch(match: MatchResult): Double {
        val initial = match.groups[1]!!.value.toDouble()
        return initial + decimal(match.groups[2]?.value, match.groups[3]?.value)
    }

    private fun decimal(
        decimal: String?,
        alpha: String?,
    ): Double {
        if (!decimal.isNullOrEmpty()) return decimal.toDouble()
        if (!alpha.isNullOrEmpty()) {
            if (alpha.contains("extra")) return 0.99
            if (alpha.contains("omake")) return 0.98
            if (alpha.contains("special")) return 0.97
            val letter = alpha.trimStart('.')
            if (letter.length == 1) return alphaPostfix(letter[0])
        }
        return 0.0
    }

    /** "x.a" → x.1, …, "x.i" → x.9. */
    private fun alphaPostfix(alpha: Char): Double {
        val n = alpha.code - ('a'.code - 1)
        if (n >= 10) return 0.0
        return n / 10.0
    }
}
