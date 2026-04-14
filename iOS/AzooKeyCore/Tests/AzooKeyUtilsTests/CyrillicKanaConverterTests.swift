//
//  CyrillicKanaConverterTests.swift
//  PismoTests
//
//  Created by Pismo on 2025/11/23.
//

import XCTest
@testable import AzooKeyUtils

final class CyrillicKanaConverterTests: XCTestCase {

    var converter: CyrillicKanaConverter!

    override func setUp() {
        super.setUp()
        converter = CyrillicKanaConverter()
        print("[\(self.classForCoder)] SetUp: Converter initialized")
    }

    override func tearDown() {
        print("[\(self.classForCoder)] TearDown: Converter released")
        converter = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// 入力シミュレーションヘルパー
    /// - Returns: 最終的なバッファの状態 (平仮名に変換されたもの)
    func simulateInput(_ input: String, initialBuffer: String = "") -> (buffer: String, operations: [CyrillicKanaConverter.InputOperation]) {
        var buffer = initialBuffer
        var operations: [CyrillicKanaConverter.InputOperation] = []

        print("\n--- Simulation Start: Input='\(input)', InitialBuffer='\(initialBuffer)' ---")

        for char in input {
            let charStr = String(char)
            print("Processing char: \(charStr)")

            let op = converter.process(input: charStr, composingText: buffer)
            operations.append(op)

            print("  Operation: deleteLast=\(op.deleteLast), input='\(op.input)'")

            if op.deleteLast > 0 {
                let dropCount = op.deleteLast
                if dropCount > buffer.count {
                    XCTFail("CRITICAL: Attempt to delete \(dropCount) chars from buffer of length \(buffer.count) ('\(buffer)')")
                    return (buffer, operations)
                }
                let deleted = buffer.suffix(dropCount)
                buffer.removeLast(dropCount)
                print("  Buffer Update: Deleted '\(deleted)' -> Current='\(buffer)'")
            }

            buffer += op.input
            print("  Buffer Update: Appended '\(op.input)' -> Current='\(buffer)'")
        }

        print("--- Simulation End: Result='\(buffer)' ---\n")
        return (buffer, operations)
    }

    // MARK: - Standard Profile Comprehensive Tests

    func testStandardSeionFullRows() {
        converter.setProfile(.standard)
        print("Testing Standard Seion Rows")

        // あ行
        assertConversion("А", "あ")
        assertConversion("И", "い")
        assertConversion("У", "う")
        assertConversion("Э", "え")
        assertConversion("О", "お")

        // か行
        assertConversion("Ка", "か")
        assertConversion("Ки", "き")
        assertConversion("Ку", "く")
        assertConversion("Кэ", "け")
        assertConversion("Ко", "こ")

        // さ行
        assertConversion("Са", "さ")
        assertConversion("Си", "し")
        assertConversion("Су", "す")
        assertConversion("Сэ", "せ")
        assertConversion("Со", "そ")

        // た行
        assertConversion("Та", "た")
        assertConversion("Чи", "ち") // Standard is Chi -> ち
        assertConversion("Цу", "つ") // Standard is Tsu -> つ
        assertConversion("Тэ", "て")
        assertConversion("То", "と")

        // な行
        assertConversion("На", "な")
        assertConversion("Ни", "に")
        assertConversion("Ну", "ぬ")
        assertConversion("Нэ", "ね")
        assertConversion("Но", "の")

        // は行
        assertConversion("Ха", "は")
        assertConversion("Хи", "ひ")
        assertConversion("Фу", "ふ") // Fu -> ふ
        assertConversion("Хэ", "へ")
        assertConversion("Хо", "ほ")

        // ま行
        assertConversion("Ма", "ま")
        assertConversion("Ми", "み")
        assertConversion("Му", "む")
        assertConversion("Мэ", "め")
        assertConversion("Мо", "も")

        // や行
        assertConversion("Я", "や")
        assertConversion("Ю", "ゆ")
        assertConversion("Ё", "よ")

        // ら行
        assertConversion("Ра", "ら")
        assertConversion("Ри", "り")
        assertConversion("Ру", "る")
        assertConversion("Рэ", "れ")
        assertConversion("Ро", "ろ")

        // わ行
        assertConversion("Ва", "わ")
        assertConversion("О", "を") // Special WO mapping

        // ん
        assertConversion("Н", "ん") // Single N is wait, but assertConversion handles result
    }

    func assertConversion(_ input: String, _ expected: String, line: UInt = #line) {
        let result = simulateInput(input)
        XCTAssertEqual(result.buffer, expected, "Failed for input '\(input)'", line: line)
    }

    func testDakutenFullRows() {
        converter.setProfile(.standard)
        print("Testing Dakuten/Handakuten Rows")

        assertConversion("Га", "が")
        assertConversion("Ги", "ぎ")
        assertConversion("Гу", "ぐ")
        assertConversion("Гэ", "げ")
        assertConversion("Го", "ご")

        assertConversion("Дза", "ざ")
        assertConversion("Дзи", "じ")
        assertConversion("Дзу", "ず")
        assertConversion("Дзэ", "ぜ")
        assertConversion("Дзо", "ぞ")

        assertConversion("Да", "だ")
        assertConversion("Дэ", "で")
        assertConversion("До", "ど")

        assertConversion("Ба", "ば")
        assertConversion("Би", "び")
        assertConversion("Бу", "ぶ")
        assertConversion("Бэ", "べ")
        assertConversion("Бо", "ぼ")

        assertConversion("Па", "ぱ")
        assertConversion("Пи", "ぴ")
        assertConversion("Пу", "ぷ")
        assertConversion("Пэ", "ぺ")
        assertConversion("По", "ぽ")
    }

    // MARK: - Special Rules (Sokuon, Nasal, Long Vowel)

    func testSokuonGenerations() {
        converter.setProfile(.standard)
        print("Testing Sokuon (Double Consonant)")

        // KK -> っk (各行の促音)
        assertConversion("ККа", "っか")
        assertConversion("ССа", "っさ")
        assertConversion("ТТа", "った")
        assertConversion("ППа", "っぱ")
        assertConversion("ББа", "っば")
        assertConversion("ГГа", "っが")
        assertConversion("ММа", "っま")
        assertConversion("РРа", "っら")

        // Mixed Case Sokuon
        assertConversion("КкА", "っか")
        assertConversion("кКа", "っか")

        // 促音 + つ (ЦЦу → っつ)
        assertConversion("ЦЦу", "っつ")

        // 促音 + ち (ЧЧи → っち)
        assertConversion("ЧЧи", "っち")
    }

    func testNasalSoundBehavior() {
        converter.setProfile(.standard)
        print("Testing Nasal Sound (N)")

        // N + Consonant -> ん + Consonant
        assertConversion("НКа", "んか")
        assertConversion("НСа", "んさ")
        assertConversion("НТа", "んた")
        assertConversion("НПа", "んぱ")
        assertConversion("НМа", "んま")

        // N + Vowel -> Na, Ni, Nu... (Not んa)
        assertConversion("НА", "な")
        assertConversion("НИ", "に")
        assertConversion("НУ", "ぬ")
        assertConversion("НЭ", "ね")
        assertConversion("НО", "の")  // ← "но" → "の"

        // N + N -> ん (Single ん, NOT っн)
        // "НН" -> "ん"
        let resNN = simulateInput("НН")
        XCTAssertEqual(resNN.buffer, "ん", "НН should produce ん, not っн")

        // "ННа" -> "んな"
        assertConversion("ННа", "んな")

        // "ННН" -> "んん" (three Ns)
        let resNNN = simulateInput("ННН")
        XCTAssertEqual(resNNN.buffer, "んН", "НННはんНになる（最後のНは待機）")

        // N at end (Explicit)
        // "Н" -> "Н" (Wait)
        let res = simulateInput("Н")
        XCTAssertEqual(res.buffer, "Н", "Single N should wait")

        // Explicit Separator Method 1: Apostrophe (')
        assertConversion("Н'А", "んあ")
        assertConversion("Н'И", "んい")
        assertConversion("Н'У", "んう")
        assertConversion("Н'Э", "んえ")
        assertConversion("Н'О", "んお")
        assertConversion("Н'Я", "んや")
        assertConversion("Н'Ю", "んゆ")
        assertConversion("Н'Ё", "んよ")

        // Explicit Separator Method 2: Hard Sign (ъ) - for Russian keyboard
        // Example: Gin'iro = гинъиро (銀色)
        assertConversion("НъА", "んあ")
        assertConversion("НъИ", "んい")
        assertConversion("НъУ", "んう")
        assertConversion("НъЭ", "んえ")
        assertConversion("НъО", "んお")
        assertConversion("НъЯ", "んや")
        assertConversion("НъЮ", "んゆ")
        assertConversion("НъЁ", "んよ")
    }

    func testSokuonVsNasalDistinction() {
        converter.setProfile(.standard)
        print("Testing Sokuon vs Nasal distinction")

        // НН → ん (撥音)
        let resNN = simulateInput("НН")
        XCTAssertEqual(resNN.buffer, "ん", "НН produces ん (nasal)")

        // КК → っК (促音 + 子音待機)
        let resKK = simulateInput("КК")
        XCTAssertEqual(resKK.buffer, "っК", "КК produces っК (sokuon + waiting K)")

        // ККа → っか
        assertConversion("ККа", "っか")

        // НКа → んか (Н + К は ん + か)
        assertConversion("НКа", "んか")
    }

    func testLongVowels() {
        converter.setProfile(.standard)
        print("Testing Long Vowels")

        // Method 1: Double vowel (e.g., ОО → おお)
        let res1 = simulateInput("ОО")
        XCTAssertEqual(res1.buffer, "おお", "Double vowel produces おお")

        // Method 2: Direct ー input (e.g., Коーхиー → こーひー)
        // "ー" is not a Cyrillic character, so it should pass through unchanged
        assertConversion("Коーхиー", "こーひー")
        assertConversion("トーキョー", "トーキョー") // Non-Cyrillic pass-through

        // Mixed: Cyrillic with direct ー
        assertConversion("Оー", "おー")
        assertConversion("Аー", "あー")
    }

    // MARK: - Special Character Tests

    func testSpecialCharacters() {
        converter.setProfile(.standard)
        print("Testing Special Characters: Ё, ъ")

        // Ё maps to よ (yo)
        assertConversion("Ё", "よ")
        assertConversion("Ёко", "よこ") // よこ (side/横)

        // ъ (hard sign) as small kana prefix
        assertConversion("ъа", "ぁ")
        assertConversion("ъи", "ぃ")
        assertConversion("ъу", "ぅ")
        assertConversion("ъэ", "ぇ")
        assertConversion("ъо", "ぉ")
        assertConversion("ъя", "ゃ")
        assertConversion("ъю", "ゅ")
        assertConversion("ъё", "ょ")

        // ъ for small っ (sokuon direct input)
        assertConversion("ъц", "っ")

        // ъ for separator (n + vowel)
        assertConversion("Нъа", "んあ")
    }

    // MARK: - Profile Switching & Variants

    func testProfileSwitching() {
        print("Testing Profile Switching")

        // Standard
        converter.setProfile(.standard)
        assertConversion("И", "い")
        assertConversion("Ъ", "Ъ") // Wait or unmapped? "Ъ" is sokuon in analytical, unmapped in standard?
        // In standard, "Ъ" is not mapped in Seion table.

        // Ukrainian
        converter.setProfile(.ukrainian)
        assertConversion("І", "い") // UKR specific
        assertConversion("И", "И") // UKR "И" is [y] (~i), but mapped?
        // In CSV: UKR col for "i" is "І". "И" is not in UKR column for "i".
        // Check `updateMapping`:
        // i -> И (Std), І (Ukr)
        // So for Ukr, "І" -> "い". "И" is likely unmapped or mapped to something else?
        // In my code `newMapping[key] = value`.
        // `pick` selects column.
        // For `i`: `row.3` is `І`. So map `І` -> `い`.
        // `И` is NOT mapped to `い` in Ukr profile.

        // Bulgarian
        converter.setProfile(.bulgarian)
        assertConversion("Ъ", "う") // BUL specific for 'u'
        assertConversion("Е", "え") // BUL specific for 'e'

        // Serbian
        converter.setProfile(.serbian)
        assertConversion("Ћ", "ち") // SRB specific
        assertConversion("Ја", "や") // Ja -> Ya
    }

    // MARK: - Integration / Flow Tests

    func testKonnichiwaFlow() {
        converter.setProfile(.standard)
        print("Testing Flow: Konnichiwa")
        // "К" + "о" + "н" + "н" + "и" + "ч" + "и" + "в" + "а"
        // かな: "こんにちは"

        let inputSeq = "Конничива"
        let res = simulateInput(inputSeq)

        XCTAssertEqual(res.buffer, "こんにちは")
    }

    func testArigatoFlow() {
        converter.setProfile(.standard)
        print("Testing Flow: Arigato")
        // "А" + "р" + "и" + "г" + "а" + "т" + "о"
        // かな: "ありがとう"

        let inputSeq = "Аригато"
        let res = simulateInput(inputSeq)

        XCTAssertEqual(res.buffer, "ありがとう")
    }

    func testSayonaraFlow() {
        converter.setProfile(.standard)
        print("Testing Flow: Sayonara")
        // "С" + "а" + "ё" + "о" + "н" + "а" + "р" + "а"
        // かな: "さようなら" (Note: "ё" is "yo", so "sayoonara")

        let inputSeq = "Саёонара"
        let res = simulateInput(inputSeq)

        XCTAssertEqual(res.buffer, "さようなら")
    }

    // MARK: - Gairaigo (Foreign Loanword) Tests

    func testGairaigoMappings() {
        converter.setProfile(.standard)
        print("Testing Gairaigo (Foreign Loanword) Mappings")

        // ファ行
        assertConversion("Фа", "ふぁ")
        assertConversion("Фи", "ふぃ")
        assertConversion("Фэ", "ふぇ")
        assertConversion("Фо", "ふぉ")
        assertConversion("Фю", "ふゅ")

        // ティ/ディ行
        assertConversion("Ти", "てぃ")
        assertConversion("Ди", "でぃ")
        assertConversion("Ту", "とぅ")
        assertConversion("Ду", "どぅ")
        assertConversion("Тю", "てゅ")
        assertConversion("Дю", "でゅ")

        // ツァ行
        assertConversion("Ца", "つぁ")
        assertConversion("Ци", "つぃ")
        assertConversion("Цо", "つぉ")

        // スィ/ズィ
        assertConversion("Сьи", "すぃ")
        assertConversion("Дзьи", "ずぃ")

        // イェ
        assertConversion("Йэ", "いぇ")

        // ウァ/ウィ/ウェ/ウォ
        assertConversion("Уа", "うぁ")
        assertConversion("Уи", "うぃ")
        assertConversion("Уэ", "うぇ")
        assertConversion("Уо", "うぉ")

        // クァ行
        assertConversion("Ква", "くゎ")
        assertConversion("Куи", "くぃ")
        assertConversion("Куэ", "くぇ")
        assertConversion("Куо", "くぉ")

        // グァ行
        assertConversion("Гва", "ぐゎ")
        assertConversion("Гуи", "ぐぃ")
        assertConversion("Гуэ", "ぐぇ")
        assertConversion("Гуо", "ぐぉ")

        // シェ/ジェ/チェ/ツェ
        assertConversion("Сье", "しぇ")
        assertConversion("Дзье", "じぇ")
        assertConversion("Чье", "ちぇ")
        assertConversion("Цье", "つぇ")

        // ニェ/ヒェ等
        assertConversion("Нье", "にぇ")
        assertConversion("Хье", "ひぇ")
        assertConversion("Мье", "みぇ")
        assertConversion("Рье", "りぇ")
        assertConversion("Кье", "きぇ")
        assertConversion("Гье", "ぎぇ")
        assertConversion("Бье", "びぇ")
        assertConversion("Пье", "ぴぇ")

        // ヴ行
        assertConversion("Вуа", "ゔぁ")
        assertConversion("Вуи", "ゔぃ")
        assertConversion("Ву", "ゔ")
        assertConversion("Вуэ", "ゔぇ")
        assertConversion("Вуо", "ゔぉ")
        assertConversion("Вуя", "ゔゃ")
        assertConversion("Вую", "ゔゅ")
        assertConversion("Вуё", "ゔょ")
    }

    func testSmallKana() {
        converter.setProfile(.standard)
        print("Testing Small Kana (小書き仮名)")

        // 小母音
        assertConversion("ъа", "ぁ")
        assertConversion("ъи", "ぃ")
        assertConversion("ъу", "ぅ")
        assertConversion("ъэ", "ぇ")
        assertConversion("ъо", "ぉ")

        // 小拗音
        assertConversion("ъя", "ゃ")
        assertConversion("ъю", "ゅ")
        assertConversion("ъё", "ょ")

        // 小わ
        assertConversion("ъва", "ゎ")

        // 促音（直接入力）
        assertConversion("ъц", "っ")

        // 小かけ
        assertConversion("ъка", "ゕ")
        assertConversion("ъкэ", "ゖ")
    }

    // MARK: - Youon (Palatalized) Tests

    func testYouonMappings() {
        converter.setProfile(.standard)
        print("Testing Youon (Palatalized Sound) Mappings")

        // きゃ行
        assertConversion("Кя", "きゃ")
        assertConversion("Кю", "きゅ")
        assertConversion("Кё", "きょ")

        // しゃ行
        assertConversion("Ся", "しゃ")
        assertConversion("Сю", "しゅ")
        assertConversion("Сё", "しょ")

        // ちゃ行
        assertConversion("Ча", "ちゃ")
        assertConversion("Чу", "ちゅ")
        assertConversion("Чо", "ちょ")

        // にゃ行
        assertConversion("Ня", "にゃ")
        assertConversion("Ню", "にゅ")
        assertConversion("Нё", "にょ")

        // ひゃ行
        assertConversion("Хя", "ひゃ")
        assertConversion("Хю", "ひゅ")
        assertConversion("Хё", "ひょ")

        // みゃ行
        assertConversion("Мя", "みゃ")
        assertConversion("Мю", "みゅ")
        assertConversion("Мё", "みょ")

        // りゃ行
        assertConversion("Ря", "りゃ")
        assertConversion("Рю", "りゅ")
        assertConversion("Рё", "りょ")

        // ぎゃ行
        assertConversion("Гя", "ぎゃ")
        assertConversion("Гю", "ぎゅ")
        assertConversion("Гё", "ぎょ")

        // じゃ行
        assertConversion("Дзя", "じゃ")
        assertConversion("Дзю", "じゅ")
        assertConversion("Дзё", "じょ")

        // びゃ行
        assertConversion("Бя", "びゃ")
        assertConversion("Бю", "びゅ")
        assertConversion("Бё", "びょ")

        // ぴゃ行
        assertConversion("Пя", "ぴゃ")
        assertConversion("Пю", "ぴゅ")
        assertConversion("Пё", "ぴょ")
    }

    // MARK: - Real Word Tests

    func testRealWords() {
        converter.setProfile(.standard)
        print("Testing Real Japanese Words")

        // 東京 (トウキョウ)
        assertConversion("Токё", "とうきょう")

        // 寿司 (スシ)
        assertConversion("Суси", "すし")

        // 天ぷら (テンプラ)
        assertConversion("Тэнпура", "てんぷら")

        // 抹茶 (マッチャ)
        assertConversion("Маччя", "まっちゃ")

        // 日本 (ニホン/ニッポン)
        assertConversion("Нихон", "にほん")
        assertConversion("Ниппон", "にっぽん")

        // 新幹線 (シンカンセン)
        assertConversion("Синкансэн", "しんかんせん")

        // カラオケ
        assertConversion("Караокэ", "からおけ")

        // ラーメン (with long vowel as double vowel)
        assertConversion("Раамэн", "らあめん")

        // コーヒー (with long vowels)
        assertConversion("Коохии", "こおひい")

        // 銀色 (gin'iro) - n + vowel with hard sign separator
        assertConversion("Гинъиро", "ぎんいろ")
    }

    // MARK: - Edge Cases & Debugging

    func testUnknownCharacters() {
        converter.setProfile(.standard)
        print("Testing Unknown Characters")

        // Input non-Cyrillic
        let input = "ABC"
        let res = simulateInput(input)
        // Should just pass through?
        // Logic: `isConsonant` checks Cyrillic range.
        // `mapping` won't match.
        // `process` returns `InputOperation(deleteLast: 0, input: input)`
        XCTAssertEqual(res.buffer, "ABC")
    }

    func testMixedCyrillicAndRoman() {
        converter.setProfile(.standard)
        print("Testing Mixed Input")

        // "К" (wait) + "a" (Roman)
        // "К" is waiting.
        // Input "a". Suffix "К" + "A" -> "КА". Mapping has "КА" -> "か".
        // Wait, does mapping keys use Cyrillic or Roman?
        // The CSV has Cyrillic keys: "Ка".
        // So "К" + "a" (Latin 'a') -> Candidate "КA" (Mixed).
        // Mapping has "КА" (Cyrillic 'A').
        // So "Кa" (Mixed) will NOT match "КА" (Cyrillic).
        // It will fall through to `InputOperation(deleteLast: 0, input: "a")`.
        // Buffer becomes "Кa".

        let res = simulateInput("Кa") // Cyrillic K, Latin a
        XCTAssertEqual(res.buffer, "Кa", "Mixed scripts should likely not convert unless mapped")
    }

    // MARK: - Chukchi Profile Tests

    func testChukchiProfile() {
        converter.setProfile(.chukchi)
        print("Testing Chukchi Profile")

        // Ӄ (voiceless uvular plosive) - K-row
        assertConversion("Ӄ", "く")       // Single Ӄ = く
        assertConversion("ӄА", "か")      // Ӄ + vowel compounds
        assertConversion("ӄИ", "き")
        assertConversion("ӄУ", "く")
        assertConversion("ӄЕ", "け")
        assertConversion("ӄО", "こ")

        // Ԓ (el with descender) - R-row
        assertConversion("Ԓ", "る")       // Single Ԓ = る
        assertConversion("ԒА", "ら")      // Ԓ + vowel compounds
        assertConversion("ԒИ", "り")
        assertConversion("ԒУ", "る")
        assertConversion("ԒЕ", "れ")
        assertConversion("ԒО", "ろ")

        // Ӈ (velar nasal) - ん
        assertConversion("Ӈ", "ん")

        // Standard characters still work
        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    // MARK: - Additional Language Profile Tests

    func testMacedonianProfile() {
        converter.setProfile(.macedonian)
        print("Testing Macedonian Profile")

        // Basic conversion (falls back to Serbian for some)
        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    func testKazakhProfile() {
        converter.setProfile(.kazakh)
        print("Testing Kazakh Profile")

        // Standard characters work
        assertConversion("А", "あ")
        assertConversion("Ка", "か")

        // Kazakh-specific characters
        assertConversion("Ә", "え")       // Schwa -> え
        assertConversion("Ғ", "が")       // Ghe with stroke -> が
    }

    func testKyrgyzProfile() {
        converter.setProfile(.kyrgyz)
        print("Testing Kyrgyz Profile")

        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    func testTatarProfile() {
        converter.setProfile(.tatar)
        print("Testing Tatar Profile")

        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    func testBashkirProfile() {
        converter.setProfile(.bashkir)
        print("Testing Bashkir Profile")

        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    func testKomiProfile() {
        converter.setProfile(.komi)
        print("Testing Komi Profile")

        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    func testAbkhazProfile() {
        converter.setProfile(.abkhaz)
        print("Testing Abkhaz Profile")

        assertConversion("А", "あ")
        assertConversion("Ка", "か")
    }

    // MARK: - Edge Cases

    func testLowercaseCyrillicInput() {
        converter.setProfile(.standard)
        print("Testing Lowercase Cyrillic Input")

        // Lowercase single vowels
        assertConversion("а", "あ")
        assertConversion("и", "い")
        assertConversion("у", "う")
        assertConversion("э", "え")
        assertConversion("о", "お")

        // Lowercase consonant + vowel
        assertConversion("ка", "か")
        assertConversion("са", "さ")
        assertConversion("та", "た")
    }

    func testMixedCaseCyrillicInput() {
        converter.setProfile(.standard)
        print("Testing Mixed Case Cyrillic Input")

        // Mixed case should work due to uppercasing
        assertConversion("кА", "か")
        assertConversion("Ка", "か")
        assertConversion("ка", "か")
        assertConversion("КА", "か")
    }

    func testEmptyInput() {
        converter.setProfile(.standard)
        print("Testing Empty Input")

        let res = simulateInput("")
        XCTAssertEqual(res.buffer, "", "Empty input produces empty result")
    }

    func testSingleCharacterInput() {
        converter.setProfile(.standard)
        print("Testing Single Character Input")

        // Single vowel
        assertConversion("А", "あ")

        // Single consonant (should wait)
        let res = simulateInput("К")
        XCTAssertEqual(res.buffer, "К", "Single consonant should wait")
    }

    func testTypingCorrectionSimulation() {
        converter.setProfile(.standard)
        print("Testing Correction (Backspace Simulation)")

        // Simulate user typing "К", then deleting it, then "С", "а"
        // Logic inside `simulateInput` is additive. Here we simulate manually.

        var buffer = ""

        // 1. Input "К"
        let op1 = converter.process(input: "К", composingText: buffer)
        buffer += op1.input
        XCTAssertEqual(buffer, "К")

        // 2. Backspace (handled by InputManager, not Converter usually, but let's say we remove from buffer)
        buffer.removeLast()
        XCTAssertEqual(buffer, "")

        // 3. Input "С"
        let op2 = converter.process(input: "С", composingText: buffer)
        buffer += op2.input
        XCTAssertEqual(buffer, "С")

        // 4. Input "а"
        let op3 = converter.process(input: "а", composingText: buffer) // Suffix "С"
        // Op should be delete 1 ("С"), insert "さ"
        XCTAssertEqual(op3.deleteLast, 1)
        XCTAssertEqual(op3.input, "さ")

        // Apply
        buffer.removeLast(op3.deleteLast)
        buffer += op3.input
        XCTAssertEqual(buffer, "さ")
    }
}
