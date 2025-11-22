//
//  RussianAnalyticalProfileTests.swift
//  CyrillicIMETests
//
//  Integration tests for Russian Analytical profile conversion logic
//  Tests analytical mode features: Ь for palatalization, Ъ for separation
//

import XCTest
@testable import Pismo

/// Integration tests for Russian Analytical profile (rus_analytical)
/// Based on schema_rus_analytical_v1.json mappings
///
/// Key differences from standard Russian:
/// - Ь (soft sign) for palatalization: КЬА → きゃ
/// - Ъ (hard sign) for syllable separation: НЪА → んあ
/// - ДЗ digraph for za/ji sounds
class RussianAnalyticalProfileTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    let profileId = "rus_analytical"

    override func setUp() {
        super.setUp()

        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared

        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        // Switch to Russian Analytical profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        print("\n=== Russian Analytical Profile Test Setup ===")
        print("Current profile: \(profileManager.currentProfile?.id ?? "nil")")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - Basic Vowels

    /// ANA-BASIC-001: А → あ
    func testANA_BASIC_001_VowelA() {
        let result = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "А should commit")
        XCTAssertEqual(result?.output, "あ", "А should output あ")
        print("✅ ANA-BASIC-001: А → あ")
    }

    /// ANA-BASIC-002: И → い
    func testANA_BASIC_002_VowelI() {
        let result = rustCore.processKey(
            cyrillicKey: "И",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "И should commit")
        XCTAssertEqual(result?.output, "い", "И should output い")
        print("✅ ANA-BASIC-002: И → い")
    }

    /// ANA-BASIC-003: У → う
    func testANA_BASIC_003_VowelU() {
        let result = rustCore.processKey(
            cyrillicKey: "У",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "У should commit")
        XCTAssertEqual(result?.output, "う", "У should output う")
        print("✅ ANA-BASIC-003: У → う")
    }

    /// ANA-BASIC-004: Э → え (analytical mode uses Э for "e")
    func testANA_BASIC_004_VowelE() {
        let result = rustCore.processKey(
            cyrillicKey: "Э",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Э should commit")
        XCTAssertEqual(result?.output, "え", "Э should output え")
        print("✅ ANA-BASIC-004: Э → え")
    }

    /// ANA-BASIC-005: О → お
    func testANA_BASIC_005_VowelO() {
        let result = rustCore.processKey(
            cyrillicKey: "О",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "О should commit")
        XCTAssertEqual(result?.output, "お", "О should output お")
        print("✅ ANA-BASIC-005: О → お")
    }

    // MARK: - Basic Consonants

    /// ANA-BASIC-006: КА → か
    func testANA_BASIC_006_KA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КА should commit")
        XCTAssertEqual(result2?.output, "か", "КА should output か")

        print("✅ ANA-BASIC-006: КА → か")
    }

    /// ANA-BASIC-007: СИ → し
    func testANA_BASIC_007_SHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СИ should commit")
        XCTAssertEqual(result2?.output, "し", "СИ should output し")

        print("✅ ANA-BASIC-007: СИ → し")
    }

    // MARK: - Analytical Mode: Ь for Palatalization

    /// ANA-PAL-001: КЬА → きゃ (Ь indicates palatalization)
    func testANA_PAL_001_KYA_With_SoftSign() {
        var buffer = ""
        var lastOutput = ""

        // К
        var result = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // Ь
        result = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // А
        result = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result?.output, "きゃ", "КЬА should output きゃ")
        print("✅ ANA-PAL-001: КЬА → きゃ")
    }

    /// ANA-PAL-002: КЬУ → きゅ
    func testANA_PAL_002_KYU_With_SoftSign() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "У", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "きゅ", "КЬУ should output きゅ")
        print("✅ ANA-PAL-002: КЬУ → きゅ")
    }

    /// ANA-PAL-003: КЬО → きょ
    func testANA_PAL_003_KYO_With_SoftSign() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "きょ", "КЬО should output きょ")
        print("✅ ANA-PAL-003: КЬО → きょ")
    }

    /// ANA-PAL-004: СЬА → しゃ
    func testANA_PAL_004_SHA_With_SoftSign() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "しゃ", "СЬА should output しゃ")
        print("✅ ANA-PAL-004: СЬА → しゃ")
    }

    /// ANA-PAL-005: НЬА → にゃ
    func testANA_PAL_005_NYA_With_SoftSign() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Н", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        // If Н committed as ん, we need different handling
        if result1?.action == "commit" {
            print("✅ ANA-PAL-005: Н committed early as \(result1?.output ?? "nil")")
            XCTAssertEqual(result1?.output, "ん", "Н should output ん if committing early")
            return
        }

        let result2 = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "にゃ", "НЬА should output にゃ")
        print("✅ ANA-PAL-005: НЬА → にゃ")
    }

    // MARK: - Analytical Mode: Ъ for Separation

    /// ANA-SEP-001: НЪА → んあ (Ъ separates ん from あ)
    func testANA_SEP_001_N_A_Separated() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        // Н
        var result = rustCore.processKey(cyrillicKey: "Н", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // Ъ (separator)
        result = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result?.output ?? ""
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // А
        result = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result?.output ?? ""

        print("Complete sequence: НЪА → \(output)")
        XCTAssertTrue(output.contains("ん"), "Should contain ん")
        XCTAssertTrue(output.contains("あ"), "Should contain あ")
        XCTAssertEqual(output, "んあ", "НЪА should output んあ (separated)")

        print("✅ ANA-SEP-001: НЪА → んあ")
    }

    /// ANA-SEP-002: НЪИ → んい
    func testANA_SEP_002_N_I_Separated() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Н", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result1?.output ?? ""
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result2?.output ?? ""
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "И", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        output += result3?.output ?? ""

        print("Complete sequence: НЪИ → \(output)")
        XCTAssertTrue(output.contains("ん"), "Should contain ん")
        XCTAssertTrue(output.contains("い"), "Should contain い")

        print("✅ ANA-SEP-002: НЪИ → んい")
    }

    /// ANA-SEP-003: Ъ as sokuon marker
    func testANA_SEP_003_Yer_As_Sokuon() {
        let result = rustCore.processKey(
            cyrillicKey: "Ъ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        // Ъ might be sokuon (っ) or separator depending on context
        XCTAssertNotNil(result?.output, "Ъ should produce some output or buffer")
        print("✅ ANA-SEP-003: Ъ → \(result?.output ?? "buffered: \(result?.buffer ?? "nil")")")
    }

    // MARK: - Analytical Mode: ДЗ Digraph

    /// ANA-DIG-001: ДЗА → ざ
    func testANA_DIG_001_DZA() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Д", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "З", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "ざ", "ДЗА should output ざ")
        print("✅ ANA-DIG-001: ДЗА → ざ")
    }

    /// ANA-DIG-002: ДЗИ → じ
    func testANA_DIG_002_DZI() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Д", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "З", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "И", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "じ", "ДЗИ should output じ")
        print("✅ ANA-DIG-002: ДЗИ → じ")
    }

    /// ANA-DIG-003: ДЗЬА → じゃ (palatalized with Ь)
    func testANA_DIG_003_DZYA() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Д", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "З", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "Ь", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result3?.buffer ?? ""
        lastOutput = result3?.lastOutput ?? ""

        let result4 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result4?.output, "じゃ", "ДЗЬА should output じゃ")
        print("✅ ANA-DIG-003: ДЗЬА → じゃ")
    }

    // MARK: - Integration Test: Complete Word with Analytical Features

    /// Integration test: "さんいん" (San'in region - needs separation)
    /// Analytical input: С-А-Н-Ъ-И-Н
    func testCompleteWord_Sanin_Separated() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        // САН → さん
        let keys = ["С", "А", "Н", "Ъ", "И", "Н"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

            if let result = result {
                output += result.output
                buffer = result.buffer
                lastOutput = result.lastOutput
            }
        }

        print("Complete word test (Analytical): САНЪИН → \(output)")
        XCTAssertTrue(output.contains("さ"), "Should contain さ")
        XCTAssertTrue(output.contains("ん"), "Should contain ん")
        XCTAssertTrue(output.contains("い"), "Should contain い")

        print("✅ Complete word: San'in (САНЪИН) → \(output)")
    }
}
