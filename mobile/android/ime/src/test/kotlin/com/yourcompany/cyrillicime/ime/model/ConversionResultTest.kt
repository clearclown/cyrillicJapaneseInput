package com.yourcompany.cyrillicime.ime.model

import org.junit.Test
import org.junit.Assert.*
import kotlinx.serialization.json.Json

/**
 * Unit tests for ConversionResult data model
 */
class ConversionResultTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    @Test
    fun testConversionResultDeserialization() {
        val jsonString = """
            {
                "action": "commit",
                "output": "あ",
                "buffer": ""
            }
        """.trimIndent()

        val result = json.decodeFromString<ConversionResult>(jsonString)
        
        assertEquals("commit", result.action)
        assertEquals("あ", result.output)
        assertEquals("", result.buffer)
    }

    @Test
    fun testIsCommit() {
        val commitResult = ConversionResult(
            action = "commit",
            output = "あ",
            buffer = ""
        )

        assertTrue("Should be commit", commitResult.isCommit)
        assertFalse("Should not be composing", commitResult.isComposing)
        assertFalse("Should not be clear", commitResult.isClear)
    }

    @Test
    fun testIsComposing() {
        val composingResult = ConversionResult(
            action = "composing",
            output = "",
            buffer = "К"
        )

        assertFalse("Should not be commit", composingResult.isCommit)
        assertTrue("Should be composing", composingResult.isComposing)
        assertFalse("Should not be clear", composingResult.isClear)
    }

    @Test
    fun testIsClear() {
        val clearResult = ConversionResult(
            action = "clear",
            output = "",
            buffer = ""
        )

        assertFalse("Should not be commit", clearResult.isCommit)
        assertFalse("Should not be composing", clearResult.isComposing)
        assertTrue("Should be clear", clearResult.isClear)
    }

    @Test
    fun testCommitResultWithOutput() {
        val result = ConversionResult(
            action = "commit",
            output = "きゃ",
            buffer = ""
        )

        assertTrue(result.isCommit)
        assertEquals("きゃ", result.output)
        assertTrue(result.buffer.isEmpty())
    }

    @Test
    fun testComposingResultWithBuffer() {
        val result = ConversionResult(
            action = "composing",
            output = "",
            buffer = "КЯ"
        )

        assertTrue(result.isComposing)
        assertEquals("КЯ", result.buffer)
        assertTrue(result.output.isEmpty())
    }

    @Test
    fun testUnknownAction() {
        val result = ConversionResult(
            action = "unknown",
            output = "",
            buffer = ""
        )

        assertFalse("Should not be commit", result.isCommit)
        assertFalse("Should not be composing", result.isComposing)
        assertFalse("Should not be clear", result.isClear)
    }
}
