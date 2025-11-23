//
//  CyrillicComposingTextTests.swift
//  CyrillicIMETests
//
//  Unit tests for CyrillicComposingText (Phase 1)
//

import XCTest
@testable import Pismo

class CyrillicComposingTextTests: XCTestCase {
    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        // Given/When: Default initialization
        let composing = CyrillicComposingText()

        // Then: Should have empty state
        XCTAssertTrue(composing.isEmpty)
        XCTAssertEqual(composing.cyrillicKeys, [])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "")
        XCTAssertEqual(composing.cursorPosition, 0)
        XCTAssertEqual(composing.hiraganaCount, 0)
    }

    func testCustomInitialization() {
        // Given/When: Custom initialization
        let composing = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        // Then: Should have initialized state
        XCTAssertFalse(composing.isEmpty)
        XCTAssertEqual(composing.cyrillicKeys, ["К", "А"])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "か")
        XCTAssertEqual(composing.cursorPosition, 1)
        XCTAssertEqual(composing.hiraganaCount, 1)
    }

    func testCustomInitializationCursorClamping() {
        // Given/When: Cursor position exceeds hiragana length
        let composing = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 100
        )

        // Then: Cursor should be clamped to hiragana length
        XCTAssertEqual(composing.cursorPosition, 1)
    }

    // MARK: - Append Tests

    func testAppendSingleKey() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()
        let result = ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil)

        // When: Appending key
        composing.append(key: "А", result: result)

        // Then: Should update state
        XCTAssertEqual(composing.cyrillicKeys, ["А"])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "あ")
        XCTAssertEqual(composing.cursorPosition, 1)
    }

    func testAppendMultipleKeys() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Appending multiple keys
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))

        // Then: Should accumulate keys and hiragana
        XCTAssertEqual(composing.cyrillicKeys, ["К", "А"])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "か")
        XCTAssertEqual(composing.cursorPosition, 1)
    }

    func testAppendAccumulatesHiragana() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Appending keys that produce hiragana
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.append(key: "Й", result: ConversionResult(action: "commit", output: "い", buffer: "", lastOutput: "", lastVowelType: nil))

        // Then: Hiragana should accumulate (not replace)
        XCTAssertEqual(composing.cyrillicKeys, ["К", "А", "Й"])
        XCTAssertEqual(composing.hiraganaTarget, "かい")
        XCTAssertEqual(composing.cursorPosition, 2)
    }

    func testAppendWithBuffer() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Appending key that updates buffer
        let result = ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil)
        composing.append(key: "К", result: result)

        // Then: Buffer should be updated
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
        XCTAssertEqual(composing.cyrillicBuffer, "К")
        XCTAssertEqual(composing.hiraganaTarget, "")
        XCTAssertEqual(composing.cursorPosition, 0)
    }

    func testAppendEmptyOutput() {
        // Given: Composing text with existing hiragana
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Appending key with empty output
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))

        // Then: Hiragana should not change
        XCTAssertEqual(composing.cyrillicKeys, ["А", "К"])
        XCTAssertEqual(composing.hiraganaTarget, "あ")
        XCTAssertEqual(composing.cyrillicBuffer, "К")
        XCTAssertEqual(composing.cursorPosition, 1)
    }

    // MARK: - Delete Backward Tests

    func testDeleteBackwardSuccess() {
        // Given: Composing text with keys
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.append(key: "Й", result: ConversionResult(action: "commit", output: "い", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Deleting backward
        let success = composing.deleteBackward()

        // Then: Should remove last key
        XCTAssertTrue(success)
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
    }

    func testDeleteBackwardEmpty() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Deleting backward
        let success = composing.deleteBackward()

        // Then: Should return false
        XCTAssertFalse(success)
        XCTAssertEqual(composing.cyrillicKeys, [])
    }

    func testDeleteBackwardMultiple() {
        // Given: Composing text with multiple keys
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.append(key: "Й", result: ConversionResult(action: "commit", output: "い", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.append(key: "Ш", result: ConversionResult(action: "commit", output: "し", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Deleting multiple times
        let success1 = composing.deleteBackward()
        let success2 = composing.deleteBackward()

        // Then: Should remove keys in reverse order
        XCTAssertTrue(success1)
        XCTAssertTrue(success2)
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
    }

    func testDeleteBackwardUntilEmpty() {
        // Given: Composing text with one key
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Deleting until empty
        let success1 = composing.deleteBackward()
        let success2 = composing.deleteBackward()

        // Then: First should succeed, second should fail
        XCTAssertTrue(success1)
        XCTAssertFalse(success2)
        XCTAssertTrue(composing.isEmpty)
    }

    // MARK: - Clear Tests

    func testClear() {
        // Given: Composing text with data
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Clearing
        composing.clear()

        // Then: Should reset to empty state
        XCTAssertTrue(composing.isEmpty)
        XCTAssertEqual(composing.cyrillicKeys, [])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "")
        XCTAssertEqual(composing.cursorPosition, 0)
    }

    func testClearAlreadyEmpty() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Clearing
        composing.clear()

        // Then: Should remain empty
        XCTAssertTrue(composing.isEmpty)
    }

    // MARK: - Cursor Position Tests

    func testUpdateCursorPosition() {
        // Given: Composing text with hiragana
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あいうえお", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Updating cursor position
        composing.updateCursorPosition(3)

        // Then: Cursor should be updated
        XCTAssertEqual(composing.cursorPosition, 3)
    }

    func testUpdateCursorPositionClamping() {
        // Given: Composing text with hiragana
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "abc", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Setting cursor beyond bounds
        composing.updateCursorPosition(10)

        // Then: Should clamp to length
        XCTAssertEqual(composing.cursorPosition, 3)

        // When: Setting negative cursor
        composing.updateCursorPosition(-1)

        // Then: Should clamp to 0
        XCTAssertEqual(composing.cursorPosition, 0)
    }

    func testUpdateCursorPositionZero() {
        // Given: Composing text with hiragana
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Setting cursor to 0
        composing.updateCursorPosition(0)

        // Then: Cursor should be at start
        XCTAssertEqual(composing.cursorPosition, 0)
    }

    // MARK: - SetHiragana Tests

    func testSetHiragana() {
        // Given: Composing text with existing data
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "commit", output: "old", buffer: "OLD", lastOutput: "", lastVowelType: nil))

        // When: Setting new hiragana
        composing.setHiragana("new", buffer: "NEW")

        // Then: Should update hiragana and buffer
        XCTAssertEqual(composing.hiraganaTarget, "new")
        XCTAssertEqual(composing.cyrillicBuffer, "NEW")
        XCTAssertEqual(composing.cursorPosition, 3)
        // Note: cyrillicKeys should remain unchanged
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
    }

    func testSetHiraganaEmpty() {
        // Given: Composing text with data
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Setting empty hiragana
        composing.setHiragana("", buffer: "")

        // Then: Should clear hiragana and buffer
        XCTAssertEqual(composing.hiraganaTarget, "")
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.cursorPosition, 0)
    }

    // MARK: - Query Methods Tests

    func testConvertTarget() {
        // Given: Composing text with hiragana
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "commit", output: "かいしゃ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Getting convert target
        let target = composing.convertTarget

        // Then: Should return hiragana
        XCTAssertEqual(target, "かいしゃ")
    }

    func testTextBeforeCursor() {
        // Given: Composing text with cursor in middle
        var composing = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "あいうえお",
            cursorPosition: 3
        )

        // When: Getting text before cursor
        let textBefore = composing.textBeforeCursor

        // Then: Should return text before cursor position
        XCTAssertEqual(textBefore, "あいう")
    }

    func testTextBeforeCursorAtStart() {
        // Given: Composing text with cursor at start
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あいう", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.updateCursorPosition(0)

        // When: Getting text before cursor
        let textBefore = composing.textBeforeCursor

        // Then: Should return empty string
        XCTAssertEqual(textBefore, "")
    }

    func testTextAfterCursor() {
        // Given: Composing text with cursor in middle
        var composing = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "あいうえお",
            cursorPosition: 2
        )

        // When: Getting text after cursor
        let textAfter = composing.textAfterCursor

        // Then: Should return text after cursor position
        XCTAssertEqual(textAfter, "うえお")
    }

    func testTextAfterCursorAtEnd() {
        // Given: Composing text with cursor at end
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あいう", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Getting text after cursor
        let textAfter = composing.textAfterCursor

        // Then: Should return empty string
        XCTAssertEqual(textAfter, "")
    }

    // MARK: - isEmpty Tests

    func testIsEmptyWhenEmpty() {
        // Given: Empty composing text
        let composing = CyrillicComposingText()

        // Then: Should be empty
        XCTAssertTrue(composing.isEmpty)
    }

    func testIsEmptyWithKeys() {
        // Given: Composing text with keys
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // Then: Should not be empty
        XCTAssertFalse(composing.isEmpty)
    }

    func testIsEmptyWithBuffer() {
        // Given: Composing text with buffer only
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))

        // Then: Should not be empty
        XCTAssertFalse(composing.isEmpty)
    }

    func testIsEmptyAfterClear() {
        // Given: Composing text with data
        var composing = CyrillicComposingText()
        composing.append(key: "А", result: ConversionResult(action: "commit", output: "あ", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Clearing
        composing.clear()

        // Then: Should be empty
        XCTAssertTrue(composing.isEmpty)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        // Given: Two identical composing texts
        let composing1 = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        let composing2 = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        // Then: Should be equal
        XCTAssertEqual(composing1, composing2)
    }

    func testInequalityDifferentKeys() {
        // Given: Two composing texts with different keys
        let composing1 = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        let composing2 = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        // Then: Should not be equal
        XCTAssertNotEqual(composing1, composing2)
    }

    func testInequalityDifferentHiragana() {
        // Given: Two composing texts with different hiragana
        let composing1 = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        let composing2 = CyrillicComposingText(
            cyrillicKeys: ["К"],
            cyrillicBuffer: "",
            hiraganaTarget: "き",
            cursorPosition: 1
        )

        // Then: Should not be equal
        XCTAssertNotEqual(composing1, composing2)
    }

    // MARK: - CustomStringConvertible Tests

    func testDescription() {
        // Given: Composing text with data
        let composing = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        // When: Getting description
        let description = composing.description

        // Then: Should contain relevant information
        XCTAssertTrue(description.contains("CyrillicComposingText"))
        XCTAssertTrue(description.contains("К"))
        XCTAssertTrue(description.contains("А"))
        XCTAssertTrue(description.contains("か"))
    }

    func testDebugDescription() {
        // Given: Composing text with data
        let composing = CyrillicComposingText(
            cyrillicKeys: ["К", "А"],
            cyrillicBuffer: "BUF",
            hiraganaTarget: "か",
            cursorPosition: 1
        )

        // When: Getting debug description
        let debugDesc = composing.debugDescription

        // Then: Should contain detailed information
        XCTAssertTrue(debugDesc.contains("CyrillicComposingText"))
        XCTAssertTrue(debugDesc.contains("keys"))
        XCTAssertTrue(debugDesc.contains("buffer"))
        XCTAssertTrue(debugDesc.contains("hiragana"))
        XCTAssertTrue(debugDesc.contains("cursor"))
    }

    // MARK: - Integration Tests

    func testCompleteInputSequence() {
        // Given: Empty composing text
        var composing = CyrillicComposingText()

        // When: Simulating complete input sequence КАЙ -> かい
        composing.append(key: "К", result: ConversionResult(action: "composing", output: "", buffer: "К", lastOutput: "", lastVowelType: nil))
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
        XCTAssertEqual(composing.cyrillicBuffer, "К")
        XCTAssertEqual(composing.hiraganaTarget, "")

        composing.append(key: "А", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))
        XCTAssertEqual(composing.cyrillicKeys, ["К", "А"])
        XCTAssertEqual(composing.cyrillicBuffer, "")
        XCTAssertEqual(composing.hiraganaTarget, "か")

        composing.append(key: "Й", result: ConversionResult(action: "commit", output: "い", buffer: "", lastOutput: "", lastVowelType: nil))
        XCTAssertEqual(composing.cyrillicKeys, ["К", "А", "Й"])
        XCTAssertEqual(composing.hiraganaTarget, "かい")

        // Then: Final state should be correct
        XCTAssertFalse(composing.isEmpty)
        XCTAssertEqual(composing.hiraganaCount, 2)
    }

    func testDeleteAndRebuildScenario() {
        // Given: Composing text with multiple characters
        var composing = CyrillicComposingText()
        composing.append(key: "К", result: ConversionResult(action: "commit", output: "か", buffer: "", lastOutput: "", lastVowelType: nil))
        composing.append(key: "Й", result: ConversionResult(action: "commit", output: "い", buffer: "", lastOutput: "", lastVowelType: nil))

        // When: Deleting last key
        let deleted = composing.deleteBackward()

        // Then: Keys should be updated (rebuild happens in InputManager)
        XCTAssertTrue(deleted)
        XCTAssertEqual(composing.cyrillicKeys, ["К"])
        // Note: Hiragana is not automatically updated here
        // CyrillicInputManager's rebuildComposingText() handles that
    }
}
