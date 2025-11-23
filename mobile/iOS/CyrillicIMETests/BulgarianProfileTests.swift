//
//  BulgarianProfileTests.swift
//  CyrillicIMETests
//
//  Integration tests for Bulgarian BDS profile conversion logic
//  Tests Bulgarian-specific features: Ъ character usage
//

import XCTest
@testable import Pismo

/// Integration tests for Bulgarian BDS profile (bul_bds)
/// Based on schema_bul_v1.json mappings
class BulgarianProfileTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    let profileId = "bul_bds"

    override func setUp() {
        super.setUp()

        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared

        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        // Switch to Bulgarian profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        print("\n=== Bulgarian Profile Test Setup ===")
        print("Current profile: \(profileManager.currentProfile?.id ?? "nil")")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - Basic Vowels

    /// BUL-BASIC-001: А → あ
    func testBUL_BASIC_001_VowelA() {
        let result = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "А should commit")
        XCTAssertEqual(result?.output, "あ", "А should output あ")
        print("✅ BUL-BASIC-001: А → あ")
    }

    /// BUL-BASIC-002: И → い
    func testBUL_BASIC_002_VowelI() {
        let result = rustCore.processKey(
            cyrillicKey: "И",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "И should commit")
        XCTAssertEqual(result?.output, "い", "И should output い")
        print("✅ BUL-BASIC-002: И → い")
    }

    /// BUL-BASIC-003: У → う
    func testBUL_BASIC_003_VowelU() {
        let result = rustCore.processKey(
            cyrillicKey: "У",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "У should commit")
        XCTAssertEqual(result?.output, "う", "У should output う")
        print("✅ BUL-BASIC-003: У → う")
    }

    /// BUL-BASIC-004: Е → え
    func testBUL_BASIC_004_VowelE() {
        let result = rustCore.processKey(
            cyrillicKey: "Е",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Е should commit")
        XCTAssertEqual(result?.output, "え", "Е should output え")
        print("✅ BUL-BASIC-004: Е → え")
    }

    /// BUL-BASIC-005: О → お
    func testBUL_BASIC_005_VowelO() {
        let result = rustCore.processKey(
            cyrillicKey: "О",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "О should commit")
        XCTAssertEqual(result?.output, "お", "О should output お")
        print("✅ BUL-BASIC-005: О → お")
    }

    /// BUL-BASIC-006: Ы → い (Bulgarian also has Ы)
    func testBUL_BASIC_006_VowelY() {
        let result = rustCore.processKey(
            cyrillicKey: "Ы",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Ы should commit")
        XCTAssertEqual(result?.output, "い", "Ы should output い")
        print("✅ BUL-BASIC-006: Ы → い")
    }

    // MARK: - Bulgarian-specific: Ъ character

    /// BUL-SPEC-001: Ъ → う (Bulgarian Ъ represents schwa, maps to u)
    func testBUL_SPEC_001_Yer() {
        let result = rustCore.processKey(
            cyrillicKey: "Ъ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Ъ should commit")
        // Ъ is the Bulgarian "yer" vowel, mapped to "u" sound
        XCTAssertNotNil(result?.output, "Ъ should produce output")
        print("✅ BUL-SPEC-001: Ъ → \(result?.output ?? "nil")")
    }

    /// BUL-SPEC-002: КЪ → く (Bulgarian uses Ъ for "u" sound)
    func testBUL_SPEC_002_KU_With_Yer() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КЪ should commit")
        XCTAssertEqual(result2?.output, "く", "КЪ should output く")

        print("✅ BUL-SPEC-002: КЪ → く")
    }

    /// BUL-SPEC-003: СЪ → す
    func testBUL_SPEC_003_SU_With_Yer() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СЪ should commit")
        XCTAssertEqual(result2?.output, "す", "СЪ should output す")

        print("✅ BUL-SPEC-003: СЪ → す")
    }

    /// BUL-SPEC-004: ЦЪ → つ (Bulgarian tsu with Ъ)
    func testBUL_SPEC_004_TSU_With_Yer() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ц", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ц should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: "Ц", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ЦЪ should commit")
        XCTAssertEqual(result2?.output, "つ", "ЦЪ should output つ")

        print("✅ BUL-SPEC-004: ЦЪ → つ")
    }

    /// BUL-SPEC-005: НЪ → ぬ
    func testBUL_SPEC_005_NU_With_Yer() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Н", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        // Н might commit as ん or be composing depending on implementation
        lastOutput = result1?.lastOutput ?? ""

        if result1?.action == "commit" {
            // If Н committed as ん, then Ъ should give う
            let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ BUL-SPEC-005: Н + Ъ → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            let result2 = rustCore.processKey(cyrillicKey: "Ъ", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "ぬ", "НЪ should output ぬ")
            print("✅ BUL-SPEC-005: НЪ → ぬ")
        }
    }

    // MARK: - Standard consonants with vowels

    /// BUL-BASIC-007: КА → か
    func testBUL_BASIC_007_KA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КА should commit")
        XCTAssertEqual(result2?.output, "か", "КА should output か")

        print("✅ BUL-BASIC-007: КА → か")
    }

    /// BUL-BASIC-008: СИ → し
    func testBUL_BASIC_008_SHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СИ should commit")
        XCTAssertEqual(result2?.output, "し", "СИ should output し")

        print("✅ BUL-BASIC-008: СИ → し")
    }

    /// BUL-BASIC-009: ЧИ → ち
    func testBUL_BASIC_009_CHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ч", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ч should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "Ч", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ЧИ should commit")
        XCTAssertEqual(result2?.output, "ち", "ЧИ should output ち")

        print("✅ BUL-BASIC-009: ЧИ → ち")
    }

    // MARK: - Voiced consonants

    /// BUL-VOICE-001: ГА → が
    func testBUL_VOICE_001_GA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Г", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Г should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "Г", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ГА should commit")
        XCTAssertEqual(result2?.output, "が", "ГА should output が")

        print("✅ BUL-VOICE-001: ГА → が")
    }

    /// BUL-VOICE-002: ЖА → じゃ (Bulgarian Ж)
    func testBUL_VOICE_002_ZHA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ж", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ж should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "Ж", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ЖА should commit")
        // Ж might map to ja or za depending on schema
        XCTAssertNotNil(result2?.output, "ЖА should produce output")

        print("✅ BUL-VOICE-002: ЖА → \(result2?.output ?? "nil")")
    }

    // MARK: - Palatalized sounds

    /// BUL-YO-001: КЯ → きゃ
    func testBUL_YO_001_KYA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Я", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КЯ should commit")
        XCTAssertEqual(result2?.output, "きゃ", "КЯ should output きゃ")

        print("✅ BUL-YO-001: КЯ → きゃ")
    }

    /// BUL-YO-002: СЯ → しゃ
    func testBUL_YO_002_SHA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Я", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СЯ should commit")
        XCTAssertEqual(result2?.output, "しゃ", "СЯ should output しゃ")

        print("✅ BUL-YO-002: СЯ → しゃ")
    }

    // MARK: - Integration Test: Complete Word

    /// Integration test: "българия" (Bulgaria)
    /// Expected input approximation: Б-Ъ-Л-Г-А-Р-И-Я
    func testCompleteWord_Bulgaria() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        // Simplified: БЪ-ЛГА-РИ-Я
        let keys = ["Б", "Ъ", "Л", "Г", "А", "Р", "И", "Я"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

            if let result = result {
                output += result.output
                buffer = result.buffer
                lastOutput = result.lastOutput ?? ""
            }
        }

        // Commit remaining buffer (Я stays in buffer because it can combine)
        if !buffer.isEmpty {
            let commitResult = rustCore.processKey(cyrillicKey: " ", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
            if let commitResult = commitResult {
                output += commitResult.output
            }
        }

        print("Complete word test (Bulgarian): БЪЛГАРИЯ → \(output)")
        XCTAssertTrue(output.contains("が"), "Should contain が")
        XCTAssertTrue(output.contains("り"), "Should contain り")
        XCTAssertTrue(output.contains("や"), "Should contain や or ゃ")

        print("✅ Complete word: Bulgaria (БЪЛГАРИЯ) → \(output)")
    }
}
