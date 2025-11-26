/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Integration tests for the full input flow
 */
package com.pismo.keyboard

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.pismo.keyboard.converter.CyrillicKanaConverter
import com.pismo.keyboard.converter.KanjiConverter
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Integration tests for the full Cyrillic → Hiragana → Kanji conversion flow.
 *
 * These tests verify that:
 * 1. Cyrillic input correctly converts to hiragana
 * 2. Hiragana correctly produces kanji candidates
 * 3. The full pipeline works end-to-end
 */
@RunWith(AndroidJUnit4::class)
class IntegrationTest {

    private lateinit var cyrillicConverter: CyrillicKanaConverter
    private lateinit var kanjiConverter: KanjiConverter

    @Before
    fun setUp() {
        cyrillicConverter = CyrillicKanaConverter()

        val context = InstrumentationRegistry.getInstrumentation().targetContext
        kanjiConverter = KanjiConverter(context)

        // Wait for dictionaries to load
        val latch = CountDownLatch(1)
        kanjiConverter.loadDictionaries {
            latch.countDown()
        }
        assertTrue("Dictionary loading timed out", latch.await(30, TimeUnit.SECONDS))
    }

    // ==================== Full Pipeline Tests ====================

    @Test
    fun testFullPipeline_Nihon() {
        // Input: НиХоН → にほん → 日本
        val cyrillic = "НиХоН"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("にほん", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should have candidates for にほん", candidates.isNotEmpty())
        assertTrue("Should include 日本", candidates.contains("日本"))
    }

    @Test
    fun testFullPipeline_Tokyo() {
        // Input: ТоУКёУ → とうきょう → 東京
        val cyrillic = "ТоУКёУ"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("とうきょう", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 東京", candidates.contains("東京"))
    }

    @Test
    fun testFullPipeline_Sakura() {
        // Input: СаКуРа → さくら → 桜
        val cyrillic = "СаКуРа"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("さくら", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 桜", candidates.contains("桜"))
    }

    @Test
    fun testFullPipeline_Densha() {
        // Input: ДэНСя → でんしゃ → 電車
        val cyrillic = "ДэНСя"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("でんしゃ", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 電車", candidates.contains("電車"))
    }

    @Test
    fun testFullPipeline_Gakkou() {
        // Input: ГаККоУ → がっこう → 学校
        val cyrillic = "ГаККоУ"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("がっこう", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 学校", candidates.contains("学校"))
    }

    @Test
    fun testFullPipeline_Watashi() {
        // Input: ВаТаСи → わたし → 私
        val cyrillic = "ВаТаСи"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("わたし", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 私", candidates.contains("私"))
    }

    @Test
    fun testFullPipeline_Ai() {
        // Input: АИ → あい → 愛
        val cyrillic = "АИ"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("あい", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 愛", candidates.any { it == "愛" || it.contains("愛") })
    }

    @Test
    fun testFullPipeline_Taberu() {
        // Input: ТаБэРу → たべる → 食べる
        val cyrillic = "ТаБэРу"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("たべる", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 食べる", candidates.contains("食べる"))
    }

    @Test
    fun testFullPipeline_Nomu() {
        // Input: Ному → のむ → 飲む
        val cyrillic = "Ному"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("のむ", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 飲む", candidates.contains("飲む"))
    }

    @Test
    fun testFullPipeline_Iku() {
        // Input: ИКу → いく → 行く
        val cyrillic = "ИКу"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("いく", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 行く", candidates.contains("行く"))
    }

    // ==================== Youon (拗音) Integration Tests ====================

    @Test
    fun testFullPipeline_Kyoto() {
        // Input: КёУТо → きょうと → 京都
        val cyrillic = "КёУТо"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("きょうと", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 京都", candidates.contains("京都"))
    }

    @Test
    fun testFullPipeline_Chuugoku() {
        // Input: ЧуУГоКу → ちゅうごく → 中国
        val cyrillic = "ЧуУГоКу"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("ちゅうごく", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 中国", candidates.contains("中国"))
    }

    // ==================== Dakuon (濁音) Integration Tests ====================

    @Test
    fun testFullPipeline_Gogo() {
        // Input: ГоГо → ごご → 午後
        val cyrillic = "ГоГо"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("ごご", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 午後", candidates.contains("午後"))
    }

    @Test
    fun testFullPipeline_Gozen() {
        // Input: ГоДзэН → ごぜん → 午前
        val cyrillic = "ГоДзэН"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("ごぜん", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 午前", candidates.contains("午前"))
    }

    // ==================== Sokuon (促音) Integration Tests ====================

    @Test
    fun testFullPipeline_Kitte() {
        // Input: КиТТэ → きって → 切手
        val cyrillic = "КиТТэ"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("きって", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 切手", candidates.contains("切手"))
    }

    @Test
    fun testFullPipeline_Zasshi() {
        // Input: ДзаССи → ざっし → 雑誌
        val cyrillic = "ДзаССи"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("ざっし", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 雑誌", candidates.contains("雑誌"))
    }

    // ==================== N Before Consonant Integration Tests ====================

    @Test
    fun testFullPipeline_Sanka() {
        // Input: СаНКа → さんか → 参加
        val cyrillic = "СаНКа"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("さんか", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 参加", candidates.contains("参加"))
    }

    @Test
    fun testFullPipeline_Konnichi() {
        // Input: КоННиЧи → こんにち → (for こんにちは)
        val cyrillic = "КоННиЧи"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("こんにち", hiragana)

        // Check prefix matching works
        val prefixResults = kanjiConverter.getCandidatesWithPrefix(hiragana)
        assertTrue("Should have prefix matches", prefixResults.isNotEmpty())
    }

    // ==================== Numbers Integration Tests ====================

    @Test
    fun testFullPipeline_Ichi() {
        // Input: ИЧи → いち → 一
        val cyrillic = "ИЧи"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("いち", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 一", candidates.contains("一"))
    }

    @Test
    fun testFullPipeline_Ni() {
        // Input: Ни → に → 二
        val cyrillic = "Ни"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("に", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 二", candidates.contains("二"))
    }

    @Test
    fun testFullPipeline_San() {
        // Input: СаН → さん → 三
        val cyrillic = "СаН"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("さん", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 三", candidates.contains("三"))
    }

    // ==================== Profile Tests ====================

    @Test
    fun testFullPipeline_UkrainianProfile_Nihon() {
        cyrillicConverter.setProfile(CyrillicKanaConverter.Profile.UKRAINIAN)
        // Input using Ukrainian И → І
        val cyrillic = "НіХоН"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        assertEquals("にほん", hiragana)

        val candidates = kanjiConverter.getCandidates(hiragana)
        assertTrue("Should include 日本", candidates.contains("日本"))
    }

    // ==================== Incremental Input Simulation ====================

    @Test
    fun testIncrementalInput_Nihon() {
        // Simulate character-by-character input
        val buffer = StringBuilder()

        // Н
        cyrillicConverter.clearBuffer()
        var result = cyrillicConverter.processInput('Н')
        // Buffer should contain Н
        assertTrue(cyrillicConverter.getComposingText().isNotEmpty())

        // Ни → に
        result = cyrillicConverter.processInput('и')
        if (result.committed.isNotEmpty()) {
            buffer.append(result.committed)
        }

        // Х
        result = cyrillicConverter.processInput('Х')

        // Хо → ほ
        result = cyrillicConverter.processInput('о')
        if (result.committed.isNotEmpty()) {
            buffer.append(result.committed)
        }

        // Н at end - flush
        result = cyrillicConverter.processInput('Н')
        buffer.append(cyrillicConverter.flush())

        assertEquals("にほん", buffer.toString())

        // Now convert to kanji
        val candidates = kanjiConverter.getCandidates(buffer.toString())
        assertTrue("Should include 日本", candidates.contains("日本"))
    }

    // ==================== ConvertToBest Integration Tests ====================

    @Test
    fun testConvertToBest_FullPipeline_Nihon() {
        val cyrillic = "НиХоН"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        val best = kanjiConverter.convertToBest(hiragana)
        assertEquals("日本", best)
    }

    @Test
    fun testConvertToBest_FullPipeline_Tokyo() {
        val cyrillic = "ТоУКёУ"
        val hiragana = convertCyrillicToHiragana(cyrillic)
        val best = kanjiConverter.convertToBest(hiragana)
        assertEquals("東京", best)
    }

    // ==================== Helper Methods ====================

    private fun convertCyrillicToHiragana(cyrillic: String): String {
        cyrillicConverter.clearBuffer()
        cyrillicConverter.processInput(cyrillic)
        return cyrillicConverter.flush()
    }
}
