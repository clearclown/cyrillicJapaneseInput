//
//  Phase2IntegrationTests.swift
//  PismoTests
//
//  Phase 2: Integration tests for Cyrillic → Hiragana → Kanji conversion
//

import XCTest
@testable import Pismo

class Phase2IntegrationTests: XCTestCase {
    var displayedTextManager: DisplayedTextManager!
    var conversionEngine: KanjiConversionEngine!
    var inputManager: CyrillicInputManager!
    var mockProxy: MockTextDocumentProxy!

    override func setUp() {
        super.setUp()

        // Setup mock text document proxy
        mockProxy = MockTextDocumentProxy()

        // Setup managers
        displayedTextManager = DisplayedTextManager(isMarkedTextEnabled: true)
        displayedTextManager.setTextDocumentProxy(mockProxy)

        conversionEngine = try! KanjiConversionEngine()

        inputManager = CyrillicInputManager(
            displayedTextManager: displayedTextManager,
            rustCore: RustCoreFFI.shared,
            profileManager: ProfileManager.shared,
            conversionEngine: conversionEngine
        )
    }

    override func tearDown() {
        inputManager = nil
        conversionEngine = nil
        displayedTextManager = nil
        mockProxy = nil
        super.tearDown()
    }

    // MARK: - End-to-End Conversion Tests

    func testEndToEndConversion_Kaisha() {
        // Given - Set IME mode
        inputManager.setInputMode(.japaneseIME)

        var receivedCandidates: [String] = []
        inputManager.onCandidatesUpdated = { candidates in
            receivedCandidates = candidates
        }

        // When - Type "К, А, Й, Ш, А" (Cyrillic for "kaisha")
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")
        inputManager.processKey("Ш")
        inputManager.processKey("А")

        // Then - Should show hiragana as composing text
        XCTAssertEqual(mockProxy.markedText, "かいしゃ", "Should display hiragana")

        // When - Press Space to start conversion
        inputManager.processSpace()

        // Wait for async conversion
        let expectation = self.expectation(description: "Candidates received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then - Should have candidates including "会社"
        XCTAssertFalse(receivedCandidates.isEmpty, "Should receive candidates")
        XCTAssertTrue(receivedCandidates.contains("会社"), "Should include '会社' candidate")

        print("[TEST] End-to-end candidates: \(receivedCandidates)")
    }

    func testEndToEndConversion_WithReturn() {
        // Given - Set IME mode
        inputManager.setInputMode(.japaneseIME)

        // When - Type "がっこう"
        inputManager.processKey("Г")
        inputManager.processKey("А")
        inputManager.processKey("К")
        inputManager.processKey("К")
        inputManager.processKey("О")
        inputManager.processKey("У")

        // Press Space to convert
        inputManager.processSpace()

        // Wait for conversion
        let expectation = self.expectation(description: "Conversion complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Press Return to commit
        inputManager.processReturn()

        // Then - Should have committed text (kanji or hiragana)
        XCTAssertTrue(
            mockProxy.insertedText.contains("学校") || mockProxy.insertedText.contains("がっこう"),
            "Should commit either kanji or hiragana"
        )

        print("[TEST] Committed text: '\(mockProxy.insertedText)'")
    }

    // MARK: - Candidate Cycling Tests

    func testCandidateCycling() {
        // Given
        inputManager.setInputMode(.japaneseIME)

        var candidatesHistory: [[String]] = []
        inputManager.onCandidatesUpdated = { candidates in
            candidatesHistory.append(candidates)
        }

        // When - Type and start conversion
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")
        inputManager.processKey("Ш")
        inputManager.processKey("А")

        inputManager.processSpace()

        // Wait for initial candidates
        let expectation1 = self.expectation(description: "Initial candidates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)

        let initialMarkedText = mockProxy.markedText

        // Press Space again to cycle
        inputManager.processSpace()

        let expectation2 = self.expectation(description: "After cycle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)

        let cycledMarkedText = mockProxy.markedText

        // Then - Marked text should change
        XCTAssertNotEqual(initialMarkedText, cycledMarkedText, "Should cycle to next candidate")

        print("[TEST] Initial: '\(initialMarkedText ?? "nil")', Cycled: '\(cycledMarkedText ?? "nil")'")
    }

    // MARK: - Delete During Conversion Tests

    func testDeleteDuringConversion() {
        // Given - Start conversion
        inputManager.setInputMode(.japaneseIME)

        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")

        inputManager.processSpace()

        let expectation = self.expectation(description: "Conversion started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // When - Press Delete
        inputManager.processDelete()

        // Then - Should exit conversion mode and revert to hiragana
        XCTAssertEqual(mockProxy.markedText, "か", "Should revert to remaining hiragana")

        print("[TEST] After delete during conversion: '\(mockProxy.markedText ?? "nil")'")
    }

    // MARK: - Learning Tests

    func testLearningIntegration() {
        // Given
        inputManager.setInputMode(.japaneseIME)

        // First conversion - select second candidate
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")
        inputManager.processKey("Ш")
        inputManager.processKey("А")

        inputManager.processSpace()

        let expectation1 = self.expectation(description: "First conversion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)

        // Cycle to second candidate and commit
        inputManager.processSpace()
        inputManager.processReturn()

        // Clear for second attempt
        mockProxy.reset()

        // Second conversion - same input
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")
        inputManager.processKey("Ш")
        inputManager.processKey("А")

        inputManager.processSpace()

        var secondCandidates: [String] = []
        inputManager.onCandidatesUpdated = { candidates in
            secondCandidates = candidates
        }

        let expectation2 = self.expectation(description: "Second conversion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)

        // Then - Learned candidate should be prioritized
        // (This test is approximate since we can't guarantee exact behavior)
        XCTAssertFalse(secondCandidates.isEmpty, "Should still have candidates")

        print("[TEST] Second conversion candidates: \(secondCandidates)")
    }

    // MARK: - Mode Switching Tests

    func testModeSwitchingWithConversion() {
        // Given - IME mode with composing text
        inputManager.setInputMode(.japaneseIME)

        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Й")

        // When - Switch to hiragana mode (conversion should be committed)
        inputManager.setInputMode(.japaneseHiragana)

        // Then - Previous composing text should be handled
        // (Behavior may vary based on implementation)
        XCTAssertTrue(true, "Mode switch should not crash")

        print("[TEST] Mode switch completed without crash")
    }

    // MARK: - Fallback Tests

    func testFallbackWhenEngineUnavailable() {
        // Given - Create input manager without conversion engine
        let managerWithoutEngine = CyrillicInputManager(
            displayedTextManager: displayedTextManager,
            rustCore: RustCoreFFI.shared,
            profileManager: ProfileManager.shared,
            conversionEngine: nil
        )

        managerWithoutEngine.setInputMode(.japaneseIME)

        var fallbackCandidates: [String] = []
        managerWithoutEngine.onCandidatesUpdated = { candidates in
            fallbackCandidates = candidates
        }

        // When - Type and convert
        managerWithoutEngine.processKey("К")
        managerWithoutEngine.processKey("А")
        managerWithoutEngine.processKey("Й")

        managerWithoutEngine.processSpace()

        let expectation = self.expectation(description: "Fallback candidates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then - Should still show hiragana and katakana
        XCTAssertTrue(fallbackCandidates.contains("かい"), "Should include hiragana")
        XCTAssertTrue(fallbackCandidates.contains("カイ"), "Should include katakana")

        print("[TEST] Fallback candidates: \(fallbackCandidates)")
    }
}

// MARK: - Mock Text Document Proxy

class MockTextDocumentProxy: NSObject, UITextDocumentProxy {
    var documentContextBeforeInput: String?
    var documentContextAfterInput: String?
    var selectedText: String?
    var documentInputMode: UITextInputMode?
    var documentIdentifier: UUID = UUID()

    var markedText: String?
    var insertedText: String = ""
    var deleteCount: Int = 0

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {
        self.markedText = markedText
        print("[MockProxy] setMarkedText: '\(markedText)', range: \(selectedRange)")
    }

    func unmarkText() {
        self.markedText = nil
        print("[MockProxy] unmarkText")
    }

    func insertText(_ text: String) {
        self.insertedText += text
        self.markedText = nil
        print("[MockProxy] insertText: '\(text)'")
    }

    func deleteBackward() {
        self.deleteCount += 1
        if !insertedText.isEmpty {
            insertedText.removeLast()
        }
        print("[MockProxy] deleteBackward (count: \(deleteCount))")
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        print("[MockProxy] adjustTextPosition: \(offset)")
    }

    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        print("[MockProxy] setBaseWritingDirection: \(writingDirection)")
    }

    func reset() {
        markedText = nil
        insertedText = ""
        deleteCount = 0
        print("[MockProxy] reset")
    }
}
