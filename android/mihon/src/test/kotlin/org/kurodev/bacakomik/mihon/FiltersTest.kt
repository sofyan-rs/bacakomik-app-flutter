package org.kurodev.bacakomik.mihon

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FiltersTest {
    private fun tree(text: String) = Json.parseToJsonElement(text).jsonArray

    @Test
    fun newestSortIsDescending() {
        // Asura: Sort by Latest Update, Popular, Rating, A-Z, Newest.
        val t = tree("""[{"name":"Status","type":"select","values":["All"],"state":0},{"name":"Sort By","type":"sort","values":["Latest Update","Popular","Rating","A-Z","Newest"],"state":{"index":0,"ascending":false}}]""")
        assertEquals("""{"f1":["4:d"]}""", Filters.newest(t).toString())
    }

    @Test
    fun newestOptionOfASortSelect() {
        val t = tree("""[{"name":"Order by","type":"select","values":["Popular","Recently Added"],"state":0}]""")
        assertEquals("""{"f0":["1"]}""", Filters.newest(t).toString())
    }

    @Test
    fun latestUpdateIsNotNewest() {
        val t = tree("""[{"name":"Sort","type":"sort","values":["Latest Update","Popular"],"state":null},{"name":"Type","type":"select","values":["New"],"state":0}]""")
        assertNull(Filters.newest(t))
    }
}
