//
//  RustCoreFFITests.swift
//  CyrillicIMETests
//
//  Unit tests for Rust Core FFI integration
//

import XCTest
@testable import CyrillicIME

class RustCoreFFITests: XCTestCase {
    let testProfilesJSON = """
    [
        {
            "id": "rus_test",
            "name_ja": "ロシア語テスト",
            "name_en": "Russian Test",
            "keyboardLayout": ["А", "И", "У", "К", "Я", "Н"],
            "inputSchemaId": "schema_rus_test"
        }
    ]
    """

    let testKanaEngineJSON = """
    {
        "a": "あ",
        "i": "い",
        "u": "う",
        "ka": "か",
        "ki": "き",
        "kya": "きゃ",
        "n_final": "ん"
    }
    """

    let testSchemaJSON = """
    {
        "А": {"kana_key": "a"},
        "И": {"kana_key": "i"},
        "У": {"kana_key": "u"},
        "КА": {"kana_key": "ka"},
        "КИ": {"kana_key": "ki"},
        "КЯ": {"kana_key": "kya"},
        "Н": {"kana_key": "n_final"}
    }
    """

    // MARK: - Initialization Tests

    func testGetVersion() {
        // When: Getting version
        let version = RustCoreFFI.shared.getVersion()

        // Then: Should return non-empty string
        XCTAssertFalse(version.isEmpty, "Version should not be empty")
        XCTAssertNotEqual(version, "unknown", "Version should not be 'unknown'")
    }

    func testInitEngine() {
        // Given: Valid JSON strings
        // When: Initializing engine
        let error = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )

        // Then: Should succeed (or fail if already initialized)
        // Note: Engine can only be initialized once per process
        if let error = error {
            XCTAssertTrue(
                error.contains("already initialized"),
                "Error should indicate already initialized: \(error)"
            )
        }
    }

    func testInitEngineWithInvalidJSON() {
        // Given: Invalid JSON
        let invalidJSON = "{invalid json"

        // When: Initializing with invalid JSON
        let error = RustCoreFFI.shared.initEngine(
            profilesJSON: invalidJSON,
            kanaEngineJSON: testKanaEngineJSON
        )

        // Then: Should return error (unless already initialized)
        // Note: If already initialized, this test may pass
        if !RustCoreFFI.shared.initialized {
            XCTAssertNotNil(error, "Should return error for invalid JSON")
        }
    }

    // MARK: - Schema Loading Tests

    func testLoadSchema() {
        // Given: Engine is initialized
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )

        // When: Loading schema
        let error = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // Then: Should succeed
        XCTAssertNil(error, "Loading schema should succeed")
    }

    func testLoadSchemaWithInvalidJSON() {
        // Given: Engine is initialized
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )

        // When: Loading invalid schema JSON
        let invalidSchema = "{invalid json"
        let error = RustCoreFFI.shared.loadSchema(
            schemaJSON: invalidSchema,
            schemaId: "invalid_schema"
        )

        // Then: Should return error
        XCTAssertNotNil(error, "Loading invalid schema should return error")
    }

    // MARK: - Key Processing Tests

    func testProcessKeySingleCharacter() {
        // Given: Engine is initialized and schema is loaded
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )
        _ = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // When: Processing single character key
        let result = RustCoreFFI.shared.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: "rus_test"
        )

        // Then: Should return commit result with "あ"
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result?.action, "commit")
        XCTAssertEqual(result?.output, "あ")
        XCTAssertEqual(result?.buffer, "")
    }

    func testProcessKeyComposing() {
        // Given: Engine is initialized and schema is loaded
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )
        _ = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // When: Processing key that forms prefix
        let result = RustCoreFFI.shared.processKey(
            cyrillicKey: "К",
            currentBuffer: "",
            profileId: "rus_test"
        )

        // Then: Should return composing result
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result?.action, "composing")
        XCTAssertEqual(result?.buffer, "К")
    }

    func testProcessKeyMultiCharacterSequence() {
        // Given: Engine is initialized and schema is loaded
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )
        _ = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // When: Processing second key to complete sequence
        let result = RustCoreFFI.shared.processKey(
            cyrillicKey: "И",
            currentBuffer: "К",
            profileId: "rus_test"
        )

        // Then: Should commit "き"
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result?.action, "commit")
        XCTAssertEqual(result?.output, "き")
        XCTAssertEqual(result?.buffer, "")
    }

    func testProcessKeyThreeCharacterSequence() {
        // Given: Engine is initialized and schema is loaded
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )
        _ = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // When: Processing КЯ sequence for きゃ
        let result1 = RustCoreFFI.shared.processKey(
            cyrillicKey: "К",
            currentBuffer: "",
            profileId: "rus_test"
        )
        XCTAssertEqual(result1?.action, "composing")

        let result2 = RustCoreFFI.shared.processKey(
            cyrillicKey: "Я",
            currentBuffer: "К",
            profileId: "rus_test"
        )

        // Then: Should commit "きゃ"
        XCTAssertNotNil(result2, "Result should not be nil")
        XCTAssertEqual(result2?.action, "commit")
        XCTAssertEqual(result2?.output, "きゃ")
    }

    func testProcessKeyWithInvalidProfile() {
        // Given: Engine is initialized
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )

        // When: Processing with invalid profile ID
        let result = RustCoreFFI.shared.processKey(
            cyrillicKey: "А",
            currentBuffer: "",
            profileId: "nonexistent_profile"
        )

        // Then: Should return nil or error result
        // Behavior depends on Rust Core implementation
        if let result = result {
            // If result is returned, it might be an error action
            XCTAssertNotEqual(result.action, "commit", "Should not commit with invalid profile")
        }
    }

    func testProcessKeyWithEmptyKey() {
        // Given: Engine is initialized and schema is loaded
        _ = RustCoreFFI.shared.initEngine(
            profilesJSON: testProfilesJSON,
            kanaEngineJSON: testKanaEngineJSON
        )
        _ = RustCoreFFI.shared.loadSchema(
            schemaJSON: testSchemaJSON,
            schemaId: "schema_rus_test"
        )

        // When: Processing empty key
        let result = RustCoreFFI.shared.processKey(
            cyrillicKey: "",
            currentBuffer: "",
            profileId: "rus_test"
        )

        // Then: Should handle gracefully (clear or nil)
        if let result = result {
            XCTAssertTrue(
                result.action == "clear" || result.action == "composing",
                "Empty key should clear or do nothing"
            )
        }
    }

    // MARK: - ConversionResult Tests

    func testConversionResultDecoding() {
        // Given: Valid JSON string
        let jsonString = """
        {
            "action": "commit",
            "output": "あ",
            "buffer": ""
        }
        """

        // When: Decoding to ConversionResult
        let data = jsonString.data(using: .utf8)!
        let result = try? JSONDecoder().decode(ConversionResult.self, from: data)

        // Then: Should decode successfully
        XCTAssertNotNil(result, "Should decode ConversionResult")
        XCTAssertEqual(result?.action, "commit")
        XCTAssertEqual(result?.output, "あ")
        XCTAssertEqual(result?.buffer, "")
        XCTAssertTrue(result?.isCommit ?? false)
    }

    func testConversionResultConvenienceProperties() {
        // Given: Different action types
        let commitResult = ConversionResult(action: "commit", output: "あ", buffer: "")
        let composingResult = ConversionResult(action: "composing", output: "", buffer: "К")
        let clearResult = ConversionResult(action: "clear", output: "", buffer: "")

        // When/Then: Testing convenience properties
        XCTAssertTrue(commitResult.isCommit)
        XCTAssertFalse(commitResult.isComposing)
        XCTAssertFalse(commitResult.isClear)

        XCTAssertFalse(composingResult.isCommit)
        XCTAssertTrue(composingResult.isComposing)
        XCTAssertFalse(composingResult.isClear)

        XCTAssertFalse(clearResult.isCommit)
        XCTAssertFalse(clearResult.isComposing)
        XCTAssertTrue(clearResult.isClear)
    }
}
