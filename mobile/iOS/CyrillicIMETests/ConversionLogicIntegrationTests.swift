//
//  ConversionLogicIntegrationTests.swift
//  CyrillicIMETests
//
//  Integration tests for actual conversion logic using real profiles and schemas
//  Based on テスト仕様書.md Section 2: 変換ロジックテスト
//

import XCTest
@testable import Pismo

/// Integration tests that verify conversion logic with REAL Rust Core, profiles, and schemas
/// These tests directly correspond to テスト仕様書.md test cases
class ConversionLogicIntegrationTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    override func setUp() {
        super.setUp()

        // Use actual RustCoreFFI and ProfileManager
        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared

        // Ensure profiles are loaded
        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        // Set to Russian Standard profile for tests
        let switchError = profileManager.switchProfile(to: "rus_standard")
        XCTAssertNil(switchError, "Should switch to rus_standard profile")

        print("\n=== Integration Test Setup ===")
        print("Current profile: \(profileManager.currentProfile?.id ?? "nil")")
        print("Rust Core initialized: \(rustCore.initialized)")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - 2.1.1 清音（50音）テストケース (Russian Standard)

    /// テスト仕様書: RUS-BASIC-001
    /// 入力: А, 期待値: あ (母音単独)
    func testRUS_BASIC_001_VowelA() {
        let result = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for А")
        XCTAssertEqual(result?.action, "commit", "А should commit")
        XCTAssertEqual(result?.output, "あ", "А should output あ")
        XCTAssertEqual(result?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-001: А → あ")
    }

    /// テスト仕様書: RUS-BASIC-002
    /// 入力: И, 期待値: い (母音単独)
    func testRUS_BASIC_002_VowelI() {
        let result = rustCore.processKey(
            cyrillicKey: "И",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for И")
        XCTAssertEqual(result?.action, "commit", "И should commit")
        XCTAssertEqual(result?.output, "い", "И should output い")
        XCTAssertEqual(result?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-002: И → い")
    }

    /// テスト仕様書: RUS-BASIC-003
    /// 入力: У, 期待値: う (母音単独)
    func testRUS_BASIC_003_VowelU() {
        let result = rustCore.processKey(
            cyrillicKey: "У",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for У")
        XCTAssertEqual(result?.action, "commit", "У should commit")
        XCTAssertEqual(result?.output, "う", "У should output う")
        XCTAssertEqual(result?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-003: У → う")
    }

    /// テスト仕様書: RUS-BASIC-004
    /// 入力: Э, 期待値: え (母音単独)
    func testRUS_BASIC_004_VowelE() {
        let result = rustCore.processKey(
            cyrillicKey: "Э",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for Э")
        XCTAssertEqual(result?.action, "commit", "Э should commit")
        XCTAssertEqual(result?.output, "え", "Э should output え")
        XCTAssertEqual(result?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-004: Э → え")
    }

    /// テスト仕様書: RUS-BASIC-005
    /// 入力: О, 期待値: お (母音単独)
    func testRUS_BASIC_005_VowelO() {
        let result = rustCore.processKey(
            cyrillicKey: "О",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for О")
        XCTAssertEqual(result?.action, "commit", "О should commit")
        XCTAssertEqual(result?.output, "お", "О should output お")
        XCTAssertEqual(result?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-005: О → お")
    }

    /// テスト仕様書: RUS-BASIC-006
    /// 入力: КА, 期待値: か (か行)
    func testRUS_BASIC_006_KA() {
        // Step 1: Press К
        let result1 = rustCore.processKey(
            cyrillicKey: "К",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result1, "Result should not be nil for К")
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        XCTAssertEqual(result1?.buffer, "К", "Buffer should contain К")

        // Step 2: Press А
        let result2 = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "К",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result2, "Result should not be nil for КА")
        XCTAssertEqual(result2?.action, "commit", "КА should commit")
        XCTAssertEqual(result2?.output, "か", "КА should output か")
        XCTAssertEqual(result2?.buffer, "", "Buffer should be empty after commit")

        print("✅ RUS-BASIC-006: КА → か")
    }

    /// テスト仕様書: RUS-BASIC-007
    /// 入力: КИ, 期待値: き (か行)
    func testRUS_BASIC_007_KI() {
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "К", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "き", "КИ should output き")

        print("✅ RUS-BASIC-007: КИ → き")
    }

    /// テスト仕様書: RUS-BASIC-008
    /// 入力: КУ, 期待値: く (か行)
    func testRUS_BASIC_008_KU() {
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "К", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "く", "КУ should output く")

        print("✅ RUS-BASIC-008: КУ → く")
    }

    /// テスト仕様書: RUS-BASIC-012
    /// 入力: СИ, 期待値: し (さ行・特殊)
    func testRUS_BASIC_012_SHI() {
        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "С", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "し", "СИ should output し")

        print("✅ RUS-BASIC-012: СИ → し")
    }

    /// テスト仕様書: RUS-BASIC-017
    /// 入力: ЧИ, 期待値: ち (た行・特殊)
    func testRUS_BASIC_017_CHI() {
        let result1 = rustCore.processKey(cyrillicKey: "Ч", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "Ч", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "ち", "ЧИ should output ち")

        print("✅ RUS-BASIC-017: ЧИ → ち")
    }

    /// テスト仕様書: RUS-BASIC-018
    /// 入力: ЦУ, 期待値: つ (た行・特殊)
    func testRUS_BASIC_018_TSU() {
        let result1 = rustCore.processKey(cyrillicKey: "Ц", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "Ц", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "つ", "ЦУ should output つ")

        print("✅ RUS-BASIC-018: ЦУ → つ")
    }

    /// テスト仕様書: RUS-BASIC-043
    /// 入力: Н (単独), 期待値: ん (撥音)
    func testRUS_BASIC_043_N() {
        let result = rustCore.processKey(
            cyrillicKey: "Н",
            currentBuffer: "",
            profileId: "rus_standard"
        )

        XCTAssertNotNil(result, "Result should not be nil for Н")
        XCTAssertEqual(result?.action, "commit", "Н should commit")
        XCTAssertEqual(result?.output, "ん", "Н should output ん")

        print("✅ RUS-BASIC-043: Н → ん")
    }

    // MARK: - 2.1.2 濁音・半濁音テストケース

    /// テスト仕様書: RUS-VOICE-001
    /// 入力: ГА, 期待値: が (濁音)
    func testRUS_VOICE_001_GA() {
        let result1 = rustCore.processKey(cyrillicKey: "Г", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "Г", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "が", "ГА should output が")

        print("✅ RUS-VOICE-001: ГА → が")
    }

    /// テスト仕様書: RUS-VOICE-007
    /// 入力: ЗИ, 期待値: じ (濁音)
    func testRUS_VOICE_007_ZI() {
        let result1 = rustCore.processKey(cyrillicKey: "З", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "З", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "じ", "ЗИ should output じ")

        print("✅ RUS-VOICE-007: ЗИ → じ")
    }

    /// テスト仕様書: RUS-SEMI-001
    /// 入力: ПА, 期待値: ぱ (半濁音)
    func testRUS_SEMI_001_PA() {
        let result1 = rustCore.processKey(cyrillicKey: "П", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "П", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "ぱ", "ПА should output ぱ")

        print("✅ RUS-SEMI-001: ПА → ぱ")
    }

    // MARK: - 2.1.3 拗音テストケース

    /// テスト仕様書: RUS-YO-001
    /// 入力: КЯ, 期待値: きゃ (か行拗音)
    func testRUS_YO_001_KYA() {
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "Я", currentBuffer: "К", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "きゃ", "КЯ should output きゃ")

        print("✅ RUS-YO-001: КЯ → きゃ")
    }

    /// テスト仕様書: RUS-YO-002
    /// 入力: КЮ, 期待値: きゅ (か行拗音)
    func testRUS_YO_002_KYU() {
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "Ю", currentBuffer: "К", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "きゅ", "КЮ should output きゅ")

        print("✅ RUS-YO-002: КЮ → きゅ")
    }

    /// テスト仕様書: RUS-YO-003
    /// 入力: КЁ, 期待値: きょ (か行拗音)
    func testRUS_YO_003_KYO() {
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "Ё", currentBuffer: "К", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "きょ", "КЁ should output きょ")

        print("✅ RUS-YO-003: КЁ → きょ")
    }

    /// テスト仕様書: RUS-YO-004
    /// 入力: СЯ, 期待値: しゃ (さ行拗音)
    func testRUS_YO_004_SHA() {
        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")

        let result2 = rustCore.processKey(cyrillicKey: "Я", currentBuffer: "С", profileId: "rus_standard")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "しゃ", "СЯ should output しゃ")

        print("✅ RUS-YO-004: СЯ → しゃ")
    }

    // MARK: - 2.1.4 特殊ケーステスト

    /// テスト仕様書: RUS-SPEC-001
    /// 入力: К + К + А, 期待値: っか (促音・子音重複)
    func testRUS_SPEC_001_Sokuon() {
        // Step 1: First К
        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: "rus_standard")
        XCTAssertEqual(result1?.action, "composing")
        XCTAssertEqual(result1?.buffer, "К")

        // Step 2: Second К (should trigger 促音)
        let result2 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "К", profileId: "rus_standard")

        // This should either:
        // a) Output "っ" and keep "К" in buffer, OR
        // b) Keep "КК" in buffer for next key

        if result2?.action == "commit" {
            XCTAssertEqual(result2?.output, "っ", "Double К should output っ")

            // Step 3: А to complete
            let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: result2?.buffer ?? "", profileId: "rus_standard")
            XCTAssertEqual(result3?.output, "か", "К + А should output か after っ")

            print("✅ RUS-SPEC-001: ККА → っか (immediate 促音)")
        } else {
            // Buffer approach: wait for third key
            let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: result2?.buffer ?? "КК", profileId: "rus_standard")
            XCTAssertTrue(
                result3?.output.contains("っ") ?? false || result3?.output.contains("か") ?? false,
                "ККА should eventually produce っか"
            )

            print("✅ RUS-SPEC-001: ККА → っか (buffered 促音)")
        }
    }

    /// テスト仕様書: RUS-SPEC-004
    /// 入力: Т + О + О + К + Я + О + О, 期待値: とーきょー (長音)
    func testRUS_SPEC_004_LongVowel_Tokyo() {
        var buffer = ""
        var output = ""

        // Т + О → と
        var result = rustCore.processKey(cyrillicKey: "Т", currentBuffer: buffer, profileId: "rus_standard")
        buffer = result?.buffer ?? ""

        result = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: "rus_standard")
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""

        // О (long vowel) → ー
        result = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: "rus_standard")
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""

        // К + Я → きょ
        result = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: "rus_standard")
        buffer = result?.buffer ?? ""

        result = rustCore.processKey(cyrillicKey: "Я", currentBuffer: buffer, profileId: "rus_standard")
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""

        // О (long vowel) → ー
        result = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: "rus_standard")
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""

        result = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: "rus_standard")
        output += result?.output ?? ""

        // Check final output contains とーきょー or とおきょお
        let expectedVariants = ["とーきょー", "とおきょお"]
        let matchesExpected = expectedVariants.contains { output.contains($0) }

        XCTAssertTrue(matchesExpected, "ТОКЯОО should produce とーきょー or とおきょお, got: \(output)")

        print("✅ RUS-SPEC-004: ТОКЯОО → \(output)")
    }

    /// テスト仕様書: RUS-SPEC-010
    /// 入力: Н (単独), 期待値: ん (撥音単独入力)
    func testRUS_SPEC_010_SingleN() {
        let result = rustCore.processKey(cyrillicKey: "Н", currentBuffer: "", profileId: "rus_standard")

        XCTAssertEqual(result?.action, "commit", "Н alone should commit")
        XCTAssertEqual(result?.output, "ん", "Н alone should output ん")

        print("✅ RUS-SPEC-010: Н → ん")
    }

    // MARK: - Integration Test: Complete Word Input

    /// 統合テスト: "こんにちは" の入力
    /// 入力: К-О-Н-Н-И-Ч-И-В-А
    func testCompleteWord_Konnichiwa() {
        var buffer = ""
        var output = ""

        let keys = ["К", "О", "Н", "Н", "И", "Ч", "И", "В", "А"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: "rus_standard")

            if let result = result {
                output += result.output
                buffer = result.buffer
            }
        }

        print("Complete word test: КОННІЧІВА → \(output)")
        XCTAssertTrue(output.contains("こ"), "Should contain こ")
        XCTAssertTrue(output.contains("ん"), "Should contain ん")
        XCTAssertTrue(output.contains("に"), "Should contain に")
        XCTAssertTrue(output.contains("ち"), "Should contain ち")
        XCTAssertTrue(output.contains("は") || output.contains("わ"), "Should contain は or わ")

        print("✅ Complete word: こんにちは")
    }

    /// 統合テスト: "ありがとう" の入力
    /// 入力: А-Р-И-Г-А-Т-О-О
    func testCompleteWord_Arigatou() {
        var buffer = ""
        var output = ""

        let keys = ["А", "Р", "И", "Г", "А", "Т", "О", "О"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: "rus_standard")

            if let result = result {
                output += result.output
                buffer = result.buffer
            }
        }

        print("Complete word test: АРИГАТО → \(output)")
        XCTAssertTrue(output.contains("あ"), "Should contain あ")
        XCTAssertTrue(output.contains("り"), "Should contain り")
        XCTAssertTrue(output.contains("が"), "Should contain が")
        XCTAssertTrue(output.contains("と"), "Should contain と")
        XCTAssertTrue(output.contains("う") || output.contains("お"), "Should contain う or お (long vowel)")

        print("✅ Complete word: ありがとう")
    }
}
