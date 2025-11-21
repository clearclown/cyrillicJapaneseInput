//
//  DisplayedTextManagerTests.swift
//  CyrillicIMETests
//
//  Unit tests for DisplayedTextManager (Phase 1)
//

import XCTest
@testable import Pismo

class DisplayedTextManagerTests: XCTestCase {
    var manager: DisplayedTextManager!
    var mockProxy: MockUITextDocumentProxy!

    override func setUp() {
        super.setUp()
        manager = DisplayedTextManager(isMarkedTextEnabled: true)
        mockProxy = MockUITextDocumentProxy()
        manager.setTextDocumentProxy(mockProxy)
    }

    override func tearDown() {
        manager = nil
        mockProxy = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given: New DisplayedTextManager
        let newManager = DisplayedTextManager(isMarkedTextEnabled: true)

        // Then: Should have empty state
        XCTAssertEqual(newManager.composingText, "")
        XCTAssertNil(newManager.displayedLiveConversionText)
    }

    func testInitializationWithMarkedTextDisabled() {
        // Given: Manager with marked text disabled
        let newManager = DisplayedTextManager(isMarkedTextEnabled: false)

        // When: Setting proxy and updating text
        let proxy = MockUITextDocumentProxy()
        newManager.setTextDocumentProxy(proxy)
        newManager.updateComposingText("test")

        // Then: Should not use setMarkedText
        XCTAssertFalse(proxy.setMarkedTextCalled)
    }

    // MARK: - Proxy Management Tests

    func testSetTextDocumentProxy() {
        // Given: Fresh manager
        let newManager = DisplayedTextManager()
        let proxy = MockUITextDocumentProxy()

        // When: Setting proxy
        newManager.setTextDocumentProxy(proxy)

        // Then: Should accept proxy (verified by subsequent operations)
        newManager.updateComposingText("test")
        XCTAssertTrue(proxy.setMarkedTextCalled)
    }

    // MARK: - Composing Text Update Tests

    func testUpdateComposingText() {
        // Given: Manager with proxy
        // When: Updating composing text
        manager.updateComposingText("かいしゃ")

        // Then: Should call setMarkedText
        XCTAssertTrue(mockProxy.setMarkedTextCalled)
        XCTAssertEqual(mockProxy.markedText, "かいしゃ")
        XCTAssertEqual(mockProxy.selectedRange?.location, 4)
        XCTAssertEqual(mockProxy.selectedRange?.length, 0)
        XCTAssertEqual(manager.composingText, "かいしゃ")
    }

    func testUpdateComposingTextWithLiveConversion() {
        // Given: Manager with proxy
        // When: Updating with live conversion text
        manager.updateComposingText("かいしゃ", liveConversionText: "会社")

        // Then: Should display live conversion text
        XCTAssertTrue(mockProxy.setMarkedTextCalled)
        XCTAssertEqual(mockProxy.markedText, "会社")
        XCTAssertEqual(manager.composingText, "かいしゃ")
        XCTAssertEqual(manager.displayedLiveConversionText, "会社")
    }

    func testUpdateComposingTextEmpty() {
        // Given: Manager with existing composing text
        manager.updateComposingText("test")
        mockProxy.reset()

        // When: Updating with empty text
        manager.updateComposingText("")

        // Then: Should call unmarkText
        XCTAssertTrue(mockProxy.unmarkTextCalled)
        XCTAssertEqual(manager.composingText, "")
    }

    func testUpdateComposingTextEmptyWithNilLiveConversion() {
        // Given: Manager with proxy
        // When: Updating with empty composing and nil live conversion
        manager.updateComposingText("", liveConversionText: nil)

        // Then: Should call unmarkText
        XCTAssertTrue(mockProxy.unmarkTextCalled)
    }

    func testUpdateComposingTextCursorPosition() {
        // Given: Manager with proxy
        // When: Updating composing text
        manager.updateComposingText("あいうえお")

        // Then: Cursor should be at end
        XCTAssertEqual(mockProxy.selectedRange?.location, 5)
    }

    func testUpdateComposingTextSequence() {
        // Given: Manager with proxy
        // When: Updating multiple times
        manager.updateComposingText("か")
        XCTAssertEqual(mockProxy.markedText, "か")

        manager.updateComposingText("かい")
        XCTAssertEqual(mockProxy.markedText, "かい")

        manager.updateComposingText("かいしゃ")
        XCTAssertEqual(mockProxy.markedText, "かいしゃ")

        // Then: Should maintain state
        XCTAssertEqual(manager.composingText, "かいしゃ")
    }

    // MARK: - Stop Composition Tests

    func testStopComposition() {
        // Given: Manager with composing text
        manager.updateComposingText("test")
        mockProxy.reset()

        // When: Stopping composition
        manager.stopComposition()

        // Then: Should unmark and clear state
        XCTAssertTrue(mockProxy.unmarkTextCalled)
        XCTAssertEqual(manager.composingText, "")
        XCTAssertNil(manager.displayedLiveConversionText)
    }

    func testStopCompositionWithLiveConversion() {
        // Given: Manager with live conversion
        manager.updateComposingText("かいしゃ", liveConversionText: "会社")
        mockProxy.reset()

        // When: Stopping composition
        manager.stopComposition()

        // Then: Should clear both composing and live conversion
        XCTAssertTrue(mockProxy.unmarkTextCalled)
        XCTAssertEqual(manager.composingText, "")
        XCTAssertNil(manager.displayedLiveConversionText)
    }

    // MARK: - Text Insertion Tests

    func testInsertText() {
        // Given: Manager with composing text
        manager.updateComposingText("かいしゃ")
        mockProxy.reset()

        // When: Inserting text
        manager.insertText("会社")

        // Then: Should unmark and insert
        XCTAssertTrue(mockProxy.unmarkTextCalled)
        XCTAssertTrue(mockProxy.insertTextCalled)
        XCTAssertEqual(mockProxy.insertedText, "会社")
        XCTAssertEqual(manager.composingText, "")
        XCTAssertNil(manager.displayedLiveConversionText)
    }

    func testInsertTextClearsState() {
        // Given: Manager with composing and live conversion
        manager.updateComposingText("かいしゃ", liveConversionText: "会社")

        // When: Inserting text
        manager.insertText("会社")

        // Then: Should clear all state
        XCTAssertEqual(manager.composingText, "")
        XCTAssertNil(manager.displayedLiveConversionText)
    }

    func testInsertTextEmpty() {
        // Given: Manager with proxy
        // When: Inserting empty text
        manager.insertText("")

        // Then: Should still unmark and insert
        XCTAssertTrue(mockProxy.unmarkTextCalled)
        XCTAssertTrue(mockProxy.insertTextCalled)
        XCTAssertEqual(mockProxy.insertedText, "")
    }

    // MARK: - Deletion Tests

    func testDeleteBackward() {
        // Given: Manager with proxy
        // When: Deleting backward
        manager.deleteBackward()

        // Then: Should call deleteBackward on proxy
        XCTAssertTrue(mockProxy.deleteBackwardCalled)
        XCTAssertEqual(mockProxy.deleteCount, 1)
    }

    func testDeleteBackwardMultiple() {
        // Given: Manager with proxy
        // When: Deleting multiple characters
        manager.deleteBackward(count: 3)

        // Then: Should call deleteBackward 3 times
        XCTAssertTrue(mockProxy.deleteBackwardCalled)
        XCTAssertEqual(mockProxy.deleteCount, 3)
    }

    func testDeleteBackwardZero() {
        // Given: Manager with proxy
        // When: Deleting 0 characters
        manager.deleteBackward(count: 0)

        // Then: Should not call deleteBackward
        XCTAssertFalse(mockProxy.deleteBackwardCalled)
    }

    // MARK: - Cursor Position Tests

    func testUpdateCursorPosition() {
        // Given: Manager with composing text
        manager.updateComposingText("あいうえお")
        mockProxy.reset()

        // When: Updating cursor position
        manager.updateCursorPosition(3)

        // Then: Should update marked text with new cursor
        XCTAssertTrue(mockProxy.setMarkedTextCalled)
        XCTAssertEqual(mockProxy.selectedRange?.location, 3)
    }

    func testUpdateCursorPositionClamping() {
        // Given: Manager with composing text
        manager.updateComposingText("abc")
        mockProxy.reset()

        // When: Setting cursor beyond bounds
        manager.updateCursorPosition(10)

        // Then: Should clamp to valid range
        XCTAssertEqual(mockProxy.selectedRange?.location, 3)

        // When: Setting negative cursor
        manager.updateCursorPosition(-1)

        // Then: Should clamp to 0
        XCTAssertEqual(mockProxy.selectedRange?.location, 0)
    }

    func testUpdateCursorPositionWithLiveConversion() {
        // Given: Manager with live conversion
        manager.updateComposingText("かいしゃ", liveConversionText: "会社")
        mockProxy.reset()

        // When: Updating cursor
        manager.updateCursorPosition(1)

        // Then: Should update with live conversion text
        XCTAssertEqual(mockProxy.markedText, "会社")
        XCTAssertEqual(mockProxy.selectedRange?.location, 1)
    }

    // MARK: - Context Information Tests

    func testDocumentContextBeforeInput() {
        // Given: Mock proxy with context
        mockProxy.mockDocumentContextBeforeInput = "Hello "

        // When: Getting context before input
        let context = manager.documentContextBeforeInput

        // Then: Should return proxy's context
        XCTAssertEqual(context, "Hello ")
    }

    func testDocumentContextAfterInput() {
        // Given: Mock proxy with context
        mockProxy.mockDocumentContextAfterInput = " World"

        // When: Getting context after input
        let context = manager.documentContextAfterInput

        // Then: Should return proxy's context
        XCTAssertEqual(context, " World")
    }

    // MARK: - Edge Cases Tests

    func testUpdateWithoutProxy() {
        // Given: Manager without proxy
        let newManager = DisplayedTextManager()

        // When: Updating composing text
        newManager.updateComposingText("test")

        // Then: Should not crash (warning logged)
        XCTAssertEqual(newManager.composingText, "test")
    }

    func testStopCompositionWithoutProxy() {
        // Given: Manager without proxy
        let newManager = DisplayedTextManager()

        // When: Stopping composition
        newManager.stopComposition()

        // Then: Should not crash
        XCTAssertEqual(newManager.composingText, "")
    }

    func testInsertTextWithoutProxy() {
        // Given: Manager without proxy
        let newManager = DisplayedTextManager()

        // When: Inserting text
        newManager.insertText("test")

        // Then: Should not crash
        XCTAssertEqual(newManager.composingText, "")
    }
}

// MARK: - Mock UITextDocumentProxy

class MockUITextDocumentProxy: NSObject, UITextDocumentProxy {
    // MARK: - Tracking Properties

    var setMarkedTextCalled = false
    var unmarkTextCalled = false
    var insertTextCalled = false
    var deleteBackwardCalled = false

    var markedText: String?
    var selectedRange: NSRange?
    var insertedText: String?
    var deleteCount = 0

    var mockDocumentContextBeforeInput: String?
    var mockDocumentContextAfterInput: String?

    // MARK: - UIKeyInput Protocol

    var hasText: Bool {
        return !(mockDocumentContextBeforeInput ?? "").isEmpty
    }

    // MARK: - Reset

    func reset() {
        setMarkedTextCalled = false
        unmarkTextCalled = false
        insertTextCalled = false
        deleteBackwardCalled = false
        markedText = nil
        selectedRange = nil
        insertedText = nil
        deleteCount = 0
    }

    // MARK: - UITextDocumentProxy Implementation

    var documentContextBeforeInput: String? {
        return mockDocumentContextBeforeInput
    }

    var documentContextAfterInput: String? {
        return mockDocumentContextAfterInput
    }

    var selectedText: String? {
        return nil
    }

    var documentInputMode: UITextInputMode? {
        return nil
    }

    var documentIdentifier: UUID {
        return UUID()
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {}

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {
        self.setMarkedTextCalled = true
        self.markedText = markedText
        self.selectedRange = selectedRange
    }

    func unmarkText() {
        self.unmarkTextCalled = true
    }

    func insertText(_ text: String) {
        self.insertTextCalled = true
        self.insertedText = text
    }

    func deleteBackward() {
        self.deleteBackwardCalled = true
        self.deleteCount += 1
    }
}
