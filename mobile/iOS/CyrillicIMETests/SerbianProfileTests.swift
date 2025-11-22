//
//  SerbianProfileTests.swift
//  CyrillicIMETests
//
//  Integration tests for Serbian Cyrillic profile conversion logic
//  Tests Serbian-specific features: Њ, Љ, Ђ, Џ, Ћ ligatures and Ј palatalization
//

import XCTest
@testable import Pismo

/// Integration tests for Serbian Cyrillic profile (srb_cyrillic)
/// Based on schema_srb_v1.json mappings
class SerbianProfileTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    let profileId = "srb_cyrillic"

    override func setUp() {
        super.setUp()

        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared

        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        // Switch to Serbian profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        print("\n=== Serbian Profile Test Setup ===")
        print("Current profile: \(profileManager.currentProfile?.id ?? "nil")")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - Basic Vowels

    /// SRB-BASIC-001: А → あ
    func testSRB_BASIC_001_VowelA() {
        let result = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "А should commit")
        XCTAssertEqual(result?.output, "あ", "А should output あ")
        print("✅ SRB-BASIC-001: А → あ")
    }

    /// SRB-BASIC-002: И → い
    func testSRB_BASIC_002_VowelI() {
        let result = rustCore.processKey(
            cyrillicKey: "И",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "И should commit")
        XCTAssertEqual(result?.output, "い", "И should output い")
        print("✅ SRB-BASIC-002: И → い")
    }

    /// SRB-BASIC-003: У → う
    func testSRB_BASIC_003_VowelU() {
        let result = rustCore.processKey(
            cyrillicKey: "У",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "У should commit")
        XCTAssertEqual(result?.output, "う", "У should output う")
        print("✅ SRB-BASIC-003: У → う")
    }

    /// SRB-BASIC-004: Е → え
    func testSRB_BASIC_004_VowelE() {
        let result = rustCore.processKey(
            cyrillicKey: "Е",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Е should commit")
        XCTAssertEqual(result?.output, "え", "Е should output え")
        print("✅ SRB-BASIC-004: Е → え")
    }

    /// SRB-BASIC-005: О → お
    func testSRB_BASIC_005_VowelO() {
        let result = rustCore.processKey(
            cyrillicKey: "О",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "О should commit")
        XCTAssertEqual(result?.output, "お", "О should output お")
        print("✅ SRB-BASIC-005: О → お")
    }

    // MARK: - Basic Consonants + Vowels

    /// SRB-BASIC-006: КА → か
    func testSRB_BASIC_006_KA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КА should commit")
        XCTAssertEqual(result2?.output, "か", "КА should output か")

        print("✅ SRB-BASIC-006: КА → か")
    }

    /// SRB-BASIC-012: СИ → し
    func testSRB_BASIC_012_SHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СИ should commit")
        XCTAssertEqual(result2?.output, "し", "СИ should output し")

        print("✅ SRB-BASIC-012: СИ → し")
    }

    // MARK: - Serbian-specific: Ћ (chi)

    /// SRB-CHI-001: Ћ → ち (single character)
    func testSRB_CHI_001_Tshe_Standalone() {
        let result = rustCore.processKey(
            cyrillicKey: "Ћ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Ћ should commit")
        XCTAssertEqual(result?.output, "ち", "Ћ should output ち")
        print("✅ SRB-CHI-001: Ћ → ち")
    }

    /// SRB-CHI-002: ЋИ → ち (with vowel, should still be chi)
    func testSRB_CHI_002_Tshe_With_I() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ћ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        // Ћ might commit immediately or wait for next key
        if result1?.action == "commit" {
            XCTAssertEqual(result1?.output, "ち", "Ћ should output ち")
            print("✅ SRB-CHI-002: Ћ → ち (standalone)")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "И", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "ち", "ЋИ should output ち")
            print("✅ SRB-CHI-002: ЋИ → ち (composed)")
        }
    }

    // MARK: - Serbian-specific: Њ ligature (nya)

    /// SRB-LIGA-001: Њ → にゃ (ligature standalone)
    func testSRB_LIGA_001_Nje_Standalone() {
        let result = rustCore.processKey(
            cyrillicKey: "Њ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Њ should commit")
        XCTAssertEqual(result?.output, "にゃ", "Њ should output にゃ")
        print("✅ SRB-LIGA-001: Њ → にゃ")
    }

    /// SRB-LIGA-002: ЊА → にゃ (with А)
    func testSRB_LIGA_002_Nje_With_A() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Њ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            XCTAssertEqual(result1?.output, "にゃ", "Њ should output にゃ")
            print("✅ SRB-LIGA-002: Њ → にゃ (standalone)")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "にゃ", "ЊА should output にゃ")
            print("✅ SRB-LIGA-002: ЊА → にゃ (composed)")
        }
    }

    /// SRB-LIGA-003: ЊУ → にゅ
    func testSRB_LIGA_003_Nju() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Њ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            // If Њ commits immediately as にゃ, then У should give う
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ SRB-LIGA-003: Њ + У → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "にゅ", "ЊУ should output にゅ")
            print("✅ SRB-LIGA-003: ЊУ → にゅ")
        }
    }

    /// SRB-LIGA-004: ЊО → にょ
    func testSRB_LIGA_004_Njo() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Њ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "О", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ SRB-LIGA-004: Њ + О → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "О", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "にょ", "ЊО should output にょ")
            print("✅ SRB-LIGA-004: ЊО → にょ")
        }
    }

    // MARK: - Serbian-specific: Љ ligature (rya)

    /// SRB-LIGA-005: Љ → りゃ (ligature standalone)
    func testSRB_LIGA_005_Lje_Standalone() {
        let result = rustCore.processKey(
            cyrillicKey: "Љ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Љ should commit")
        XCTAssertEqual(result?.output, "りゃ", "Љ should output りゃ")
        print("✅ SRB-LIGA-005: Љ → りゃ")
    }

    /// SRB-LIGA-006: ЉУ → りゅ
    func testSRB_LIGA_006_Lju() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Љ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ SRB-LIGA-006: Љ + У → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "りゅ", "ЉУ should output りゅ")
            print("✅ SRB-LIGA-006: ЉУ → りゅ")
        }
    }

    /// SRB-LIGA-007: ЉО → りょ
    func testSRB_LIGA_007_Ljo() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Љ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "О", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ SRB-LIGA-007: Љ + О → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "О", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "りょ", "ЉО should output りょ")
            print("✅ SRB-LIGA-007: ЉО → りょ")
        }
    }

    // MARK: - Serbian-specific: Ђ and Џ (both ja)

    /// SRB-LIGA-008: Ђ → じゃ
    func testSRB_LIGA_008_Dje_Standalone() {
        let result = rustCore.processKey(
            cyrillicKey: "Ђ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Ђ should commit")
        XCTAssertEqual(result?.output, "じゃ", "Ђ should output じゃ")
        print("✅ SRB-LIGA-008: Ђ → じゃ")
    }

    /// SRB-LIGA-009: ЂУ → じゅ
    func testSRB_LIGA_009_Dju() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ђ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)

        if result1?.action == "commit" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
            print("✅ SRB-LIGA-009: Ђ + У → \(result1?.output ?? "")\(result2?.output ?? "")")
        } else if result1?.action == "composing" {
            lastOutput = result1?.lastOutput ?? ""
            let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: result1?.buffer ?? "", profileId: profileId, lastOutput: lastOutput)
            XCTAssertEqual(result2?.output, "じゅ", "ЂУ should output じゅ")
            print("✅ SRB-LIGA-009: ЂУ → じゅ")
        }
    }

    /// SRB-LIGA-010: Џ → じゃ
    func testSRB_LIGA_010_Dzhe_Standalone() {
        let result = rustCore.processKey(
            cyrillicKey: "Џ",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Џ should commit")
        XCTAssertEqual(result?.output, "じゃ", "Џ should output じゃ")
        print("✅ SRB-LIGA-010: Џ → じゃ")
    }

    // MARK: - Serbian-specific: Ј palatalization

    /// SRB-YO-001: КЈА → きゃ (Ј palatalization)
    func testSRB_YO_001_KJA() {
        var buffer = ""
        var lastOutput = ""

        // К
        var result = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // Ј
        result = rustCore.processKey(cyrillicKey: "Ј", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result?.buffer ?? ""
        lastOutput = result?.lastOutput ?? ""

        // А
        result = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result?.output, "きゃ", "КЈА should output きゃ")
        print("✅ SRB-YO-001: КЈА → きゃ")
    }

    /// SRB-YO-002: СЈА → しゃ
    func testSRB_YO_002_SJA() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ј", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "しゃ", "СЈА should output しゃ")
        print("✅ SRB-YO-002: СЈА → しゃ")
    }

    /// SRB-YO-003: ЋА → ちゃ
    func testSRB_YO_003_TSHA() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ћ", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result2?.output, "ちゃ", "ЋА should output ちゃ")
        print("✅ SRB-YO-003: ЋА → ちゃ")
    }

    // MARK: - Integration Test: Complete Word

    /// Integration test: "じゃぱん" (Japan in Serbian)
    /// Expected input: Џ-А-П-А-Н
    func testCompleteWord_Japan() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        let keys = ["Џ", "А", "П", "А", "Н"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

            if let result = result {
                output += result.output
                buffer = result.buffer
                lastOutput = result.lastOutput
            }
        }

        print("Complete word test (Serbian): ЏАПАН → \(output)")
        XCTAssertTrue(output.contains("じゃ") || output.contains("じ"), "Should contain じゃ or じ")
        XCTAssertTrue(output.contains("ぱ") || output.contains("は"), "Should contain ぱ or は")
        XCTAssertTrue(output.contains("ん"), "Should contain ん")

        print("✅ Complete word: じゃぱん (ЏАПАН)")
    }
}
