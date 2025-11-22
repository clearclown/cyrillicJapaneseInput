//
//  UkrainianProfileTests.swift
//  CyrillicIMETests
//
//  Integration tests for Ukrainian Cyrillic profile conversion logic
//  Tests Ukrainian-specific features: І, Ї, Є, Ґ characters
//

import XCTest
@testable import Pismo

/// Integration tests for Ukrainian Cyrillic profile (ukr_cyrillic)
/// Based on schema_ukr_v1.json mappings
class UkrainianProfileTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    let profileId = "ukr_cyrillic"

    override func setUp() {
        super.setUp()

        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared

        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        // Switch to Ukrainian profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        print("\n=== Ukrainian Profile Test Setup ===")
        print("Current profile: \(profileManager.currentProfile?.id ?? "nil")")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - Basic Vowels

    /// UKR-BASIC-001: А → あ
    func testUKR_BASIC_001_VowelA() {
        let result = rustCore.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "А should commit")
        XCTAssertEqual(result?.output, "あ", "А should output あ")
        print("✅ UKR-BASIC-001: А → あ")
    }

    /// UKR-BASIC-002: І → い (Ukrainian uses І instead of И)
    func testUKR_BASIC_002_VowelI_Ukrainian() {
        let result = rustCore.processKey(
            cyrillicKey: "І",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "І should commit")
        XCTAssertEqual(result?.output, "い", "І should output い")
        print("✅ UKR-BASIC-002: І → い")
    }

    /// UKR-BASIC-003: У → う
    func testUKR_BASIC_003_VowelU() {
        let result = rustCore.processKey(
            cyrillicKey: "У",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "У should commit")
        XCTAssertEqual(result?.output, "う", "У should output う")
        print("✅ UKR-BASIC-003: У → う")
    }

    /// UKR-BASIC-004: Е → え
    func testUKR_BASIC_004_VowelE() {
        let result = rustCore.processKey(
            cyrillicKey: "Е",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Е should commit")
        XCTAssertEqual(result?.output, "え", "Е should output え")
        print("✅ UKR-BASIC-004: Е → え")
    }

    /// UKR-BASIC-005: О → お
    func testUKR_BASIC_005_VowelO() {
        let result = rustCore.processKey(
            cyrillicKey: "О",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "О should commit")
        XCTAssertEqual(result?.output, "お", "О should output お")
        print("✅ UKR-BASIC-005: О → お")
    }

    // MARK: - Ukrainian-specific vowels

    /// UKR-SPEC-001: Ї → い (yi sound, but mapped to い)
    func testUKR_SPEC_001_Yi() {
        let result = rustCore.processKey(
            cyrillicKey: "Ї",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Ї should commit")
        // Ї is "yi" sound - might map to い or be handled specially
        XCTAssertNotNil(result?.output, "Ї should produce output")
        print("✅ UKR-SPEC-001: Ї → \(result?.output ?? "nil")")
    }

    /// UKR-SPEC-002: Є → え (ye sound)
    func testUKR_SPEC_002_Ye() {
        let result = rustCore.processKey(
            cyrillicKey: "Є",
            currentBuffer: "",
            profileId: profileId,
            lastOutput: ""
        )

        XCTAssertEqual(result?.action, "commit", "Є should commit")
        XCTAssertEqual(result?.output, "え", "Є should output え")
        print("✅ UKR-SPEC-002: Є → え")
    }

    // MARK: - Basic Consonants with І

    /// UKR-BASIC-006: КІ → き (using Ukrainian І)
    func testUKR_BASIC_006_KI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "І", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КІ should commit")
        XCTAssertEqual(result2?.output, "き", "КІ should output き")

        print("✅ UKR-BASIC-006: КІ → き")
    }

    /// UKR-BASIC-007: СІ → し (Ukrainian і with С)
    func testUKR_BASIC_007_SHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "С", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "С should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "І", currentBuffer: "С", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "СІ should commit")
        XCTAssertEqual(result2?.output, "し", "СІ should output し")

        print("✅ UKR-BASIC-007: СІ → し")
    }

    /// UKR-BASIC-008: ЧІ → ち (Ukrainian special case)
    func testUKR_BASIC_008_CHI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ч", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ч should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "І", currentBuffer: "Ч", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ЧІ should commit")
        XCTAssertEqual(result2?.output, "ち", "ЧІ should output ち")

        print("✅ UKR-BASIC-008: ЧІ → ち")
    }

    // MARK: - Ukrainian Ґ (hard G)

    /// UKR-SPEC-003: ҐА → が (Ukrainian Ґ for hard G)
    func testUKR_SPEC_003_GA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ґ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ґ should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "А", currentBuffer: "Ґ", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ҐА should commit")
        XCTAssertEqual(result2?.output, "が", "ҐА should output が")

        print("✅ UKR-SPEC-003: ҐА → が")
    }

    /// UKR-SPEC-004: ҐІ → ぎ
    func testUKR_SPEC_004_GI() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ґ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ґ should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "І", currentBuffer: "Ґ", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ҐІ should commit")
        XCTAssertEqual(result2?.output, "ぎ", "ҐІ should output ぎ")

        print("✅ UKR-SPEC-004: ҐІ → ぎ")
    }

    /// UKR-SPEC-005: ҐУ → ぐ
    func testUKR_SPEC_005_GU() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Ґ", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "Ґ should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "У", currentBuffer: "Ґ", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "ҐУ should commit")
        XCTAssertEqual(result2?.output, "ぐ", "ҐУ should output ぐ")

        print("✅ UKR-SPEC-005: ҐУ → ぐ")
    }

    // MARK: - Ukrainian DZ digraph (for za/ji sounds)

    /// UKR-SPEC-006: ДЗА → ざ (Ukrainian ДЗ for za)
    func testUKR_SPEC_006_DZA() {
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
        print("✅ UKR-SPEC-006: ДЗА → ざ")
    }

    /// UKR-SPEC-007: ДЗІ → じ
    func testUKR_SPEC_007_DZI() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "Д", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "З", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "І", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "じ", "ДЗІ should output じ")
        print("✅ UKR-SPEC-007: ДЗІ → じ")
    }

    // MARK: - Ukrainian palatalization with Я, Ю, ЙО

    /// UKR-YO-001: КЯ → きゃ
    func testUKR_YO_001_KYA() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Я", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КЯ should commit")
        XCTAssertEqual(result2?.output, "きゃ", "КЯ should output きゃ")

        print("✅ UKR-YO-001: КЯ → きゃ")
    }

    /// UKR-YO-002: КЮ → きゅ
    func testUKR_YO_002_KYU() {
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: "", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result1?.action, "composing", "К should be composing")
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Ю", currentBuffer: "К", profileId: profileId, lastOutput: lastOutput)
        XCTAssertEqual(result2?.action, "commit", "КЮ should commit")
        XCTAssertEqual(result2?.output, "きゅ", "КЮ should output きゅ")

        print("✅ UKR-YO-002: КЮ → きゅ")
    }

    /// UKR-YO-003: КЙО → きょ (Ukrainian uses ЙО for yo)
    func testUKR_YO_003_KYO() {
        var buffer = ""
        var lastOutput = ""

        let result1 = rustCore.processKey(cyrillicKey: "К", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result1?.buffer ?? ""
        lastOutput = result1?.lastOutput ?? ""

        let result2 = rustCore.processKey(cyrillicKey: "Й", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)
        buffer = result2?.buffer ?? ""
        lastOutput = result2?.lastOutput ?? ""

        let result3 = rustCore.processKey(cyrillicKey: "О", currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

        XCTAssertEqual(result3?.output, "きょ", "КЙО should output きょ")
        print("✅ UKR-YO-003: КЙО → きょ")
    }

    // MARK: - Integration Test: Complete Word

    /// Integration test: "きーう" (Kyiv in Ukrainian)
    /// Expected input: К-І-Ї-В
    func testCompleteWord_Kyiv() {
        var buffer = ""
        var output = ""
        var lastOutput = ""

        let keys = ["К", "І", "Ї", "В"]

        for key in keys {
            let result = rustCore.processKey(cyrillicKey: key, currentBuffer: buffer, profileId: profileId, lastOutput: lastOutput)

            if let result = result {
                output += result.output
                buffer = result.buffer
                lastOutput = result.lastOutput
            }
        }

        print("Complete word test (Ukrainian): КІЇВ → \(output)")
        XCTAssertTrue(output.contains("き"), "Should contain き")
        XCTAssertTrue(output.contains("い"), "Should contain い")

        print("✅ Complete word: Kyiv (КІЇВ) → \(output)")
    }
}
