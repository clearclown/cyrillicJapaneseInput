package com.yourcompany.cyrillicime.ime.model

import org.junit.Test
import org.junit.Assert.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString

/**
 * Unit tests for Profile data model
 */
class ProfileTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    @Test
    fun testProfileSerialization() {
        val profile = Profile(
            id = "rus_standard",
            nameJa = "ロシア語 (標準)",
            nameEn = "Russian (Standard)",
            keyboardLayout = listOf("А", "И", "У"),
            inputSchemaId = "schema_rus_v1"
        )

        val jsonString = json.encodeToString(profile)
        assertNotNull("JSON should not be null", jsonString)
        assertTrue("JSON should contain id", jsonString.contains("rus_standard"))
    }

    @Test
    fun testProfileDeserialization() {
        val jsonString = """
            {
                "id": "rus_standard",
                "name_ja": "ロシア語",
                "name_en": "Russian",
                "keyboardLayout": ["А", "Б", "В"],
                "inputSchemaId": "schema_rus_v1"
            }
        """.trimIndent()

        val profile = json.decodeFromString<Profile>(jsonString)
        
        assertEquals("rus_standard", profile.id)
        assertEquals("ロシア語", profile.nameJa)
        assertEquals("Russian", profile.nameEn)
        assertEquals(3, profile.keyboardLayout.size)
        assertEquals("schema_rus_v1", profile.inputSchemaId)
    }

    @Test
    fun testGetDisplayNameJapanese() {
        val profile = Profile(
            id = "test",
            nameJa = "テスト",
            nameEn = "Test",
            keyboardLayout = emptyList(),
            inputSchemaId = "schema_test"
        )

        val displayName = profile.getDisplayName("ja")
        assertEquals("テスト", displayName)
    }

    @Test
    fun testGetDisplayNameEnglish() {
        val profile = Profile(
            id = "test",
            nameJa = "テスト",
            nameEn = "Test",
            keyboardLayout = emptyList(),
            inputSchemaId = "schema_test"
        )

        val displayName = profile.getDisplayName("en")
        assertEquals("Test", displayName)
    }

    @Test
    fun testKeyboardLayoutNotEmpty() {
        val profile = Profile(
            id = "rus_standard",
            nameJa = "ロシア語",
            nameEn = "Russian",
            keyboardLayout = listOf("А", "Б", "В", "Г", "Д"),
            inputSchemaId = "schema_rus_v1"
        )

        assertFalse("Keyboard layout should not be empty", profile.keyboardLayout.isEmpty())
        assertEquals(5, profile.keyboardLayout.size)
    }

    @Test
    fun testProfileEquality() {
        val profile1 = Profile(
            id = "rus",
            nameJa = "ロシア語",
            nameEn = "Russian",
            keyboardLayout = listOf("А"),
            inputSchemaId = "schema_rus_v1"
        )

        val profile2 = Profile(
            id = "rus",
            nameJa = "ロシア語",
            nameEn = "Russian",
            keyboardLayout = listOf("А"),
            inputSchemaId = "schema_rus_v1"
        )

        assertEquals("Profiles with same data should be equal", profile1, profile2)
    }
}
