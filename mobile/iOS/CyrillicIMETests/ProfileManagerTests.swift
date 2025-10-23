//
//  ProfileManagerTests.swift
//  CyrillicIMETests
//
//  Unit tests for ProfileManager
//

import XCTest
@testable import CyrillicIME

class ProfileManagerTests: XCTestCase {
    var profileManager: ProfileManager!

    override func setUp() {
        super.setUp()
        profileManager = ProfileManager.shared
    }

    override func tearDown() {
        profileManager = nil
        super.tearDown()
    }

    // MARK: - Profile Loading Tests

    func testInitialization() {
        // Given: ProfileManager is initialized
        // When: Calling initialize()
        let error = profileManager.initialize()

        // Then: Should succeed or return specific error
        if let error = error {
            XCTAssertNotNil(error, "Initialization failed with: \(error)")
        } else {
            XCTAssertTrue(profileManager.availableProfiles.count > 0, "Should load at least one profile")
        }
    }

    func testGetAvailableProfiles() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        // When: Getting available profiles
        let profiles = profileManager.availableProfiles

        // Then: Should return non-empty array
        XCTAssertFalse(profiles.isEmpty, "Available profiles should not be empty")

        // And: Each profile should have required fields
        for profile in profiles {
            XCTAssertFalse(profile.id.isEmpty, "Profile ID should not be empty")
            XCTAssertFalse(profile.nameJa.isEmpty, "Profile Japanese name should not be empty")
            XCTAssertFalse(profile.nameEn.isEmpty, "Profile English name should not be empty")
            XCTAssertFalse(profile.keyboardLayout.isEmpty, "Keyboard layout should not be empty")
            XCTAssertFalse(profile.inputSchemaId.isEmpty, "Input schema ID should not be empty")
        }
    }

    func testCurrentProfile() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        // When: Getting current profile
        let currentProfile = profileManager.currentProfile

        // Then: Should return a valid profile
        XCTAssertNotNil(currentProfile, "Current profile should not be nil")

        if let profile = currentProfile {
            XCTAssertFalse(profile.id.isEmpty, "Current profile ID should not be empty")
        }
    }

    // MARK: - Schema Loading Tests

    func testLoadSchemaForProfile() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        guard let profile = profileManager.availableProfiles.first else {
            XCTFail("No profiles available")
            return
        }

        // When: Loading schema for profile
        let error = profileManager.loadSchemaForProfile(profile)

        // Then: Should succeed
        XCTAssertNil(error, "Loading schema should succeed")
    }

    func testLoadCurrentSchema() {
        // Given: ProfileManager is initialized with a current profile
        _ = profileManager.initialize()

        // When: Loading current schema
        let error = profileManager.loadCurrentSchema()

        // Then: Should succeed
        XCTAssertNil(error, "Loading current schema should succeed")
    }

    func testLoadSchemaIdempotent() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        guard let profile = profileManager.availableProfiles.first else {
            XCTFail("No profiles available")
            return
        }

        // When: Loading same schema twice
        let error1 = profileManager.loadSchemaForProfile(profile)
        let error2 = profileManager.loadSchemaForProfile(profile)

        // Then: Both should succeed (second load should be skipped)
        XCTAssertNil(error1, "First schema load should succeed")
        XCTAssertNil(error2, "Second schema load should succeed (idempotent)")
    }

    // MARK: - Profile Switching Tests

    func testSwitchProfileValid() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        guard let targetProfile = profileManager.availableProfiles.first else {
            XCTFail("No profiles available")
            return
        }

        // When: Switching to valid profile
        let error = profileManager.switchProfile(to: targetProfile.id)

        // Then: Should succeed
        XCTAssertNil(error, "Switching profile should succeed")

        // And: Current profile should be updated
        XCTAssertEqual(profileManager.currentProfile?.id, targetProfile.id)
    }

    func testSwitchProfileInvalid() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        // When: Switching to invalid profile
        let error = profileManager.switchProfile(to: "nonexistent_profile")

        // Then: Should return error
        XCTAssertNotNil(error, "Switching to invalid profile should return error")
    }

    // MARK: - Validation Tests

    func testIsValidProfile() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        guard let validProfile = profileManager.availableProfiles.first else {
            XCTFail("No profiles available")
            return
        }

        // When/Then: Valid profile should return true
        XCTAssertTrue(profileManager.isValidProfile(validProfile.id))

        // When/Then: Invalid profile should return false
        XCTAssertFalse(profileManager.isValidProfile("invalid_profile_id"))
    }

    func testProfileDisplayName() {
        // Given: A test profile
        let profile = Profile(
            id: "test",
            nameJa: "テストプロファイル",
            nameEn: "Test Profile",
            keyboardLayout: ["А", "Б"],
            inputSchemaId: "schema_test"
        )

        // When: Getting display name
        let displayName = profile.displayName

        // Then: Should return appropriate name based on locale
        XCTAssertFalse(displayName.isEmpty, "Display name should not be empty")
        XCTAssertTrue(
            displayName == profile.nameJa || displayName == profile.nameEn,
            "Display name should be either Japanese or English name"
        )
    }

    // MARK: - Error Handling Tests

    func testLoadSchemaForNonexistentFile() {
        // Given: ProfileManager is initialized
        _ = profileManager.initialize()

        // And: A profile with invalid schema ID
        let invalidProfile = Profile(
            id: "invalid",
            nameJa: "無効",
            nameEn: "Invalid",
            keyboardLayout: ["А"],
            inputSchemaId: "nonexistent_schema"
        )

        // When: Loading schema for invalid profile
        let error = profileManager.loadSchemaForProfile(invalidProfile)

        // Then: Should return error
        XCTAssertNotNil(error, "Loading nonexistent schema should return error")
    }
}
