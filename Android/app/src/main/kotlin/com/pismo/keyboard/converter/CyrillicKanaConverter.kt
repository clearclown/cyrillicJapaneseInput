/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.pismo.keyboard.converter

import android.util.Log

/**
 * Converts Cyrillic text to Japanese Hiragana.
 *
 * Supports multiple Cyrillic profiles:
 * - Standard (Russian)
 * - Ukrainian (UKR)
 * - Belarusian (BEL)
 * - Bulgarian (BUL)
 * - Serbian (SRB)
 *
 * Based on docs/mappings/ CSV files
 */
class CyrillicKanaConverter {

    companion object {
        private const val TAG = "CyrillicKanaConverter"
    }

    enum class Profile(val index: Int) {
        STANDARD(0),
        UKRAINIAN(1),
        BELARUSIAN(2),
        BULGARIAN(3),
        SERBIAN(4)
    }

    private var currentProfile: Profile = Profile.STANDARD

    // ==================== SEION (清音) ====================
    // Format: (romaji, hiragana, Standard, UKR, BEL, BUL, SRB)
    private val seionData = listOf(
        // Vowels
        listOf("a", "あ", "А", "А", "А", "А", "А"),
        listOf("i", "い", "И", "І", "І", "И", "И"),
        listOf("u", "う", "У", "У", "У", "Ъ", "У"),
        listOf("e", "え", "Э", "Э", "Э", "Е", "Э"),
        listOf("o", "お", "О", "О", "О", "О", "О"),
        // K-row
        listOf("ka", "か", "Ка", "Ка", "Ка", "Ка", "Ка"),
        listOf("ki", "き", "Ки", "Кі", "Кі", "Ки", "Ки"),
        listOf("ku", "く", "Ку", "Ку", "Ку", "Къ", "Ку"),
        listOf("ke", "け", "Кэ", "Кэ", "Кэ", "Ке", "Кэ"),
        listOf("ko", "こ", "Ко", "Ко", "Ко", "Ко", "Ко"),
        // S-row
        listOf("sa", "さ", "Са", "Са", "Са", "Са", "Са"),
        listOf("shi", "し", "Си", "Сі", "Сі", "Си", "Си"),
        listOf("su", "す", "Су", "Су", "Су", "Съ", "Су"),
        listOf("se", "せ", "Сэ", "Сэ", "Сэ", "Се", "Сэ"),
        listOf("so", "そ", "Со", "Со", "Со", "Со", "Со"),
        // T-row
        listOf("ta", "た", "Та", "Та", "Та", "Та", "Та"),
        listOf("chi", "ち", "Чи", "Чі", "Чі", "Чи", "Ћ"),
        listOf("tsu", "つ", "Цу", "Цу", "Цу", "Цъ", "Цу"),
        listOf("te", "て", "Тэ", "Тэ", "Тэ", "Те", "Тэ"),
        listOf("to", "と", "То", "То", "То", "То", "То"),
        // N-row
        listOf("na", "な", "На", "На", "На", "На", "На"),
        listOf("ni", "に", "Ни", "Ні", "Ні", "Ни", "Ни"),
        listOf("nu", "ぬ", "Ну", "Ну", "Ну", "Нъ", "Ну"),
        listOf("ne", "ね", "Нэ", "Нэ", "Нэ", "Не", "Нэ"),
        listOf("no", "の", "Но", "Но", "Но", "Но", "Но"),
        // H-row
        listOf("ha", "は", "Ха", "Ха", "Ха", "Ха", "Ха"),
        listOf("hi", "ひ", "Хи", "Хі", "Хі", "Хи", "Хи"),
        listOf("fu", "ふ", "Фу", "Фу", "Фу", "Фъ", "Фу"),
        listOf("he", "へ", "Хэ", "Хэ", "Хэ", "Хе", "Хэ"),
        listOf("ho", "ほ", "Хо", "Хо", "Хо", "Хо", "Хо"),
        // M-row
        listOf("ma", "ま", "Ма", "Ма", "Ма", "Ма", "Ма"),
        listOf("mi", "み", "Ми", "Мі", "Мі", "Ми", "Ми"),
        listOf("mu", "む", "Му", "Му", "Му", "Мъ", "Му"),
        listOf("me", "め", "Мэ", "Мэ", "Мэ", "Ме", "Мэ"),
        listOf("mo", "も", "Мо", "Мо", "Мо", "Мо", "Мо"),
        // Y-row
        listOf("ya", "や", "Я", "Я", "Я", "Я", "Ја"),
        listOf("yu", "ゆ", "Ю", "Ю", "Ю", "Ю", "Ју"),
        listOf("yo", "よ", "Ё", "Ё", "Ё", "Ё", "Јо"),
        // R-row
        listOf("ra", "ら", "Ра", "Ра", "Ра", "Ра", "Ра"),
        listOf("ri", "り", "Ри", "Рі", "Рі", "Ри", "Ри"),
        listOf("ru", "る", "Ру", "Ру", "Ру", "Ръ", "Ру"),
        listOf("re", "れ", "Рэ", "Рэ", "Рэ", "Ре", "Рэ"),
        listOf("ro", "ろ", "Ро", "Ро", "Ро", "Ро", "Ро"),
        // W-row
        listOf("wa", "わ", "Ва", "Ва", "Ўа", "Ва", "Ва"),
        listOf("wi", "ゐ", "Ви", "Ві", "Ўі", "Ви", "Ви"),
        listOf("we", "ゑ", "Вэ", "Вэ", "Ўэ", "Ве", "Вэ"),
        listOf("wo", "を", "Во", "Во", "Ўо", "Во", "Во"),
        // N
        listOf("n", "ん", "Н", "Н", "Н", "Н", "Н")
    )

    // ==================== DAKUON (濁音) ====================
    private val dakuonData = listOf(
        // G-row
        listOf("ga", "が", "Га", "Ґа", "Га", "Га", "Га"),
        listOf("gi", "ぎ", "Ги", "Ґі", "Ги", "Ги", "Ги"),
        listOf("gu", "ぐ", "Гу", "Ґу", "Гу", "Гу", "Гу"),
        listOf("ge", "げ", "Гэ", "Ґе", "Гэ", "Гэ", "Гэ"),
        listOf("go", "ご", "Го", "Ґо", "Го", "Го", "Го"),
        // Z-row
        listOf("za", "ざ", "Дза", "Дза", "Дза", "Дза", "Дза"),
        listOf("ji", "じ", "Дзи", "Дзі", "Дзі", "Дзи", "Дзи"),
        listOf("zu", "ず", "Дзу", "Дзу", "Дзу", "Дзъ", "Дзу"),
        listOf("ze", "ぜ", "Дзэ", "Дзэ", "Дзэ", "Дзе", "Дзэ"),
        listOf("zo", "ぞ", "Дзо", "Дзо", "Дзо", "Дзо", "Дзо"),
        // D-row
        listOf("da", "だ", "Да", "Да", "Да", "Да", "Да"),
        listOf("di", "ぢ", "Дьи", "Дьі", "Дьі", "Дьи", "Дьи"),
        listOf("du", "づ", "Дьу", "Дьу", "Дьу", "Дьъ", "Дьу"),
        listOf("de", "で", "Дэ", "Дэ", "Дэ", "Де", "Дэ"),
        listOf("do", "ど", "До", "До", "До", "До", "До"),
        // B-row
        listOf("ba", "ば", "Ба", "Ба", "Ба", "Ба", "Ба"),
        listOf("bi", "び", "Би", "Бі", "Бі", "Би", "Би"),
        listOf("bu", "ぶ", "Бу", "Бу", "Бу", "Бъ", "Бу"),
        listOf("be", "べ", "Бэ", "Бэ", "Бэ", "Бе", "Бэ"),
        listOf("bo", "ぼ", "Бо", "Бо", "Бо", "Бо", "Бо")
    )

    // ==================== HANDAKUON (半濁音) ====================
    private val handakuonData = listOf(
        listOf("pa", "ぱ", "Па", "Па", "Па", "Па", "Па"),
        listOf("pi", "ぴ", "Пи", "Пі", "Пі", "Пи", "Пи"),
        listOf("pu", "ぷ", "Пу", "Пу", "Пу", "Пъ", "Пу"),
        listOf("pe", "ぺ", "Пэ", "Пэ", "Пэ", "Пе", "Пэ"),
        listOf("po", "ぽ", "По", "По", "По", "По", "По")
    )

    // ==================== YOUON (拗音) ====================
    private val youonData = listOf(
        // Ky-
        listOf("kya", "きゃ", "Кя", "Кя", "Кя", "Кя", "Кја"),
        listOf("kyu", "きゅ", "Кю", "Кю", "Кю", "Кю", "Кју"),
        listOf("kyo", "きょ", "Кё", "Кё", "Кё", "Кё", "Кјо"),
        // Sh-
        listOf("sha", "しゃ", "Ся", "Ся", "Ся", "Ся", "Сја"),
        listOf("shu", "しゅ", "Сю", "Сю", "Сю", "Сю", "Сју"),
        listOf("sho", "しょ", "Сё", "Сё", "Сё", "Сё", "Сјо"),
        // Ch-
        listOf("cha", "ちゃ", "Ча", "Ча", "Ча", "Ча", "Ћа"),
        listOf("chu", "ちゅ", "Чу", "Чу", "Чу", "Чу", "Ћу"),
        listOf("cho", "ちょ", "Чо", "Чо", "Чо", "Чо", "Ћо"),
        // Ny-
        listOf("nya", "にゃ", "Ня", "Ня", "Ня", "Ня", "Ња"),
        listOf("nyu", "にゅ", "Ню", "Ню", "Ню", "Ню", "Њу"),
        listOf("nyo", "にょ", "Нё", "Нё", "Нё", "Нё", "Њо"),
        // Hy-
        listOf("hya", "ひゃ", "Хя", "Хя", "Хя", "Хя", "Хја"),
        listOf("hyu", "ひゅ", "Хю", "Хю", "Хю", "Хю", "Хју"),
        listOf("hyo", "ひょ", "Хё", "Хё", "Хё", "Хё", "Хјо"),
        // My-
        listOf("mya", "みゃ", "Мя", "Мя", "Мя", "Мя", "Мја"),
        listOf("myu", "みゅ", "Мю", "Мю", "Мю", "Мю", "Мју"),
        listOf("myo", "みょ", "Мё", "Мё", "Мё", "Мё", "Мјо"),
        // Ry-
        listOf("rya", "りゃ", "Ря", "Ря", "Ря", "Ря", "Рја"),
        listOf("ryu", "りゅ", "Рю", "Рю", "Рю", "Рю", "Рју"),
        listOf("ryo", "りょ", "Рё", "Рё", "Рё", "Рё", "Рјо"),
        // Gy-
        listOf("gya", "ぎゃ", "Гя", "Гя", "Гя", "Гя", "Гја"),
        listOf("gyu", "ぎゅ", "Гю", "Гю", "Гю", "Гю", "Гју"),
        listOf("gyo", "ぎょ", "Гё", "Гё", "Гё", "Гё", "Гјо"),
        // J-
        listOf("ja", "じゃ", "Дзя", "Дзя", "Дзя", "Дзя", "Ђа"),
        listOf("ju", "じゅ", "Дзю", "Дзю", "Дзю", "Дзю", "Ђу"),
        listOf("jo", "じょ", "Дзё", "Дзё", "Дзё", "Дзё", "Ђо"),
        // By-
        listOf("bya", "びゃ", "Бя", "Бя", "Бя", "Бя", "Бја"),
        listOf("byu", "びゅ", "Бю", "Бю", "Бю", "Бю", "Бју"),
        listOf("byo", "びょ", "Бё", "Бё", "Бё", "Бё", "Бјо"),
        // Py-
        listOf("pya", "ぴゃ", "Пя", "Пя", "Пя", "Пя", "Пја"),
        listOf("pyu", "ぴゅ", "Пю", "Пю", "Пю", "Пю", "Пју"),
        listOf("pyo", "ぴょ", "Пё", "Пё", "Пё", "Пё", "Пјо")
    )

    // ==================== GAIRAIGO (外来語) ====================
    private val gairaigo = listOf(
        // ファ行 (f + vowel)
        listOf("fa", "ふぁ", "Фа", "Фа", "Фа", "Фа", "Фа"),
        listOf("fi", "ふぃ", "Фи", "Фі", "Фі", "Фи", "Фи"),
        listOf("fe", "ふぇ", "Фэ", "Фэ", "Фэ", "Фе", "Фэ"),
        listOf("fo", "ふぉ", "Фо", "Фо", "Фо", "Фо", "Фо"),
        // ティ/ディ行
        listOf("ti", "てぃ", "Ти", "Ті", "Ті", "Ти", "Ти"),
        listOf("di", "でぃ", "Ди", "Ді", "Ді", "Ди", "Ди"),
        listOf("tu", "とぅ", "Ту", "Ту", "Ту", "Ту", "Ту"),
        listOf("du", "どぅ", "Ду", "Ду", "Ду", "Ду", "Ду"),
        // ウィ/ウェ/ウォ modern
        listOf("wi_m", "うぃ", "Уи", "Уі", "Уі", "Уи", "Уи"),
        listOf("we_m", "うぇ", "Уэ", "Уэ", "Уэ", "Уе", "Уэ"),
        listOf("wo_m", "うぉ", "Уо", "Уо", "Уо", "Уо", "Уо"),
        // シェ/ジェ/チェ/ツェ
        listOf("she", "しぇ", "Сье", "Сье", "Сье", "Сье", "Сје"),
        listOf("je", "じぇ", "Дзье", "Дзье", "Дзье", "Дзье", "Џе"),
        listOf("che", "ちぇ", "Чье", "Чье", "Чье", "Чье", "Ће"),
        listOf("tse", "つぇ", "Цье", "Цье", "Цье", "Цье", "Цје"),
        // ヴ行 (v sound)
        listOf("va", "ゔぁ", "Вуа", "Вуа", "Вуа", "Въа", "Вуа"),
        listOf("vi", "ゔぃ", "Вуи", "Вуі", "Вуі", "Въи", "Вуи"),
        listOf("vu", "ゔ", "Ву", "Ву", "Ву", "Въ", "Ву"),
        listOf("ve", "ゔぇ", "Вуэ", "Вуэ", "Вуэ", "Въе", "Вуэ"),
        listOf("vo", "ゔぉ", "Вуо", "Вуо", "Вуо", "Въо", "Вуо")
    )

    // ==================== SMALL KANA (小書き仮名) ====================
    private val smallKana = listOf(
        listOf("xa", "ぁ", "ъа", "ъа", "ъа", "ъа", "ъа"),
        listOf("xi", "ぃ", "ъи", "ъі", "ъі", "ъи", "ъи"),
        listOf("xu", "ぅ", "ъу", "ъу", "ъу", "ъу", "ъу"),
        listOf("xe", "ぇ", "ъэ", "ъэ", "ъэ", "ъе", "ъэ"),
        listOf("xo", "ぉ", "ъо", "ъо", "ъо", "ъо", "ъо"),
        listOf("xya", "ゃ", "ъя", "ъя", "ъя", "ъя", "ъја"),
        listOf("xyu", "ゅ", "ъю", "ъю", "ъю", "ъю", "ъју"),
        listOf("xyo", "ょ", "ъё", "ъё", "ъё", "ъё", "ъјо"),
        listOf("xwa", "ゎ", "ъва", "ъва", "ъўа", "ъва", "ъва"),
        listOf("xtu", "っ", "ъц", "ъц", "ъц", "ъц", "ъц")
    )

    // Sokuon consonants (doubles that become っ)
    private val sokuonConsonants = setOf(
        "К", "С", "Т", "Ц", "Х", "Ф", "П", "Ч",
        "Г", "Д", "Б", "Дз"
    )

    // Buffer for composing text
    private var composingBuffer = StringBuilder()

    fun setProfile(profile: Profile) {
        currentProfile = profile
    }

    fun getProfile(): Profile = currentProfile

    /**
     * Process a single character input and return converted text if ready.
     */
    fun processInput(char: Char): ConversionResult {
        composingBuffer.append(char.uppercaseChar())
        return tryConvert()
    }

    /**
     * Process string input.
     */
    fun processInput(text: String): ConversionResult {
        for (char in text) {
            composingBuffer.append(char.uppercaseChar())
        }
        return tryConvert()
    }

    fun getComposingText(): String = composingBuffer.toString()

    fun clearBuffer() {
        composingBuffer.clear()
    }

    /**
     * Delete the last character from the composing buffer.
     */
    fun deleteLastChar() {
        if (composingBuffer.isNotEmpty()) {
            composingBuffer.deleteCharAt(composingBuffer.length - 1)
        }
    }

    fun flush(): String {
        val result = convertBuffer(composingBuffer.toString())
        composingBuffer.clear()
        return result
    }

    private fun tryConvert(): ConversionResult {
        val buffer = composingBuffer.toString()
        if (buffer.isEmpty()) {
            return ConversionResult("", "")
        }

        val committed = StringBuilder()
        var remaining = buffer

        while (remaining.isNotEmpty()) {
            val matchResult = findLongestMatch(remaining)

            if (matchResult != null) {
                val (hiragana, matchLength) = matchResult

                // Check if there might be a longer match
                if (couldMatchLonger(remaining)) {
                    break
                }

                committed.append(hiragana)
                remaining = remaining.substring(matchLength)
            } else {
                // Check for sokuon (っ) - doubled consonant
                if (remaining.length >= 2 && isSokuonPattern(remaining)) {
                    committed.append("っ")
                    remaining = remaining.substring(1)
                    continue
                }

                // Check for ん before consonant or at end with apostrophe separator
                if (remaining.startsWith("Н") && remaining.length >= 2) {
                    val nextChar = remaining.substring(1, minOf(2, remaining.length))
                    // н' is explicit separator for ん
                    if (remaining.length >= 2 && remaining[1] == '\'') {
                        committed.append("ん")
                        remaining = remaining.substring(2)
                        continue
                    }
                    if (!isVowel(nextChar) && nextChar != "Ь" && nextChar != "Я" && nextChar != "Ю" && nextChar != "Ё") {
                        committed.append("ん")
                        remaining = remaining.substring(1)
                        continue
                    }
                }

                // Check for long vowel (double vowel -> ー)
                if (remaining.length >= 2 && isLongVowelPattern(remaining)) {
                    committed.append("ー")
                    remaining = remaining.substring(1)
                    continue
                }

                // Could be start of valid sequence - keep in buffer
                if (couldStartValidSequence(remaining)) {
                    break
                }

                // No match possible, output as-is (lowercase)
                committed.append(remaining[0].lowercaseChar())
                remaining = remaining.substring(1)
            }
        }

        composingBuffer = StringBuilder(remaining)
        return ConversionResult(committed.toString(), remaining)
    }

    private fun findLongestMatch(text: String): Pair<String, Int>? {
        // Try longest matches first (up to 4 characters for patterns like "Дзье")
        for (length in minOf(text.length, 4) downTo 1) {
            val candidate = text.substring(0, length)
            val hiragana = getHiragana(candidate)
            if (hiragana != null) {
                return Pair(hiragana, length)
            }
        }
        return null
    }

    private fun couldMatchLonger(text: String): Boolean {
        for (entry in getAllMappings()) {
            val cyrillic = entry.first
            if (cyrillic.startsWith(text) && cyrillic.length > text.length) {
                return true
            }
        }
        return false
    }

    private fun couldStartValidSequence(text: String): Boolean {
        val firstChar = text.first().toString()
        for (entry in getAllMappings()) {
            val cyrillic = entry.first
            if (cyrillic.startsWith(firstChar)) {
                return true
            }
        }
        return false
    }

    private fun isSokuonPattern(text: String): Boolean {
        if (text.length < 2) return false
        val first = text[0].toString()
        val second = text[1].toString()

        // Check multi-char consonants first (like Дз)
        if (text.length >= 4 && text.startsWith("ДЗ") && text.substring(2, 4).startsWith("ДЗ")) {
            return true
        }

        return sokuonConsonants.contains(first) && first == second
    }

    private fun isLongVowelPattern(text: String): Boolean {
        if (text.length < 2) return false
        val first = text[0].toString()
        val second = text[1].toString()
        val vowels = setOf("А", "И", "У", "Э", "О", "І", "Е", "Ъ")
        return vowels.contains(first) && first == second
    }

    private fun isVowel(char: String): Boolean {
        return char in listOf("А", "И", "У", "Э", "О", "І", "Е", "Ъ")
    }

    private fun getHiragana(cyrillic: String): String? {
        val upper = cyrillic.uppercase()
        val profileIndex = currentProfile.index + 2

        val allData = seionData + dakuonData + handakuonData + youonData + gairaigo + smallKana
        for (entry in allData) {
            if (entry[profileIndex].uppercase() == upper) {
                return entry[1]
            }
        }
        return null
    }

    private fun getAllMappings(): List<Pair<String, String>> {
        val profileIndex = currentProfile.index + 2
        val allData = seionData + dakuonData + handakuonData + youonData + gairaigo + smallKana
        return allData.map { entry ->
            Pair(entry[profileIndex].uppercase(), entry[1])
        }
    }

    private fun convertBuffer(text: String): String {
        var remaining = text
        val result = StringBuilder()

        while (remaining.isNotEmpty()) {
            val matchResult = findLongestMatch(remaining)
            if (matchResult != null) {
                result.append(matchResult.first)
                remaining = remaining.substring(matchResult.second)
            } else {
                // Check sokuon
                if (remaining.length >= 2 && isSokuonPattern(remaining)) {
                    result.append("っ")
                    remaining = remaining.substring(1)
                    continue
                }

                // Check ん before consonant
                if (remaining.startsWith("Н") && remaining.length >= 2) {
                    val nextChar = remaining.substring(1, minOf(2, remaining.length))
                    if (remaining.length >= 2 && remaining[1] == '\'') {
                        result.append("ん")
                        remaining = remaining.substring(2)
                        continue
                    }
                    if (!isVowel(nextChar)) {
                        result.append("ん")
                        remaining = remaining.substring(1)
                        continue
                    }
                }

                // Long vowel
                if (remaining.length >= 2 && isLongVowelPattern(remaining)) {
                    result.append("ー")
                    remaining = remaining.substring(1)
                    continue
                }

                // Output as-is
                result.append(remaining[0].lowercaseChar())
                remaining = remaining.substring(1)
            }
        }

        return result.toString()
    }

    data class ConversionResult(
        val committed: String,
        val composing: String
    )
}
