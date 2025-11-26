/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Instrumented tests for KanjiConverter
 */
package com.pismo.keyboard.converter

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Instrumented tests for KanjiConverter.
 *
 * Tests cover:
 * - Dictionary loading
 * - Single kanji conversion
 * - Word/phrase conversion
 * - Candidate generation
 * - Katakana conversion
 * - Edge cases
 */
@RunWith(AndroidJUnit4::class)
class KanjiConverterTest {

    private lateinit var converter: KanjiConverter

    @Before
    fun setUp() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        converter = KanjiConverter(context)

        // Wait for dictionaries to load
        val latch = CountDownLatch(1)
        converter.loadDictionaries {
            latch.countDown()
        }
        assertTrue("Dictionary loading timed out", latch.await(30, TimeUnit.SECONDS))
        assertTrue("Dictionary should be ready", converter.isReady())
    }

    // ==================== Dictionary Loading Tests ====================

    @Test
    fun testDictionaryLoading() {
        assertTrue("Converter should be ready after loading", converter.isReady())
    }

    @Test
    fun testMultipleLoadCalls() {
        // Calling load again should not cause issues
        val latch = CountDownLatch(1)
        converter.loadDictionaries {
            latch.countDown()
        }
        assertTrue(latch.await(5, TimeUnit.SECONDS))
        assertTrue(converter.isReady())
    }

    // ==================== Single Kanji Tests ====================

    @Test
    fun testSingleKanjiConversion_A() {
        val candidates = converter.getCandidates("あ")
        assertTrue("Should have candidates for あ", candidates.isNotEmpty())
        // First candidate should be the original
        assertEquals("あ", candidates[0])
        // Should have kanji candidates
        assertTrue("Should have multiple candidates", candidates.size > 1)
    }

    @Test
    fun testSingleKanjiConversion_Ai() {
        val candidates = converter.getCandidates("あい")
        assertTrue("Should have candidates for あい", candidates.isNotEmpty())
        // Should include 愛 among candidates
        assertTrue("Should include 愛", candidates.any { it == "愛" || it.contains("愛") })
    }

    @Test
    fun testSingleKanjiConversion_Hi() {
        val candidates = converter.getCandidates("ひ")
        assertTrue("Should have candidates for ひ", candidates.isNotEmpty())
        assertTrue("Should have kanji like 日 or 火", candidates.size > 1)
    }

    // ==================== Word Conversion Tests ====================

    @Test
    fun testWordConversion_Nihon() {
        val candidates = converter.getCandidates("にほん")
        assertTrue("Should have candidates for にほん", candidates.isNotEmpty())
        // Should include 日本 among candidates
        assertTrue("Should include 日本", candidates.any { it == "日本" })
    }

    @Test
    fun testWordConversion_Tokyo() {
        val candidates = converter.getCandidates("とうきょう")
        assertTrue("Should have candidates for とうきょう", candidates.isNotEmpty())
        // Should include 東京 among candidates
        assertTrue("Should include 東京", candidates.any { it == "東京" })
    }

    @Test
    fun testWordConversion_Sakura() {
        val candidates = converter.getCandidates("さくら")
        assertTrue("Should have candidates for さくら", candidates.isNotEmpty())
        // Should include 桜 among candidates
        assertTrue("Should include 桜", candidates.any { it == "桜" })
    }

    @Test
    fun testWordConversion_Densha() {
        val candidates = converter.getCandidates("でんしゃ")
        assertTrue("Should have candidates for でんしゃ", candidates.isNotEmpty())
        // Should include 電車 among candidates
        assertTrue("Should include 電車", candidates.any { it == "電車" })
    }

    @Test
    fun testWordConversion_Watashi() {
        val candidates = converter.getCandidates("わたし")
        assertTrue("Should have candidates for わたし", candidates.isNotEmpty())
        // Should include 私 among candidates
        assertTrue("Should include 私", candidates.any { it == "私" })
    }

    @Test
    fun testWordConversion_Gakkou() {
        val candidates = converter.getCandidates("がっこう")
        assertTrue("Should have candidates for がっこう", candidates.isNotEmpty())
        // Should include 学校 among candidates
        assertTrue("Should include 学校", candidates.any { it == "学校" })
    }

    // ==================== Katakana Conversion Tests ====================

    @Test
    fun testKatakanaConversion_A() {
        val candidates = converter.getCandidates("あ")
        assertTrue("Should include katakana ア", candidates.contains("ア"))
    }

    @Test
    fun testKatakanaConversion_Word() {
        val candidates = converter.getCandidates("こんぴゅーたー")
        // Should include katakana version
        assertTrue("Should include katakana", candidates.any {
            it.all { c -> c.code in 0x30A0..0x30FF || c == 'ー' }
        })
    }

    // ==================== ConvertToBest Tests ====================

    @Test
    fun testConvertToBest_Nihon() {
        val result = converter.convertToBest("にほん")
        assertEquals("日本", result)
    }

    @Test
    fun testConvertToBest_NoMatch() {
        val result = converter.convertToBest("xyzabc")
        // Should return original if no match
        assertEquals("xyzabc", result)
    }

    @Test
    fun testConvertToBest_EmptyString() {
        val result = converter.convertToBest("")
        assertEquals("", result)
    }

    // ==================== ConvertWithSegmentation Tests ====================

    @Test
    fun testConvertWithSegmentation_Simple() {
        val result = converter.convertWithSegmentation("にほん")
        assertEquals("日本", result)
    }

    @Test
    fun testConvertWithSegmentation_Mixed() {
        val result = converter.convertWithSegmentation("にほんご")
        // Should convert whole word if exists, or segment it
        assertTrue(result.contains("日本"))
    }

    // ==================== Prefix Matching Tests ====================

    @Test
    fun testCandidatesWithPrefix_Ni() {
        val results = converter.getCandidatesWithPrefix("に")
        assertTrue("Should have prefix matches", results.isNotEmpty())

        // Should have exact match for に
        val exactMatch = results.find { it.first == "に" }
        assertNotNull("Should have exact match", exactMatch)
    }

    @Test
    fun testCandidatesWithPrefix_Niho() {
        val results = converter.getCandidatesWithPrefix("にほ")
        assertTrue("Should have prefix matches for にほ", results.isNotEmpty())

        // Should include にほん as one of the matches
        val hasNihon = results.any { it.first == "にほん" }
        assertTrue("Should include にほん reading", hasNihon)
    }

    // ==================== Edge Cases ====================

    @Test
    fun testEmptyInput() {
        val candidates = converter.getCandidates("")
        assertTrue("Empty input should return empty list", candidates.isEmpty())
    }

    @Test
    fun testVeryLongInput() {
        val longInput = "あ".repeat(100)
        val candidates = converter.getCandidates(longInput)
        // Should not crash, may or may not have candidates
        assertNotNull(candidates)
    }

    @Test
    fun testNonHiraganaInput() {
        val candidates = converter.getCandidates("abc")
        // Should handle gracefully
        assertNotNull(candidates)
    }

    @Test
    fun testMixedInput() {
        val candidates = converter.getCandidates("あaい")
        // Should handle gracefully
        assertNotNull(candidates)
    }

    @Test
    fun testSpecialCharacters() {
        val candidates = converter.getCandidates("ー")
        assertNotNull(candidates)
    }

    // ==================== Common Word Tests ====================

    @Test
    fun testCommonWord_Arigatou() {
        val candidates = converter.getCandidates("ありがとう")
        assertTrue("Should have candidates", candidates.isNotEmpty())
    }

    @Test
    fun testCommonWord_Konnichiwa() {
        val candidates = converter.getCandidates("こんにちは")
        assertTrue("Should have candidates", candidates.isNotEmpty())
    }

    @Test
    fun testCommonWord_Ohayou() {
        val candidates = converter.getCandidates("おはよう")
        assertTrue("Should have candidates", candidates.isNotEmpty())
    }

    @Test
    fun testCommonWord_Sumimasen() {
        val candidates = converter.getCandidates("すみません")
        assertTrue("Should have candidates", candidates.isNotEmpty())
    }

    @Test
    fun testCommonWord_Taberu() {
        val candidates = converter.getCandidates("たべる")
        assertTrue("Should have candidates for たべる", candidates.isNotEmpty())
        assertTrue("Should include 食べる", candidates.any { it == "食べる" })
    }

    @Test
    fun testCommonWord_Nomu() {
        val candidates = converter.getCandidates("のむ")
        assertTrue("Should have candidates for のむ", candidates.isNotEmpty())
        assertTrue("Should include 飲む", candidates.any { it == "飲む" })
    }

    @Test
    fun testCommonWord_Iku() {
        val candidates = converter.getCandidates("いく")
        assertTrue("Should have candidates for いく", candidates.isNotEmpty())
        assertTrue("Should include 行く", candidates.any { it == "行く" })
    }

    @Test
    fun testCommonWord_Kuru() {
        val candidates = converter.getCandidates("くる")
        assertTrue("Should have candidates for くる", candidates.isNotEmpty())
        assertTrue("Should include 来る", candidates.any { it == "来る" })
    }

    @Test
    fun testCommonWord_Suru() {
        val candidates = converter.getCandidates("する")
        assertTrue("Should have candidates for する", candidates.isNotEmpty())
    }

    // ==================== Number Conversion Tests ====================

    @Test
    fun testNumber_Ichi() {
        val candidates = converter.getCandidates("いち")
        assertTrue("Should have candidates for いち", candidates.isNotEmpty())
        assertTrue("Should include 一", candidates.any { it == "一" })
    }

    @Test
    fun testNumber_Ni() {
        val candidates = converter.getCandidates("に")
        assertTrue("Should have candidates for に", candidates.isNotEmpty())
        assertTrue("Should include 二", candidates.any { it == "二" })
    }

    @Test
    fun testNumber_San() {
        val candidates = converter.getCandidates("さん")
        assertTrue("Should have candidates for さん", candidates.isNotEmpty())
        assertTrue("Should include 三", candidates.any { it == "三" })
    }

    // ==================== Time/Date Word Tests ====================

    @Test
    fun testTimeWord_Ima() {
        val candidates = converter.getCandidates("いま")
        assertTrue("Should have candidates for いま", candidates.isNotEmpty())
        assertTrue("Should include 今", candidates.any { it == "今" })
    }

    @Test
    fun testTimeWord_Kyou() {
        val candidates = converter.getCandidates("きょう")
        assertTrue("Should have candidates for きょう", candidates.isNotEmpty())
        assertTrue("Should include 今日", candidates.any { it == "今日" })
    }

    @Test
    fun testTimeWord_Ashita() {
        val candidates = converter.getCandidates("あした")
        assertTrue("Should have candidates for あした", candidates.isNotEmpty())
        assertTrue("Should include 明日", candidates.any { it == "明日" })
    }

    // ==================== Place Name Tests ====================

    @Test
    fun testPlace_Osaka() {
        val candidates = converter.getCandidates("おおさか")
        assertTrue("Should have candidates for おおさか", candidates.isNotEmpty())
        assertTrue("Should include 大阪", candidates.any { it == "大阪" })
    }

    @Test
    fun testPlace_Kyoto() {
        val candidates = converter.getCandidates("きょうと")
        assertTrue("Should have candidates for きょうと", candidates.isNotEmpty())
        assertTrue("Should include 京都", candidates.any { it == "京都" })
    }
}
