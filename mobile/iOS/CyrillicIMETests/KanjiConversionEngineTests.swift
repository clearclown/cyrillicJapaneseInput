//
//  KanjiConversionEngineTests.swift
//  PismoTests
//
//  Phase 2: Unit tests for KanjiConversionEngine
//

import XCTest
@testable import Pismo

class KanjiConversionEngineTests: XCTestCase {
    var engine: KanjiConversionEngine!

    override func setUp() {
        super.setUp()
        engine = try! KanjiConversionEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Conversion Tests

    func testRequestCandidatesForKaisha() async throws {
        // Given
        let input = "かいしゃ"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then
        XCTAssertFalse(candidates.isEmpty, "Should return candidates for '\(input)'")
        XCTAssertTrue(candidates.contains { $0.text == "会社" }, "Should include '会社'")
        XCTAssertTrue(candidates.contains { $0.text == "かいしゃ" }, "Should include hiragana as-is")

        print("[TEST] Candidates for '\(input)': \(candidates.map { $0.text })")
    }

    func testRequestCandidatesForGakkou() async throws {
        // Given
        let input = "がっこう"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.contains { $0.text == "学校" })

        print("[TEST] Candidates for '\(input)': \(candidates.map { $0.text })")
    }

    func testRequestCandidatesForSensei() async throws {
        // Given
        let input = "せんせい"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.contains { $0.text == "先生" })

        print("[TEST] Candidates for '\(input)': \(candidates.map { $0.text })")
    }

    // MARK: - Edge Cases

    func testRequestCandidatesForEmptyString() async {
        do {
            // When
            _ = try await engine.requestCandidates(for: "", maxCount: 10)

            // Then
            XCTFail("Should throw error for empty input")
        } catch ConversionError.invalidInput {
            // Expected
            print("[TEST] Correctly rejected empty input")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestCandidatesForUnknownWord() async throws {
        // Given - a nonsense word not in dictionary
        let input = "ぞぞぞぞ"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then - should at least return hiragana and katakana
        XCTAssertTrue(candidates.contains { $0.text == "ぞぞぞぞ" }, "Should include hiragana")
        XCTAssertTrue(candidates.contains { $0.text == "ゾゾゾゾ" }, "Should include katakana")

        print("[TEST] Candidates for unknown word '\(input)': \(candidates.map { $0.text })")
    }

    // MARK: - Learning Tests

    func testLearning() async throws {
        // Given - initial candidates
        let input = "かいしゃ"
        let initialCandidates = try await engine.requestCandidates(for: input, maxCount: 10)
        let firstCandidate = initialCandidates[0]

        // When - learn a different candidate
        let targetCandidate = initialCandidates.first { $0.text == "開車" }!
        engine.learn(input: input, selected: targetCandidate)

        // Then - target should now be first
        let learnedCandidates = try await engine.requestCandidates(for: input, maxCount: 10)
        XCTAssertEqual(learnedCandidates[0].text, "開車", "Learned candidate should be first")
        XCTAssertEqual(learnedCandidates[0].type, .userDictionary, "Should be from user dictionary")

        print("[TEST] Before learning: \(firstCandidate.text)")
        print("[TEST] After learning: \(learnedCandidates[0].text)")
    }

    func testClearLearningData() async throws {
        // Given - learned data
        let input = "かいしゃ"
        let candidate = Candidate(text: "開車", type: .kanji, score: 1.0, metadata: nil)
        engine.learn(input: input, selected: candidate)

        // When - clear learning data
        engine.clearLearningData()

        // Then - learned data should be gone
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)
        XCTAssertNotEqual(candidates[0].type, .userDictionary, "Should not use user dictionary after clearing")

        print("[TEST] After clearing learning data, first candidate: \(candidates[0].text)")
    }

    // MARK: - Candidate Properties Tests

    func testCandidateTypeClassification() async throws {
        // Given
        let input = "かいしゃ"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then - verify types
        let kanjiCandidates = candidates.filter { $0.type == .kanji }
        let hiraganaCandidates = candidates.filter { $0.type == .hiragana }
        let katakanaCandidates = candidates.filter { $0.type == .katakana }

        XCTAssertFalse(kanjiCandidates.isEmpty, "Should have kanji candidates")
        XCTAssertEqual(hiraganaCandidates.count, 1, "Should have exactly 1 hiragana candidate")
        XCTAssertEqual(katakanaCandidates.count, 1, "Should have exactly 1 katakana candidate")

        print("[TEST] Kanji: \(kanjiCandidates.count), Hiragana: \(hiraganaCandidates.count), Katakana: \(katakanaCandidates.count)")
    }

    func testCandidateScoreOrdering() async throws {
        // Given
        let input = "かいしゃ"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then - scores should be descending
        for i in 0..<(candidates.count - 1) {
            XCTAssertGreaterThanOrEqual(
                candidates[i].score,
                candidates[i + 1].score,
                "Candidates should be sorted by score (descending)"
            )
        }

        print("[TEST] Candidate scores: \(candidates.map { $0.score })")
    }

    func testNoDuplicateCandidates() async throws {
        // Given
        let input = "かいしゃ"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then - no duplicates
        let uniqueTexts = Set(candidates.map { $0.text })
        XCTAssertEqual(candidates.count, uniqueTexts.count, "Should not have duplicate candidates")

        print("[TEST] All candidates are unique: \(candidates.map { $0.text })")
    }

    // MARK: - Katakana Conversion Tests

    func testKatakanaConversion() async throws {
        // Given
        let input = "めーる"

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: 10)

        // Then
        XCTAssertTrue(candidates.contains { $0.text == "メール" }, "Should convert to katakana")

        print("[TEST] Candidates for '\(input)': \(candidates.map { $0.text })")
    }

    // MARK: - Max Count Tests

    func testMaxCandidateCount() async throws {
        // Given
        let input = "かいしゃ"
        let maxCount = 3

        // When
        let candidates = try await engine.requestCandidates(for: input, maxCount: maxCount)

        // Then
        XCTAssertLessThanOrEqual(candidates.count, maxCount, "Should respect maxCount")

        print("[TEST] Requested \(maxCount), got \(candidates.count) candidates")
    }

    // MARK: - Performance Tests

    func testConversionPerformance() throws {
        // Given
        let input = "かいしゃ"

        // When/Then - should complete within 100ms
        measure {
            let expectation = self.expectation(description: "Conversion completes")

            Task {
                _ = try? await engine.requestCandidates(for: input, maxCount: 10)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 0.1) // 100ms
        }
    }
}
