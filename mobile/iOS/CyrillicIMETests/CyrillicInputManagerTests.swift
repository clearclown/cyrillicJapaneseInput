//
//  CyrillicInputManagerTests.swift
//  CyrillicIMETests
//
//  Unit tests for CyrillicInputManager (Phase 1)
//

import XCTest
@testable import CyrillicIME

class CyrillicInputManagerTests: XCTestCase {
    var manager: CyrillicInputManager!
    var mockDisplayedTextManager: MockDisplayedTextManager!
    var mockRustCore: MockRustCoreFFI!
    var mockProfileManager: MockProfileManager!

    override func setUp() {
        super.setUp()
        mockDisplayedTextManager = MockDisplayedTextManager()
        mockRustCore = MockRustCoreFFI()
        mockProfileManager = MockProfileManager()

        manager = CyrillicInputManager(
            displayedTextManager: mockDisplayedTextManager,
            rustCore: mockRustCore,
            profileManager: mockProfileManager
        )
    }

    override func tearDown() {
        manager = nil
        mockDisplayedTextManager = nil
        mockRustCore = nil
        mockProfileManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given/When: Manager is initialized
        let newManager = CyrillicInputManager(
            displayedTextManager: mockDisplayedTextManager
        )

        // Then: Should have default state
        XCTAssertEqual(newManager.currentComposingText, "")
        XCTAssertFalse(newManager.hasComposingText)
    }

    // MARK: - Mode Management Tests

    func testSetInputMode() {
        // When: Setting different input modes
        manager.setInputMode(.japaneseIME)
        manager.processKey("К") // Trigger mode usage
        XCTAssertNotNil(mockRustCore.lastProcessKeyCall)

        manager.setInputMode(.japaneseHiragana)
        manager.setInputMode(.directCyrillic)

        // Then: Should not crash and accept all modes
        XCTAssertTrue(true)
    }

    // MARK: - Key Processing Tests

    func testProcessKeySingleCharacter() {
        // Given: Profile is available
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "テスト",
            nameEn: "Test",
            keyboardLayout: ["А"],
            inputSchemaId: "schema_test"
        )
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "あ", buffer: "")
        manager.setInputMode(.japaneseIME)

        // When: Processing key
        manager.processKey("А")

        // Then: Should call Rust Core
        XCTAssertNotNil(mockRustCore.lastProcessKeyCall)
        XCTAssertEqual(mockRustCore.lastProcessKeyCall?.cyrillicKey, "А")
        XCTAssertEqual(mockRustCore.lastProcessKeyCall?.currentBuffer, "")
        XCTAssertEqual(mockRustCore.lastProcessKeyCall?.profileId, "test")
    }

    func testProcessKeyAccumulatesHiragana() {
        // Given: Profile and IME mode
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)

        // When: Processing multiple keys
        mockRustCore.nextResult = ConversionResult(action: "composing", output: "", buffer: "К")
        manager.processKey("К")

        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        mockRustCore.nextResult = ConversionResult(action: "commit", output: "い", buffer: "")
        manager.processKey("Й")

        // Then: Should accumulate hiragana
        XCTAssertEqual(manager.currentComposingText, "かい")
        XCTAssertTrue(manager.hasComposingText)
    }

    func testProcessKeyWithNoProfile() {
        // Given: No current profile
        mockProfileManager.currentProfile = nil

        // When: Processing key
        manager.processKey("А")

        // Then: Should not call Rust Core
        XCTAssertNil(mockRustCore.lastProcessKeyCall)
    }

    func testProcessKeyWithFailedConversion() {
        // Given: Profile exists but Rust Core returns nil
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        mockRustCore.nextResult = nil

        // When: Processing key
        manager.processKey("А")

        // Then: Should not update composing text
        XCTAssertEqual(manager.currentComposingText, "")
    }

    // MARK: - Mode-Specific Handling Tests

    func testHandleIMEMode() {
        // Given: IME mode with profile
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        var callbackCalled = false
        manager.onComposingTextChanged = { text in
            callbackCalled = true
            XCTAssertEqual(text, "か")
        }

        // When: Processing key in IME mode
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // Then: Should update composing text and call callback
        XCTAssertEqual(mockDisplayedTextManager.lastComposingText, "か")
        XCTAssertTrue(callbackCalled)
    }

    func testHandleHiraganaMode() {
        // Given: Hiragana mode with profile
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseHiragana)

        // When: Processing key that commits
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // Then: Should insert text immediately
        XCTAssertEqual(mockDisplayedTextManager.lastInsertedText, "か")
    }

    // MARK: - Delete Handling Tests

    func testProcessDeleteWithComposingText() {
        // Given: Composing text exists
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)

        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("К")
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "い", buffer: "")
        manager.processKey("А")

        // When: Deleting
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processDelete()

        // Then: Should rebuild from history
        XCTAssertTrue(manager.hasComposingText)
        XCTAssertEqual(manager.currentComposingText, "か")
    }

    func testProcessDeleteWithoutComposingText() {
        // Given: No composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )

        // When: Deleting
        manager.processDelete()

        // Then: Should delete from document
        XCTAssertTrue(mockDisplayedTextManager.deleteBackwardCalled)
    }

    func testProcessDeleteExitConversionMode() {
        // Given: In conversion mode with candidates
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // Start conversion
        manager.processSpace()
        XCTAssertNotNil(mockDisplayedTextManager.lastLiveConversionText)

        // When: Deleting in conversion mode
        manager.processDelete()

        // Then: Should exit conversion mode
        XCTAssertNil(mockDisplayedTextManager.lastLiveConversionText)
    }

    // MARK: - Space Key Handling Tests

    func testProcessSpaceStartConversion() {
        // Given: IME mode with composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "かいしゃ", buffer: "")
        manager.processKey("К")

        var candidatesUpdated = false
        manager.onCandidatesUpdated = { candidates in
            candidatesUpdated = true
            XCTAssertTrue(candidates.contains("かいしゃ"))
        }

        // When: Pressing space
        manager.processSpace()

        // Then: Should start conversion and show candidates
        XCTAssertTrue(candidatesUpdated)
    }

    func testProcessSpaceCycleCandidates() {
        // Given: Already in conversion mode
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")
        manager.processSpace() // Start conversion

        // When: Pressing space again
        manager.processSpace()

        // Then: Should cycle to next candidate
        // In Phase 1, this cycles through hiragana and katakana
        XCTAssertNotNil(mockDisplayedTextManager.lastLiveConversionText)
    }

    func testProcessSpaceWithoutComposingText() {
        // Given: No composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)

        // When: Pressing space
        manager.processSpace()

        // Then: Should insert space
        XCTAssertEqual(mockDisplayedTextManager.lastInsertedText, " ")
    }

    // MARK: - Return Key Handling Tests

    func testProcessReturnWithComposingText() {
        // Given: Composing text exists
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // When: Pressing return
        manager.processReturn()

        // Then: Should commit composing text
        XCTAssertEqual(mockDisplayedTextManager.lastInsertedText, "か")
        XCTAssertFalse(manager.hasComposingText)
    }

    func testProcessReturnInConversionMode() {
        // Given: In conversion mode
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")
        manager.processSpace() // Start conversion

        // When: Pressing return
        manager.processReturn()

        // Then: Should commit selected candidate
        XCTAssertNotNil(mockDisplayedTextManager.lastInsertedText)
        XCTAssertFalse(manager.hasComposingText)
    }

    func testProcessReturnWithoutComposingText() {
        // Given: No composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )

        // When: Pressing return
        manager.processReturn()

        // Then: Should do nothing (caller inserts newline)
        XCTAssertNil(mockDisplayedTextManager.lastInsertedText)
    }

    // MARK: - Candidate Selection Tests

    func testSelectCandidateValid() {
        // Given: Conversion mode with candidates
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")
        manager.processSpace() // Start conversion

        // When: Selecting first candidate
        manager.selectCandidate(at: 0)

        // Then: Should commit candidate
        XCTAssertNotNil(mockDisplayedTextManager.lastInsertedText)
        XCTAssertFalse(manager.hasComposingText)
    }

    func testSelectCandidateInvalid() {
        // Given: Conversion mode with candidates
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")
        manager.processSpace()

        // When: Selecting invalid index
        manager.selectCandidate(at: 999)

        // Then: Should not crash
        XCTAssertTrue(manager.hasComposingText)
    }

    // MARK: - Commit Tests

    func testCommitIfNeededWithComposingText() {
        // Given: Composing text exists
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // When: Committing if needed
        manager.commitIfNeeded()

        // Then: Should commit
        XCTAssertEqual(mockDisplayedTextManager.lastInsertedText, "か")
        XCTAssertFalse(manager.hasComposingText)
    }

    func testCommitIfNeededWithoutComposingText() {
        // Given: No composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )

        // When: Committing if needed
        manager.commitIfNeeded()

        // Then: Should do nothing
        XCTAssertNil(mockDisplayedTextManager.lastInsertedText)
    }

    // MARK: - Callback Tests

    func testOnCandidatesUpdatedCallback() {
        // Given: Callback is set
        var receivedCandidates: [String]?
        manager.onCandidatesUpdated = { candidates in
            receivedCandidates = candidates
        }

        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // When: Starting conversion
        manager.processSpace()

        // Then: Callback should be called
        XCTAssertNotNil(receivedCandidates)
        XCTAssertTrue(receivedCandidates!.count > 0)
    }

    func testOnComposingTextChangedCallback() {
        // Given: Callback is set
        var receivedText: String?
        manager.onComposingTextChanged = { text in
            receivedText = text
        }

        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")

        // When: Processing key
        manager.processKey("А")

        // Then: Callback should be called
        XCTAssertEqual(receivedText, "か")
    }

    // MARK: - State Access Tests

    func testCurrentComposingText() {
        // Given: Manager with composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "かいしゃ", buffer: "")
        manager.processKey("К")

        // When: Getting current composing text
        let text = manager.currentComposingText

        // Then: Should return hiragana
        XCTAssertEqual(text, "かいしゃ")
    }

    func testHasComposingText() {
        // Given: Manager with no composing text
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )

        // When: Checking has composing text
        XCTAssertFalse(manager.hasComposingText)

        // Given: Add composing text
        manager.setInputMode(.japaneseIME)
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("А")

        // Then: Should have composing text
        XCTAssertTrue(manager.hasComposingText)
    }

    // MARK: - Integration Tests

    func testCompleteInputFlow() {
        // Given: Complete setup
        mockProfileManager.currentProfile = Profile(
            id: "test",
            nameJa: "Test",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )
        manager.setInputMode(.japaneseIME)

        // When: Typing "かいしゃ" and converting to "会社"
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "か", buffer: "")
        manager.processKey("К")
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "い", buffer: "")
        manager.processKey("А")
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "し", buffer: "")
        manager.processKey("Ш")
        mockRustCore.nextResult = ConversionResult(action: "commit", output: "ゃ", buffer: "")
        manager.processKey("Я")

        XCTAssertEqual(manager.currentComposingText, "かいしゃ")

        // Start conversion
        manager.processSpace()
        XCTAssertNotNil(mockDisplayedTextManager.lastLiveConversionText)

        // Commit
        manager.processReturn()

        // Then: Should be committed
        XCTAssertFalse(manager.hasComposingText)
        XCTAssertNotNil(mockDisplayedTextManager.lastInsertedText)
    }
}

// MARK: - Mock DisplayedTextManager

class MockDisplayedTextManager: DisplayedTextManager {
    var lastComposingText: String?
    var lastLiveConversionText: String?
    var lastInsertedText: String?
    var deleteBackwardCalled = false

    override func updateComposingText(_ composingText: String, liveConversionText: String? = nil) {
        lastComposingText = composingText
        lastLiveConversionText = liveConversionText
    }

    override func insertText(_ text: String) {
        lastInsertedText = text
    }

    override func deleteBackward(count: Int = 1) {
        deleteBackwardCalled = true
    }
}

// MARK: - Mock RustCoreFFI

class MockRustCoreFFI: RustCoreFFI {
    var nextResult: ConversionResult?
    var lastProcessKeyCall: (cyrillicKey: String, currentBuffer: String, profileId: String)?

    override func processKey(cyrillicKey: String, currentBuffer: String, profileId: String) -> ConversionResult? {
        lastProcessKeyCall = (cyrillicKey, currentBuffer, profileId)
        return nextResult
    }
}

// MARK: - Mock ProfileManager

class MockProfileManager: ProfileManager {
    override var currentProfile: Profile? {
        get { return _currentProfile }
        set { _currentProfile = newValue }
    }

    private var _currentProfile: Profile?
}
