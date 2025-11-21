//
//  UserDictionaryTests.swift
//  PismoTests
//
//  Phase 2: Unit tests for UserDictionary
//

import XCTest
@testable import Pismo

class UserDictionaryTests: XCTestCase {
    var dictionary: UserDictionary!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        // Use test-specific UserDefaults
        testDefaults = UserDefaults(suiteName: "com.pismo.test")!
        testDefaults.removePersistentDomain(forName: "com.pismo.test")

        dictionary = UserDictionary(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.pismo.test")
        dictionary = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Basic Add/Lookup Tests

    func testAddAndLookup() {
        // Given
        let input = "かいしゃ"
        let output = "会社"

        // When
        dictionary.add(input: input, output: output)
        let results = dictionary.lookup(input)

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].text, output)
        XCTAssertEqual(results[0].type, .userDictionary)

        print("[TEST] Added and found: '\(input)' → '\(output)'")
    }

    func testLookupNonExistent() {
        // Given
        let input = "zzzzz"

        // When
        let results = dictionary.lookup(input)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty for non-existent input")

        print("[TEST] Lookup for non-existent input returned empty")
    }

    func testAddMultipleOutputsForSameInput() {
        // Given
        let input = "かいしゃ"

        // When
        dictionary.add(input: input, output: "会社")
        dictionary.add(input: input, output: "開車")
        dictionary.add(input: input, output: "快謝")

        // Then
        let results = dictionary.lookup(input)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].text, "快謝") // Most recent
        XCTAssertEqual(results[1].text, "開車")
        XCTAssertEqual(results[2].text, "会社") // Oldest

        print("[TEST] Multiple outputs: \(results.map { $0.text })")
    }

    // MARK: - Ordering Tests

    func testRecentlyUsedComesFirst() {
        // Given
        let input = "かいしゃ"
        dictionary.add(input: input, output: "会社")
        dictionary.add(input: input, output: "開車")

        // When - re-add "会社"
        dictionary.add(input: input, output: "会社")

        // Then - "会社" should be first now
        let results = dictionary.lookup(input)
        XCTAssertEqual(results[0].text, "会社", "Most recently used should be first")

        print("[TEST] After re-adding, order: \(results.map { $0.text })")
    }

    func testScoreDecreases() {
        // Given
        let input = "かいしゃ"
        dictionary.add(input: input, output: "会社")
        dictionary.add(input: input, output: "開車")
        dictionary.add(input: input, output: "快謝")

        // When
        let results = dictionary.lookup(input)

        // Then - scores should decrease
        XCTAssertGreaterThan(results[0].score, results[1].score)
        XCTAssertGreaterThan(results[1].score, results[2].score)

        print("[TEST] Scores: \(results.map { $0.score })")
    }

    // MARK: - Limit Tests

    func testMaxEntriesPerInput() {
        // Given
        let input = "てすと"

        // When - add more than 10 entries
        for i in 1...15 {
            dictionary.add(input: input, output: "テスト\(i)")
        }

        // Then - should only keep 10
        let results = dictionary.lookup(input)
        XCTAssertEqual(results.count, 10, "Should limit to 10 entries per input")

        print("[TEST] Added 15, kept \(results.count)")
    }

    // MARK: - Remove Tests

    func testRemove() {
        // Given
        let input = "かいしゃ"
        dictionary.add(input: input, output: "会社")
        dictionary.add(input: input, output: "開車")

        // When
        dictionary.remove(input: input, output: "会社")

        // Then
        let results = dictionary.lookup(input)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].text, "開車")

        print("[TEST] After removal: \(results.map { $0.text })")
    }

    func testRemoveLastEntry() {
        // Given
        let input = "かいしゃ"
        dictionary.add(input: input, output: "会社")

        // When
        dictionary.remove(input: input, output: "会社")

        // Then
        let results = dictionary.lookup(input)
        XCTAssertTrue(results.isEmpty, "Should remove input key when last entry is removed")

        print("[TEST] After removing last entry, lookup returns empty")
    }

    // MARK: - Clear Tests

    func testClear() {
        // Given
        dictionary.add(input: "かいしゃ", output: "会社")
        dictionary.add(input: "がっこう", output: "学校")
        dictionary.add(input: "せんせい", output: "先生")

        // When
        dictionary.clear()

        // Then
        XCTAssertTrue(dictionary.lookup("かいしゃ").isEmpty)
        XCTAssertTrue(dictionary.lookup("がっこう").isEmpty)
        XCTAssertTrue(dictionary.lookup("せんせい").isEmpty)

        let stats = dictionary.getStatistics()
        XCTAssertEqual(stats.totalInputs, 0)
        XCTAssertEqual(stats.totalOutputs, 0)

        print("[TEST] After clear, all lookups return empty")
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        // Given
        let input = "かいしゃ"
        let output = "会社"
        dictionary.add(input: input, output: output)

        // When - create new dictionary with same UserDefaults
        let newDictionary = UserDictionary(userDefaults: testDefaults)

        // Then
        let results = newDictionary.lookup(input)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].text, output)

        print("[TEST] Data persisted across dictionary instances")
    }

    func testPersistenceAfterMultipleOperations() {
        // Given
        dictionary.add(input: "かいしゃ", output: "会社")
        dictionary.add(input: "かいしゃ", output: "開車")
        dictionary.add(input: "がっこう", output: "学校")
        dictionary.remove(input: "かいしゃ", output: "会社")

        // When - create new dictionary
        let newDictionary = UserDictionary(userDefaults: testDefaults)

        // Then
        let kaishaResults = newDictionary.lookup("かいしゃ")
        XCTAssertEqual(kaishaResults.count, 1)
        XCTAssertEqual(kaishaResults[0].text, "開車")

        let gakkouResults = newDictionary.lookup("がっこう")
        XCTAssertEqual(gakkouResults.count, 1)
        XCTAssertEqual(gakkouResults[0].text, "学校")

        print("[TEST] Complex operations persisted correctly")
    }

    // MARK: - Statistics Tests

    func testGetStatistics() {
        // Given
        dictionary.add(input: "かいしゃ", output: "会社")
        dictionary.add(input: "かいしゃ", output: "開車")
        dictionary.add(input: "がっこう", output: "学校")

        // When
        let stats = dictionary.getStatistics()

        // Then
        XCTAssertEqual(stats.totalInputs, 2, "Should have 2 unique inputs")
        XCTAssertEqual(stats.totalOutputs, 3, "Should have 3 total outputs")

        print("[TEST] Stats: \(stats.totalInputs) inputs, \(stats.totalOutputs) outputs")
    }

    func testGetAllEntries() {
        // Given
        dictionary.add(input: "かいしゃ", output: "会社")
        dictionary.add(input: "がっこう", output: "学校")

        // When
        let allEntries = dictionary.getAllEntries()

        // Then
        XCTAssertEqual(allEntries.count, 2)
        XCTAssertEqual(allEntries["かいしゃ"], ["会社"])
        XCTAssertEqual(allEntries["がっこう"], ["学校"])

        print("[TEST] All entries: \(allEntries)")
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        // When
        dictionary.add(input: "", output: "テスト")
        let results = dictionary.lookup("")

        // Then
        XCTAssertEqual(results.count, 1, "Should handle empty input")
    }

    func testEmptyOutput() {
        // When
        dictionary.add(input: "てすと", output: "")
        let results = dictionary.lookup("てすと")

        // Then
        XCTAssertEqual(results.count, 1, "Should handle empty output")
        XCTAssertEqual(results[0].text, "")
    }

    func testSpecialCharacters() {
        // Given
        let input = "🎌🗾"
        let output = "日本"

        // When
        dictionary.add(input: input, output: output)
        let results = dictionary.lookup(input)

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].text, output)

        print("[TEST] Special characters handled: '\(input)' → '\(output)'")
    }

    // MARK: - Debug Tests

    #if DEBUG
    func testAddTestEntries() {
        // When
        dictionary.addTestEntries()

        // Then
        XCTAssertFalse(dictionary.lookup("かいしゃ").isEmpty)
        XCTAssertFalse(dictionary.lookup("がっこう").isEmpty)
        XCTAssertFalse(dictionary.lookup("せんせい").isEmpty)

        print("[TEST] Test entries added successfully")
    }

    func testPrintAllEntries() {
        // Given
        dictionary.add(input: "かいしゃ", output: "会社")
        dictionary.add(input: "がっこう", output: "学校")

        // When/Then - should not crash
        dictionary.printAllEntries()

        print("[TEST] Print all entries completed without crash")
    }
    #endif
}
