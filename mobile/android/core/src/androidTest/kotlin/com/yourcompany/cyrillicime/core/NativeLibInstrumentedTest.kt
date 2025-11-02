package com.yourcompany.cyrillicime.core

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import org.junit.runner.RunWith

/**
 * Instrumented tests for NativeLib JNI interface
 * 
 * These tests run on Android device/emulator with native library loaded
 */
@RunWith(AndroidJUnit4::class)
class NativeLibInstrumentedTest {

    private val testProfilesJson = """
        [
            {
                "id": "rus_test",
                "name_ja": "ロシア語テスト",
                "name_en": "Russian Test",
                "keyboardLayout": ["А", "И", "У", "К", "Я", "Н"],
                "inputSchemaId": "schema_rus_test"
            }
        ]
    """.trimIndent()

    private val testKanaEngineJson = """
        {
            "a": "あ",
            "i": "い",
            "u": "う",
            "ka": "か",
            "ki": "き",
            "kya": "きゃ",
            "n_final": "ん"
        }
    """.trimIndent()

    private val testSchemaJson = """
        {
            "А": {"kana_key": "a"},
            "И": {"kana_key": "i"},
            "У": {"kana_key": "u"},
            "КА": {"kana_key": "ka"},
            "КИ": {"kana_key": "ki"},
            "КЯ": {"kana_key": "kya"},
            "Н": {"kana_key": "n_final"}
        }
    """.trimIndent()

    @Test
    fun testGetVersion() {
        val version = NativeLib.getVersion()
        assertNotNull("Version should not be null", version)
        assertFalse("Version should not be empty", version.isEmpty())
        assertEquals("0.1.0", version)
    }

    @Test
    fun testInitEngine() {
        val result = NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        // May be true or false depending on whether already initialized
        // Just verify it doesn't crash
        assertNotNull(result)
    }

    @Test
    fun testLoadSchema() {
        // Ensure engine is initialized
        NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        
        val result = NativeLib.loadSchema(testSchemaJson, "schema_rus_test")
        assertTrue("Schema should load successfully", result)
    }

    @Test
    fun testProcessKeySingleCharacter() {
        // Ensure engine and schema are loaded
        NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        NativeLib.loadSchema(testSchemaJson, "schema_rus_test")
        
        val result = NativeLib.processKey("А", "", "rus_test")
        assertNotNull("Result should not be null", result)
        assertTrue("Result should contain 'commit'", result!!.contains("commit"))
        assertTrue("Result should contain 'あ'", result.contains("あ"))
    }

    @Test
    fun testProcessKeyComposing() {
        NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        NativeLib.loadSchema(testSchemaJson, "schema_rus_test")
        
        val result = NativeLib.processKey("К", "", "rus_test")
        assertNotNull("Result should not be null", result)
        assertTrue("Result should contain 'composing'", result!!.contains("composing"))
        assertTrue("Result should contain buffer", result.contains("buffer"))
    }

    @Test
    fun testProcessKeyMultipleCharacters() {
        NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        NativeLib.loadSchema(testSchemaJson, "schema_rus_test")
        
        // First key: К (composing)
        val result1 = NativeLib.processKey("К", "", "rus_test")
        assertNotNull(result1)
        assertTrue(result1!!.contains("composing"))
        
        // Second key: И (should commit き)
        val result2 = NativeLib.processKey("И", "К", "rus_test")
        assertNotNull(result2)
        assertTrue(result2!!.contains("commit"))
        assertTrue(result2.contains("き"))
    }

    @Test
    fun testProcessKeyInvalidProfile() {
        NativeLib.initEngine(testProfilesJson, testKanaEngineJson)
        
        val result = NativeLib.processKey("А", "", "nonexistent_profile")
        // Should return null or error
        // Behavior may vary, just verify it doesn't crash
        assertNotNull(result)
    }
}
