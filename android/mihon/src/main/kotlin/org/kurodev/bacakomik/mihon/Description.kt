package org.kurodev.bacakomik.mihon

/**
 * Mihon has no fields for alternative titles or a rating, so extensions put
 * them in the description ("Alternative Titles: …", Asura's "Rank: #1 •
 * Rating: 9.13 • Bookmarks: 64.0K"). The app has fields for both: this
 * takes them out of the synopsis.
 */
object Description {
    class Parsed(
        val synopsis: String?,
        val altTitles: List<String>,
        val rating: Double?,
    )

    /** A line naming other titles; group 1 is the rest of the line. */
    private val altHeader =
        Regex(
            """^[\s*•\-#]*(?:alternative\s+(?:titles?|names?)|alt(?:ernate)?\.?\s*(?:titles?|names?)|other\s+(?:titles?|names?)|associated\s+names?|also\s+known\s+as|a\.?k\.?a\.?|synonyms?|judul\s+(?:alternatif|lain)|nama\s+lain)\s*[:：]\s*(.*)$""",
            RegexOption.IGNORE_CASE,
        )

    // A label with its colon ("Rating: 9.13"), so "rating 18+" in a sentence is no score.
    private val rating = Regex("""\b(?:rating|score)\s*[:：]\s*([0-9]+(?:[.,][0-9]+)?)""", RegexOption.IGNORE_CASE)

    /** Separators that never appear inside a title (the app's alt_titles.dart). */
    private val strong = Regex("""\s*(?:[•|;]|\s/\s)\s*""")

    fun parse(text: String?): Parsed {
        if (text.isNullOrBlank()) return Parsed(null, emptyList(), null)
        val lines = text.replace("\r\n", "\n").replace('\r', '\n').split('\n')
        val kept = mutableListOf<String>()
        val alts = mutableListOf<String>()
        var score: Double? = null
        var i = 0
        while (i < lines.size) {
            val line = lines[i]
            val header = altHeader.find(line)
            if (header != null) {
                val rest = header.groupValues[1].trim()
                if (rest.isNotEmpty()) {
                    alts += split(rest)
                } else {
                    // The titles follow, one block up to a blank line or
                    // the first line that reads like the story.
                    while (i + 1 < lines.size && lines[i + 1].isNotBlank() && !isProse(lines[i + 1])) alts += split(lines[++i].trim())
                }
                i++
                continue
            }
            val found = rating.find(line)
            if (found != null && score == null && isStats(line)) {
                score = found.groupValues[1].replace(',', '.').toDoubleOrNull()
                i++
                continue
            }
            kept += line
            i++
        }
        val synopsis =
            kept
                .joinToString("\n")
                // Markdown bold ("**Parodies**: original", nhentai); the app shows plain text.
                .replace(Regex("""(\*\*|__)(.+?)\1"""), "$2")
                .replace(Regex("""\n{3,}"""), "\n\n")
                .trim()
                .ifEmpty { null }
        // List bullets ("- 템빨", Asura) are not part of a title.
        val titles = alts.map { it.trim().trimStart('-', '*', '•', '–', ' ').trim().trim(',', '.') }
        return Parsed(synopsis, titles.filter { it.isNotEmpty() }.distinct(), score)
    }

    /** A short line of numbers ("Rank: #1 • Rating: 9.13"), not a sentence of the story. */
    private fun isStats(line: String): Boolean {
        val t = line.trim()
        return t.length <= 160 && (t.contains('•') || t.contains('|') || Regex("""^[\s*•\-]*(?:rating|score|rank)\b""", RegexOption.IGNORE_CASE).containsMatchIn(t))
    }

    /** A sentence rather than a title: long, or many words ending in a full stop. */
    private fun isProse(line: String): Boolean {
        val t = line.trim()
        return t.length > 120 || (t.endsWith('.') && t.split(Regex("""\s+""")).size > 6)
    }

    /** Strong separators first; `, ` only when there are none (titles hold commas). */
    private fun split(text: String): List<String> =
        if (strong.containsMatchIn(text)) text.split(strong) else text.split(Regex(""",\s+"""))
}
