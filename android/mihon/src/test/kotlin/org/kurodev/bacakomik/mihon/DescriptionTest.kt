package org.kurodev.bacakomik.mihon

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DescriptionTest {
    @Test
    fun asuraStatsLineBecomesTheRating() {
        val d = Description.parse("Rank: #1 • Rating: 9.13 • Bookmarks: 64.0K\n\nShin Youngwoo, an unlucky man.")
        assertEquals(9.13, d.rating!!, 0.0001)
        assertEquals("Shin Youngwoo, an unlucky man.", d.synopsis)
    }

    @Test
    fun altTitlesOnTheirLine() {
        val d = Description.parse("A story.\n\nAlternative Titles: 전지적 독자 시점 • Omniscient Reader")
        assertEquals(listOf("전지적 독자 시점", "Omniscient Reader"), d.altTitles)
        assertEquals("A story.", d.synopsis)
    }

    @Test
    fun altTitlesInABlockSplitOnCommasOnlyWithoutStrongSeparators() {
        val d = Description.parse("Story.\n\nAlternative Names:\nSolo Leveling, Na Honjaman Level Up\n\nMore.")
        assertEquals(listOf("Solo Leveling", "Na Honjaman Level Up"), d.altTitles)
        assertEquals("Story.\n\nMore.", d.synopsis)
    }

    @Test
    fun bulletsAreNotPartOfTitles() {
        val d = Description.parse("Alternative Titles:\n- 템빨\n- Over Geared\n\nStory.")
        assertEquals(listOf("템빨", "Over Geared"), d.altTitles)
    }

    @Test
    fun aSentenceMentioningARatingStays() {
        val text = "Her rating 5 in the guild was the lowest of all the members who joined that year and she knew it."
        val d = Description.parse(text)
        assertNull(d.rating)
        assertEquals(text, d.synopsis)
    }

    @Test
    fun markdownBoldIsDropped() =
        assertEquals("Parodies: original", Description.parse("**Parodies**: original").synopsis)

    @Test
    fun anAltBlockStopsAtTheStory() {
        val d = Description.parse("Other names:\nFoo\nIn a world where heroes fall, one boy rises to fight back.")
        assertEquals(listOf("Foo"), d.altTitles)
        assertEquals("In a world where heroes fall, one boy rises to fight back.", d.synopsis)
    }

    @Test
    fun aStoryLineStartingWithRankStays() {
        val text = "Rank S hunter, score 99 on every test."
        val d = Description.parse(text)
        assertNull(d.rating)
        assertEquals(text, d.synopsis)
    }

    @Test
    fun aStarLineIsTheRating() {
        val d = Description.parse("★★★★★ 9.8\n\nMori, a child found by a rescue team.")
        assertEquals(9.8, d.rating!!, 0.0001)
        assertEquals("Mori, a child found by a rescue team.", d.synopsis)
    }
}
