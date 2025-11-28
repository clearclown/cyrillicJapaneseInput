/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Unit tests for CyrillicKanaConverter
 */
package com.pismo.keyboard.converter

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Comprehensive unit tests for CyrillicKanaConverter.
 *
 * Tests cover:
 * - Seion (清音) - Basic kana
 * - Dakuon (濁音) - Voiced consonants
 * - Handakuon (半濁音) - Semi-voiced consonants
 * - Youon (拗音) - Combined sounds
 * - Gairaigo (外来語) - Foreign loan word sounds
 * - Small kana (小書き仮名)
 * - Sokuon (促音) - Double consonants
 * - Long vowels
 * - N (ん) handling
 * - Multiple profiles
 */
class CyrillicKanaConverterTest {

    private lateinit var converter: CyrillicKanaConverter

    @Before
    fun setUp() {
        converter = CyrillicKanaConverter()
        converter.clearBuffer()
    }

    // ==================== Seion (清音) Tests ====================

    @Test
    fun `test vowels conversion`() {
        // A, I, U, E, O
        assertEquals("あ", processAndFlush("А"))
        assertEquals("い", processAndFlush("И"))
        assertEquals("う", processAndFlush("У"))
        assertEquals("え", processAndFlush("Э"))
        assertEquals("お", processAndFlush("О"))
    }

    @Test
    fun `test K-row conversion`() {
        assertEquals("か", processAndFlush("Ка"))
        assertEquals("き", processAndFlush("Ки"))
        assertEquals("く", processAndFlush("Ку"))
        assertEquals("け", processAndFlush("Кэ"))
        assertEquals("こ", processAndFlush("Ко"))
    }

    @Test
    fun `test S-row conversion`() {
        assertEquals("さ", processAndFlush("Са"))
        assertEquals("し", processAndFlush("Си"))
        assertEquals("す", processAndFlush("Су"))
        assertEquals("せ", processAndFlush("Сэ"))
        assertEquals("そ", processAndFlush("Со"))
    }

    @Test
    fun `test T-row conversion`() {
        assertEquals("た", processAndFlush("Та"))
        assertEquals("ち", processAndFlush("Чи"))
        assertEquals("つ", processAndFlush("Цу"))
        assertEquals("て", processAndFlush("Тэ"))
        assertEquals("と", processAndFlush("То"))
    }

    @Test
    fun `test N-row conversion`() {
        assertEquals("な", processAndFlush("На"))
        assertEquals("に", processAndFlush("Ни"))
        assertEquals("ぬ", processAndFlush("Ну"))
        assertEquals("ね", processAndFlush("Нэ"))
        assertEquals("の", processAndFlush("Но"))
    }

    @Test
    fun `test H-row conversion`() {
        assertEquals("は", processAndFlush("Ха"))
        assertEquals("ひ", processAndFlush("Хи"))
        assertEquals("ふ", processAndFlush("Фу"))
        assertEquals("へ", processAndFlush("Хэ"))
        assertEquals("ほ", processAndFlush("Хо"))
    }

    @Test
    fun `test M-row conversion`() {
        assertEquals("ま", processAndFlush("Ма"))
        assertEquals("み", processAndFlush("Ми"))
        assertEquals("む", processAndFlush("Му"))
        assertEquals("め", processAndFlush("Мэ"))
        assertEquals("も", processAndFlush("Мо"))
    }

    @Test
    fun `test Y-row conversion`() {
        assertEquals("や", processAndFlush("Я"))
        assertEquals("ゆ", processAndFlush("Ю"))
        assertEquals("よ", processAndFlush("Ё"))
    }

    @Test
    fun `test R-row conversion`() {
        assertEquals("ら", processAndFlush("Ра"))
        assertEquals("り", processAndFlush("Ри"))
        assertEquals("る", processAndFlush("Ру"))
        assertEquals("れ", processAndFlush("Рэ"))
        assertEquals("ろ", processAndFlush("Ро"))
    }

    @Test
    fun `test W-row conversion`() {
        assertEquals("わ", processAndFlush("Ва"))
        assertEquals("を", processAndFlush("О"))
    }

    @Test
    fun `test N standalone conversion`() {
        assertEquals("ん", processAndFlush("Н'"))
    }

    // ==================== Dakuon (濁音) Tests ====================

    @Test
    fun `test G-row conversion`() {
        assertEquals("が", processAndFlush("Га"))
        assertEquals("ぎ", processAndFlush("Ги"))
        assertEquals("ぐ", processAndFlush("Гу"))
        assertEquals("げ", processAndFlush("Гэ"))
        assertEquals("ご", processAndFlush("Го"))
    }

    @Test
    fun `test Z-row conversion`() {
        assertEquals("ざ", processAndFlush("Дза"))
        assertEquals("じ", processAndFlush("Дзи"))
        assertEquals("ず", processAndFlush("Дзу"))
        assertEquals("ぜ", processAndFlush("Дзэ"))
        assertEquals("ぞ", processAndFlush("Дзо"))
    }

    @Test
    fun `test D-row conversion`() {
        assertEquals("だ", processAndFlush("Да"))
        assertEquals("で", processAndFlush("Дэ"))
        assertEquals("ど", processAndFlush("До"))
    }

    @Test
    fun `test B-row conversion`() {
        assertEquals("ば", processAndFlush("Ба"))
        assertEquals("び", processAndFlush("Би"))
        assertEquals("ぶ", processAndFlush("Бу"))
        assertEquals("べ", processAndFlush("Бэ"))
        assertEquals("ぼ", processAndFlush("Бо"))
    }

    // ==================== Handakuon (半濁音) Tests ====================

    @Test
    fun `test P-row conversion`() {
        assertEquals("ぱ", processAndFlush("Па"))
        assertEquals("ぴ", processAndFlush("Пи"))
        assertEquals("ぷ", processAndFlush("Пу"))
        assertEquals("ぺ", processAndFlush("Пэ"))
        assertEquals("ぽ", processAndFlush("По"))
    }

    // ==================== Youon (拗音) Tests ====================

    @Test
    fun `test Ky youon conversion`() {
        assertEquals("きゃ", processAndFlush("Кя"))
        assertEquals("きゅ", processAndFlush("Кю"))
        assertEquals("きょ", processAndFlush("Кё"))
    }

    @Test
    fun `test Sh youon conversion`() {
        assertEquals("しゃ", processAndFlush("Ся"))
        assertEquals("しゅ", processAndFlush("Сю"))
        assertEquals("しょ", processAndFlush("Сё"))
    }

    @Test
    fun `test Ch youon conversion`() {
        assertEquals("ちゃ", processAndFlush("Ча"))
        assertEquals("ちゅ", processAndFlush("Чу"))
        assertEquals("ちょ", processAndFlush("Чо"))
    }

    @Test
    fun `test Ny youon conversion`() {
        assertEquals("にゃ", processAndFlush("Ня"))
        assertEquals("にゅ", processAndFlush("Ню"))
        assertEquals("にょ", processAndFlush("Нё"))
    }

    @Test
    fun `test Hy youon conversion`() {
        assertEquals("ひゃ", processAndFlush("Хя"))
        assertEquals("ひゅ", processAndFlush("Хю"))
        assertEquals("ひょ", processAndFlush("Хё"))
    }

    @Test
    fun `test My youon conversion`() {
        assertEquals("みゃ", processAndFlush("Мя"))
        assertEquals("みゅ", processAndFlush("Мю"))
        assertEquals("みょ", processAndFlush("Мё"))
    }

    @Test
    fun `test Ry youon conversion`() {
        assertEquals("りゃ", processAndFlush("Ря"))
        assertEquals("りゅ", processAndFlush("Рю"))
        assertEquals("りょ", processAndFlush("Рё"))
    }

    @Test
    fun `test Gy youon conversion`() {
        assertEquals("ぎゃ", processAndFlush("Гя"))
        assertEquals("ぎゅ", processAndFlush("Гю"))
        assertEquals("ぎょ", processAndFlush("Гё"))
    }

    @Test
    fun `test J youon conversion`() {
        assertEquals("じゃ", processAndFlush("Дзя"))
        assertEquals("じゅ", processAndFlush("Дзю"))
        assertEquals("じょ", processAndFlush("Дзё"))
    }

    @Test
    fun `test By youon conversion`() {
        assertEquals("びゃ", processAndFlush("Бя"))
        assertEquals("びゅ", processAndFlush("Бю"))
        assertEquals("びょ", processAndFlush("Бё"))
    }

    @Test
    fun `test Py youon conversion`() {
        assertEquals("ぴゃ", processAndFlush("Пя"))
        assertEquals("ぴゅ", processAndFlush("Пю"))
        assertEquals("ぴょ", processAndFlush("Пё"))
    }

    // ==================== Gairaigo (外来語) Tests ====================

    @Test
    fun `test F-row gairaigo conversion`() {
        assertEquals("ふぁ", processAndFlush("Фа"))
        assertEquals("ふぃ", processAndFlush("Фи"))
        assertEquals("ふぇ", processAndFlush("Фэ"))
        assertEquals("ふぉ", processAndFlush("Фо"))
    }

    @Test
    fun `test Ti Di gairaigo conversion`() {
        assertEquals("てぃ", processAndFlush("Ти"))
        assertEquals("でぃ", processAndFlush("Ди"))
    }

    @Test
    fun `test Tu Du gairaigo conversion`() {
        assertEquals("とぅ", processAndFlush("Ту"))
        assertEquals("どぅ", processAndFlush("Ду"))
    }

    @Test
    fun `test She Je Che gairaigo conversion`() {
        assertEquals("しぇ", processAndFlush("Сье"))
        assertEquals("じぇ", processAndFlush("Дзье"))
        assertEquals("ちぇ", processAndFlush("Чье"))
    }

    @Test
    fun `test V-row gairaigo conversion`() {
        assertEquals("ゔぁ", processAndFlush("Вуа"))
        assertEquals("ゔぃ", processAndFlush("Вуи"))
        assertEquals("ゔ", processAndFlush("Ву"))
        assertEquals("ゔぇ", processAndFlush("Вуэ"))
        assertEquals("ゔぉ", processAndFlush("Вуо"))
    }

    // ==================== Small Kana Tests ====================

    @Test
    fun `test small vowels conversion`() {
        assertEquals("ぁ", processAndFlush("ъа"))
        assertEquals("ぃ", processAndFlush("ъи"))
        assertEquals("ぅ", processAndFlush("ъу"))
        assertEquals("ぇ", processAndFlush("ъэ"))
        assertEquals("ぉ", processAndFlush("ъо"))
    }

    @Test
    fun `test small ya yu yo conversion`() {
        assertEquals("ゃ", processAndFlush("ъя"))
        assertEquals("ゅ", processAndFlush("ъю"))
        assertEquals("ょ", processAndFlush("ъё"))
    }

    @Test
    fun `test small tsu conversion`() {
        assertEquals("っ", processAndFlush("ъц"))
    }

    // ==================== Sokuon (促音) Tests ====================

    @Test
    fun `test sokuon with K`() {
        // КК should become っК
        val result = processAndFlush("Кка")
        assertEquals("っか", result)
    }

    @Test
    fun `test sokuon with S`() {
        val result = processAndFlush("Сса")
        assertEquals("っさ", result)
    }

    @Test
    fun `test sokuon with T`() {
        val result = processAndFlush("Тта")
        assertEquals("った", result)
    }

    @Test
    fun `test sokuon with P`() {
        val result = processAndFlush("Ппа")
        assertEquals("っぱ", result)
    }

    // ==================== N Before Consonant Tests ====================

    @Test
    fun `test N before consonant`() {
        // Н before consonant should become ん
        assertEquals("さんか", processAndFlush("СаНКа"))
    }

    @Test
    fun `test N before vowel stays in buffer`() {
        // Н before vowel continues to compose
        assertEquals("にあ", processAndFlush("НиА"))
    }

    @Test
    fun `test N with apostrophe separator`() {
        assertEquals("かんあ", processAndFlush("КаН'А"))
    }

    // ==================== Word Tests ====================

    @Test
    fun `test basic word - sakura`() {
        assertEquals("さくら", processAndFlush("СаКуРа"))
    }

    @Test
    fun `test basic word - nihongo`() {
        assertEquals("にほんご", processAndFlush("НиХоНГо"))
    }

    @Test
    fun `test basic word - Tokyo`() {
        assertEquals("とうきょう", processAndFlush("ТоУКёУ"))
    }

    @Test
    fun `test word with youon - kyoto`() {
        assertEquals("きょうと", processAndFlush("КёУТо"))
    }

    @Test
    fun `test word with sokuon - gakko`() {
        assertEquals("がっこう", processAndFlush("ГаККоУ"))
    }

    @Test
    fun `test word with dakuon - densha`() {
        assertEquals("でんしゃ", processAndFlush("ДэНСя"))
    }

    // ==================== Case Insensitivity Tests ====================

    @Test
    fun `test lowercase input`() {
        assertEquals("さ", processAndFlush("са"))
    }

    @Test
    fun `test mixed case input`() {
        assertEquals("さくら", processAndFlush("сАкУрА"))
    }

    // ==================== Incremental Input Tests ====================

    @Test
    fun `test character by character input`() {
        converter.processInput('С')
        assertEquals("С", converter.getComposingText())

        converter.processInput('а')
        // After Са is recognized, should commit さ
        assertEquals("", converter.getComposingText())
        assertEquals("さ", converter.flush())
    }

    @Test
    fun `test composing text during input`() {
        val result1 = converter.processInput('К')
        assertTrue(result1.composing.isNotEmpty())

        val result2 = converter.processInput('а')
        assertEquals("か", result2.committed)
        assertTrue(result2.composing.isEmpty())
    }

    // ==================== Profile Tests ====================

    @Test
    fun `test Ukrainian profile - I`() {
        converter.setProfile(CyrillicKanaConverter.Profile.UKRAINIAN)
        assertEquals("い", processAndFlush("І"))
    }

    @Test
    fun `test Ukrainian profile - Gi`() {
        converter.setProfile(CyrillicKanaConverter.Profile.UKRAINIAN)
        assertEquals("ぎ", processAndFlush("Ґі"))
    }

    @Test
    fun `test Belarusian profile - Wa`() {
        converter.setProfile(CyrillicKanaConverter.Profile.BELARUSIAN)
        assertEquals("わ", processAndFlush("Ўа"))
    }

    @Test
    fun `test Bulgarian profile - U`() {
        converter.setProfile(CyrillicKanaConverter.Profile.BULGARIAN)
        assertEquals("う", processAndFlush("Ъ"))
    }

    @Test
    fun `test Serbian profile - Ya`() {
        converter.setProfile(CyrillicKanaConverter.Profile.SERBIAN)
        assertEquals("や", processAndFlush("Ја"))
    }

    @Test
    fun `test Serbian profile - Chi`() {
        converter.setProfile(CyrillicKanaConverter.Profile.SERBIAN)
        assertEquals("ち", processAndFlush("Ћ"))
    }

    // ==================== Edge Cases ====================

    @Test
    fun `test empty input`() {
        assertEquals("", processAndFlush(""))
    }

    @Test
    fun `test clear buffer`() {
        converter.processInput("Са")
        converter.clearBuffer()
        assertEquals("", converter.getComposingText())
    }

    @Test
    fun `test flush with pending buffer`() {
        converter.processInput("К")
        val result = converter.flush()
        // К alone should be output as-is (lowercase)
        assertEquals("к", result)
    }

    @Test
    fun `test non-cyrillic passthrough`() {
        // Non-Cyrillic characters should pass through
        assertEquals("abc", processAndFlush("abc"))
    }

    @Test
    fun `test mixed cyrillic and non-cyrillic`() {
        assertEquals("さaさ", processAndFlush("СаaСа"))
    }

    // ==================== Helper Methods ====================

    private fun processAndFlush(input: String): String {
        converter.clearBuffer()
        converter.processInput(input)
        return converter.flush()
    }
}
