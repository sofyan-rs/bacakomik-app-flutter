package org.kurodev.bacakomik.mihon

import org.junit.Assert.assertEquals
import org.junit.Test

class ChapterRecognitionTest {
    private fun n(
        name: String,
        title: String = "",
        given: Double = -1.0,
    ) = ChapterRecognition.parseChapterNumber(title, name, given)

    @Test
    fun givenNumberWins() = assertEquals(12.0, n("Chapter 99", given = 12.0), 0.0)

    @Test
    fun readsTheName() {
        assertEquals(345.0, n("Chapter 345"), 0.0)
        assertEquals(10.5, n("Ch. 10.5"), 0.0)
        assertEquals(3.0, n("Vol.2 Ch.3"), 0.0)
        assertEquals(5.99, n("Chapter 5 extra"), 0.0001)
        assertEquals(4.0, n("Solo Leveling 2 Chapter 4", title = "Solo Leveling 2"), 0.0)
    }

    @Test
    fun noNumber() = assertEquals(-1.0, n("Prologue"), 0.0)

    @Test
    fun unnumberedChaptersGoJustAboveTheOneBefore() =
        assertEquals(
            listOf(10.0, 9.002, 9.001, 9.0, 0.001),
            ChapterRecognition.placeNumbers(listOf(10.0, -1.0, -1.0, 9.0, -1.0)),
        )

    @Test
    fun noNumbersAtAllAreNumberedInOrder() =
        assertEquals(listOf(2.0, 1.0), ChapterRecognition.placeNumbers(listOf(-1.0, -1.0)))

    @Test
    fun interleavedScanlatorsGetTheirOwnNumbers() =
        assertEquals(
            listOf(9.002, 9.0, 9.001, 9.0),
            ChapterRecognition.placeNumbers(listOf(-1.0, 9.0, -1.0, 9.0)),
        )
}
