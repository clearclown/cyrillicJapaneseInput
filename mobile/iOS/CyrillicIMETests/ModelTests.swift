//
//  ModelTests.swift
//  CyrillicIMETests
//
//  Unit tests for data models
//

import XCTest
@testable import CyrillicIME

class ModelTests: XCTestCase {
    // MARK: - Profile Tests

    func testProfileCodable() {
        // Given: A Profile instance
        let profile = Profile(
            id: "rus_standard",
            nameJa: "ロシア語",
            nameEn: "Russian",
            keyboardLayout: ["А", "Б", "В"],
            inputSchemaId: "schema_rus_v1"
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try? encoder.encode(profile)

        // Then: Should encode successfully
        XCTAssertNotNil(data, "Profile should encode to JSON")

        // When: Decoding back
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedProfile = try? decoder.decode(Profile.self, from: data!)

        // Then: Should decode successfully with same values
        XCTAssertNotNil(decodedProfile)
        XCTAssertEqual(decodedProfile?.id, profile.id)
        XCTAssertEqual(decodedProfile?.nameJa, profile.nameJa)
        XCTAssertEqual(decodedProfile?.nameEn, profile.nameEn)
        XCTAssertEqual(decodedProfile?.keyboardLayout, profile.keyboardLayout)
        XCTAssertEqual(decodedProfile?.inputSchemaId, profile.inputSchemaId)
    }

    func testProfileDisplayNameJapanese() {
        // Given: A Profile with both Japanese and English names
        let profile = Profile(
            id: "test",
            nameJa: "テスト",
            nameEn: "Test",
            keyboardLayout: [],
            inputSchemaId: "schema_test"
        )

        // When: Getting display name
        let displayName = profile.displayName

        // Then: Should return appropriate name based on locale
        XCTAssertFalse(displayName.isEmpty)
        // Note: Actual result depends on test environment locale
    }

    func testProfileIdentifiable() {
        // Given: Two profiles with different IDs
        let profile1 = Profile(
            id: "rus",
            nameJa: "ロシア語",
            nameEn: "Russian",
            keyboardLayout: [],
            inputSchemaId: "schema_rus"
        )

        let profile2 = Profile(
            id: "srb",
            nameJa: "セルビア語",
            nameEn: "Serbian",
            keyboardLayout: [],
            inputSchemaId: "schema_srb"
        )

        // Then: Should have unique IDs
        XCTAssertNotEqual(profile1.id, profile2.id)
    }

    func testProfileHashable() {
        // Given: Two identical profiles
        let profile1 = Profile(
            id: "test",
            nameJa: "テスト",
            nameEn: "Test",
            keyboardLayout: ["А"],
            inputSchemaId: "schema_test"
        )

        let profile2 = Profile(
            id: "test",
            nameJa: "テスト",
            nameEn: "Test",
            keyboardLayout: ["А"],
            inputSchemaId: "schema_test"
        )

        // When: Using in a Set
        let profileSet: Set<Profile> = [profile1, profile2]

        // Then: Should be treated as equal (Set should contain only one)
        XCTAssertEqual(profileSet.count, 1, "Identical profiles should be equal")
    }

    func testProfileEquality() {
        // Given: Two profiles with same ID
        let profile1 = Profile(
            id: "rus",
            nameJa: "ロシア語",
            nameEn: "Russian",
            keyboardLayout: ["А", "Б"],
            inputSchemaId: "schema_rus"
        )

        let profile2 = Profile(
            id: "rus",
            nameJa: "ロシア語",
            nameEn: "Russian",
            keyboardLayout: ["А", "Б"],
            inputSchemaId: "schema_rus"
        )

        // Then: Should be equal
        XCTAssertEqual(profile1, profile2)
    }

    // MARK: - ConversionResult Tests

    func testConversionResultCodable() {
        // Given: A ConversionResult instance
        let result = ConversionResult(
            action: "commit",
            output: "あ",
            buffer: ""
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        let data = try? encoder.encode(result)

        // Then: Should encode successfully
        XCTAssertNotNil(data, "ConversionResult should encode to JSON")

        // When: Decoding back
        let decoder = JSONDecoder()
        let decodedResult = try? decoder.decode(ConversionResult.self, from: data!)

        // Then: Should decode successfully with same values
        XCTAssertNotNil(decodedResult)
        XCTAssertEqual(decodedResult?.action, result.action)
        XCTAssertEqual(decodedResult?.output, result.output)
        XCTAssertEqual(decodedResult?.buffer, result.buffer)
    }

    func testConversionResultIsCommit() {
        // Given: A commit result
        let commitResult = ConversionResult(action: "commit", output: "あ", buffer: "")

        // Then: isCommit should be true
        XCTAssertTrue(commitResult.isCommit)
        XCTAssertFalse(commitResult.isComposing)
        XCTAssertFalse(commitResult.isClear)
    }

    func testConversionResultIsComposing() {
        // Given: A composing result
        let composingResult = ConversionResult(action: "composing", output: "", buffer: "К")

        // Then: isComposing should be true
        XCTAssertFalse(composingResult.isCommit)
        XCTAssertTrue(composingResult.isComposing)
        XCTAssertFalse(composingResult.isClear)
    }

    func testConversionResultIsClear() {
        // Given: A clear result
        let clearResult = ConversionResult(action: "clear", output: "", buffer: "")

        // Then: isClear should be true
        XCTAssertFalse(clearResult.isCommit)
        XCTAssertFalse(clearResult.isComposing)
        XCTAssertTrue(clearResult.isClear)
    }

    func testConversionResultUnknownAction() {
        // Given: A result with unknown action
        let unknownResult = ConversionResult(action: "unknown", output: "", buffer: "")

        // Then: All convenience properties should be false
        XCTAssertFalse(unknownResult.isCommit)
        XCTAssertFalse(unknownResult.isComposing)
        XCTAssertFalse(unknownResult.isClear)
    }

    // MARK: - UserDefaults Extension Tests

    func testUserDefaultsAppGroup() {
        // Given: UserDefaults.shared
        let defaults = UserDefaults.shared

        // Then: Should not crash and should be accessible
        XCTAssertNotNil(defaults, "Shared UserDefaults should be accessible")
    }

    func testUserDefaultsCurrentProfileId() {
        // Given: UserDefaults.shared
        let defaults = UserDefaults.shared

        // When: Setting profile ID
        let testProfileId = "test_profile"
        defaults.currentProfileId = testProfileId

        // Then: Should retrieve same value
        XCTAssertEqual(defaults.currentProfileId, testProfileId)

        // Cleanup
        defaults.currentProfileId = "rus_standard"
    }

    func testUserDefaultsCurrentProfileIdDefault() {
        // Given: Fresh UserDefaults state
        let defaults = UserDefaults.shared

        // When: Removing current profile ID
        defaults.removeObject(forKey: UserDefaults.Keys.currentProfileId)

        // Then: Should return default value
        XCTAssertEqual(defaults.currentProfileId, "rus_standard")

        // Cleanup
        defaults.currentProfileId = "rus_standard"
    }

    func testUserDefaultsHasCompletedOnboarding() {
        // Given: UserDefaults.shared
        let defaults = UserDefaults.shared

        // When: Setting onboarding flag
        defaults.hasCompletedOnboarding = true

        // Then: Should retrieve same value
        XCTAssertTrue(defaults.hasCompletedOnboarding)

        // When: Setting to false
        defaults.hasCompletedOnboarding = false

        // Then: Should retrieve false
        XCTAssertFalse(defaults.hasCompletedOnboarding)
    }

    func testNotificationNameProfileDidChange() {
        // Given: Notification name
        let notificationName = Notification.Name.profileDidChange

        // Then: Should have correct raw value
        XCTAssertEqual(notificationName.rawValue, "profileDidChange")
    }

    // MARK: - JSON Parsing Tests

    func testProfileArrayDecoding() {
        // Given: JSON array of profiles
        let json = """
        [
            {
                "id": "rus",
                "name_ja": "ロシア語",
                "name_en": "Russian",
                "keyboardLayout": ["А", "Б"],
                "inputSchemaId": "schema_rus"
            },
            {
                "id": "srb",
                "name_ja": "セルビア語",
                "name_en": "Serbian",
                "keyboardLayout": ["А", "Б", "В"],
                "inputSchemaId": "schema_srb"
            }
        ]
        """

        // When: Decoding to Profile array
        let data = json.data(using: .utf8)!
        let profiles = try? JSONDecoder().decode([Profile].self, from: data)

        // Then: Should decode successfully
        XCTAssertNotNil(profiles)
        XCTAssertEqual(profiles?.count, 2)
        XCTAssertEqual(profiles?[0].id, "rus")
        XCTAssertEqual(profiles?[1].id, "srb")
    }

    func testConversionResultJSONDecoding() {
        // Given: JSON string for ConversionResult
        let json = """
        {
            "action": "commit",
            "output": "きゃ",
            "buffer": ""
        }
        """

        // When: Decoding to ConversionResult
        let data = json.data(using: .utf8)!
        let result = try? JSONDecoder().decode(ConversionResult.self, from: data)

        // Then: Should decode successfully with correct values
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, "commit")
        XCTAssertEqual(result?.output, "きゃ")
        XCTAssertEqual(result?.buffer, "")
    }
}
