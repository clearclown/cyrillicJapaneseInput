//
//  AutomatedConversionTests.swift
//  CyrillicIMETests
//
//  Phase 4: Automated testing for 560 conversion test cases
//  Uses TestCaseProvider to run all conversion patterns
//

import XCTest
@testable import Pismo

/// Automated tests for all 560 conversion patterns across all profiles
/// This test suite ensures comprehensive coverage of:
/// - Basic syllables (清音)
/// - Voiced consonants (濁音・半濁音)
/// - Contracted sounds (拗音)
/// - Special cases (促音・撥音・長音・音節分離)
class AutomatedConversionTests: XCTestCase {

    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!
    var testCaseProvider: TestCaseProvider!

    override func setUp() {
        super.setUp()

        // Initialize real components
        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared
        testCaseProvider = TestCaseProvider.shared

        // Initialize profile manager
        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager initialization should succeed")

        print("\n=== Automated Conversion Tests ===")
        print("Test cases available: \(testCaseProvider.getAllTestCases().count)")
        print("Profiles: \(testCaseProvider.getAvailableProfiles().joined(separator: ", "))")
    }

    override func tearDown() {
        rustCore = nil
        profileManager = nil
        testCaseProvider = nil
        super.tearDown()
    }

    // MARK: - Russian Standard Profile Tests

    /// Test ALL Russian Standard cases (112 test cases)
    func testAllRussianStandard_112Cases() {
        let profileId = "rus_standard"
        let testCases = testCaseProvider.getTestCases(for: profileId)

        print("\n========================================")
        print("Running ALL Russian Standard test cases")
        print("Total: \(testCases.count) test cases")
        print("========================================\n")

        guard !testCases.isEmpty else {
            XCTFail("No test cases found for profile '\(profileId)'")
            return
        }

        // Switch to Russian Standard profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        var passedCount = 0
        var failedCases: [(ConversionTestCase, String)] = []

        for testCase in testCases {
            do {
                try runTestCase(testCase, profileId: profileId)
                passedCount += 1
                print("✅ \(testCase.id): PASSED")
            } catch let error as NSError {
                failedCases.append((testCase, error.localizedDescription))
                print("❌ \(testCase.id): FAILED - \(error.localizedDescription)")
            }
        }

        printSummary(profileId: profileId, passed: passedCount, failed: failedCases)

        XCTAssertEqual(failedCases.count, 0, "\(failedCases.count) test cases failed for \(profileId)")
    }

    /// Test Russian Basic syllables only (43 cases)
    func testRussianBasicSyllables() {
        let profileId = "rus_standard"
        let testCases = testCaseProvider.getTestCases(for: profileId, category: "vowel") +
                        testCaseProvider.getTestCases(for: profileId, category: "consonant")

        runCategoryTests(profileId: profileId, testCases: testCases, categoryName: "Basic Syllables")
    }

    /// Test Russian Voiced consonants (25 cases)
    func testRussianVoicedConsonants() {
        let profileId = "rus_standard"
        let testCases = testCaseProvider.getTestCases(for: profileId, category: "voiced") +
                        testCaseProvider.getTestCases(for: profileId, category: "semi-voiced")

        runCategoryTests(profileId: profileId, testCases: testCases, categoryName: "Voiced Consonants")
    }

    /// Test Russian Yoon (33 cases)
    func testRussianYoon() {
        let profileId = "rus_standard"
        let testCases = testCaseProvider.getTestCases(for: profileId, category: "yoon")

        runCategoryTests(profileId: profileId, testCases: testCases, categoryName: "Yoon")
    }

    /// Test Russian Special cases (10 cases)
    func testRussianSpecialCases() {
        let profileId = "rus_standard"
        let testCases = testCaseProvider.getTestCases(for: profileId, category: "sokuon") +
                        testCaseProvider.getTestCases(for: profileId, category: "long-vowel") +
                        testCaseProvider.getTestCases(for: profileId, category: "separation") +
                        testCaseProvider.getTestCases(for: profileId, category: "n-combinations") +
                        testCaseProvider.getTestCases(for: profileId, category: "standalone-n") +
                        testCaseProvider.getTestCases(for: profileId, category: "special")

        runCategoryTests(profileId: profileId, testCases: testCases, categoryName: "Special Cases")
    }

    // MARK: - Other Profiles (to be implemented in Phase 1)

    /// Test ALL Serbian cases (112 test cases)
    /// NOTE: This will be implemented when Serbian profile is complete (Phase 1)
    func testAllSerbian_112Cases() {
        let profileId = "srb_cyrillic"
        let testCases = testCaseProvider.getTestCases(for: profileId)

        guard !testCases.isEmpty else {
            print("⚠️  Serbian test cases not yet implemented (Phase 1)")
            return
        }

        runAllTests(for: profileId, testCases: testCases)
    }

    /// Test ALL Ukrainian cases (112 test cases)
    /// NOTE: This will be implemented when Ukrainian profile is complete (Phase 1)
    func testAllUkrainian_112Cases() {
        let profileId = "ukr_cyrillic"
        let testCases = testCaseProvider.getTestCases(for: profileId)

        guard !testCases.isEmpty else {
            print("⚠️  Ukrainian test cases not yet implemented (Phase 1)")
            return
        }

        runAllTests(for: profileId, testCases: testCases)
    }

    /// Test ALL Bulgarian cases (112 test cases)
    /// NOTE: This will be implemented when Bulgarian profile is complete (Phase 1)
    func testAllBulgarian_112Cases() {
        let profileId = "bul_bds"
        let testCases = testCaseProvider.getTestCases(for: profileId)

        guard !testCases.isEmpty else {
            print("⚠️  Bulgarian test cases not yet implemented (Phase 1)")
            return
        }

        runAllTests(for: profileId, testCases: testCases)
    }

    /// Test ALL Russian Analytical cases (112 test cases)
    /// NOTE: This will be implemented when Analytical profile is complete (Phase 1)
    func testAllRussianAnalytical_112Cases() {
        let profileId = "rus_analytical"
        let testCases = testCaseProvider.getTestCases(for: profileId)

        guard !testCases.isEmpty else {
            print("⚠️  Russian Analytical test cases not yet implemented (Phase 1)")
            return
        }

        runAllTests(for: profileId, testCases: testCases)
    }

    // MARK: - Helper Methods

    /// Run a single test case
    private func runTestCase(_ testCase: ConversionTestCase, profileId: String) throws {
        var currentBuffer = ""
        var accumulatedOutput = ""
        var lastOutput = ""
        var lastVowelType: String? = nil

        for (index, key) in testCase.input.enumerated() {
            guard let result = rustCore.processKey(
                cyrillicKey: key,
                currentBuffer: currentBuffer,
                profileId: profileId,
                lastOutput: lastOutput,
                lastVowelType: lastVowelType
            ) else {
                throw NSError(
                    domain: "ConversionError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Rust Core returned nil for key '\(key)' with buffer '\(currentBuffer)'"]
                )
            }

            // Accumulate output
            if !result.output.isEmpty {
                accumulatedOutput += result.output
            }

            // Update buffer for next iteration
            currentBuffer = result.buffer

            // Update lastOutput and lastVowelType for next iteration (for long vowel detection)
            if let resultLastOutput = result.lastOutput {
                lastOutput = resultLastOutput
            }
            lastVowelType = result.lastVowelType

            print("  Step \(index + 1): Key '\(key)' → output: '\(result.output)', buffer: '\(result.buffer)', action: \(result.action), lastOutput: '\(lastOutput)', lastVowelType: \(lastVowelType ?? "nil")")
        }

        // If there's remaining buffer content, try to commit it
        // This simulates pressing space/enter to commit at the end of input
        if !currentBuffer.isEmpty {
            // Try one more processKey with empty string to force commit
            // Or we can just look up the buffer in the schema directly
            print("  Final buffer remaining: '\(currentBuffer)' - attempting to commit...")

            // Process a space character to commit the buffer
            if let commitResult = rustCore.processKey(
                cyrillicKey: " ",
                currentBuffer: currentBuffer,
                profileId: profileId,
                lastOutput: ""
            ) {
                if !commitResult.output.isEmpty {
                    accumulatedOutput += commitResult.output
                    print("  Committed buffer: '\(commitResult.output)'")
                }
            }
        }

        // Verify final output
        guard accumulatedOutput == testCase.expected else {
            throw NSError(
                domain: "ConversionError",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Expected '\(testCase.expected)' but got '\(accumulatedOutput)'",
                    "input": testCase.input.joined(),
                    "expected": testCase.expected,
                    "actual": accumulatedOutput
                ]
            )
        }
    }

    /// Run all tests for a specific profile
    private func runAllTests(for profileId: String, testCases: [ConversionTestCase]) {
        print("\n========================================")
        print("Running ALL test cases for \(profileId)")
        print("Total: \(testCases.count) test cases")
        print("========================================\n")

        // Switch to profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        var passedCount = 0
        var failedCases: [(ConversionTestCase, String)] = []

        for testCase in testCases {
            do {
                try runTestCase(testCase, profileId: profileId)
                passedCount += 1
                print("✅ \(testCase.id): PASSED")
            } catch let error as NSError {
                failedCases.append((testCase, error.localizedDescription))
                print("❌ \(testCase.id): FAILED - \(error.localizedDescription)")
            }
        }

        printSummary(profileId: profileId, passed: passedCount, failed: failedCases)

        XCTAssertEqual(failedCases.count, 0, "\(failedCases.count) test cases failed for \(profileId)")
    }

    /// Run tests for a specific category
    private func runCategoryTests(profileId: String, testCases: [ConversionTestCase], categoryName: String) {
        print("\n========================================")
        print("Testing \(categoryName) for \(profileId)")
        print("Total: \(testCases.count) test cases")
        print("========================================\n")

        guard !testCases.isEmpty else {
            print("⚠️  No test cases found for category '\(categoryName)'")
            return
        }

        // Switch to profile
        let switchError = profileManager.switchProfile(to: profileId)
        XCTAssertNil(switchError, "Should switch to \(profileId) profile")

        var passedCount = 0
        var failedCases: [(ConversionTestCase, String)] = []

        for testCase in testCases {
            do {
                try runTestCase(testCase, profileId: profileId)
                passedCount += 1
            } catch let error as NSError {
                failedCases.append((testCase, error.localizedDescription))
            }
        }

        printSummary(profileId: profileId, category: categoryName, passed: passedCount, failed: failedCases)

        XCTAssertEqual(failedCases.count, 0, "\(failedCases.count) test cases failed in \(categoryName)")
    }

    /// Print test summary
    private func printSummary(profileId: String, category: String? = nil, passed: Int, failed: [(ConversionTestCase, String)]) {
        let total = passed + failed.count
        let successRate = total > 0 ? Double(passed) / Double(total) * 100.0 : 0.0

        let categoryStr = category != nil ? " - \(category!)" : ""

        print("\n========================================")
        print("Test Summary: \(profileId)\(categoryStr)")
        print("========================================")
        print("Total:   \(total)")
        print("Passed:  \(passed)")
        print("Failed:  \(failed.count)")
        print("Success: \(String(format: "%.2f", successRate))%")
        print("========================================")

        if !failed.isEmpty {
            print("\n❌ Failed Test Cases (\(min(failed.count, 20)) of \(failed.count)):")
            for (testCase, error) in failed.prefix(20) {
                print("  [\(testCase.id)] \(testCase.description)")
                print("    Input:    \(testCase.input.joined())")
                print("    Expected: \(testCase.expected)")
                print("    Error:    \(error)")
            }
            if failed.count > 20 {
                print("  ... and \(failed.count - 20) more failures")
            }
            print("")
        }
    }

    // MARK: - Regression Tests

    /// Regression test: Ensure all previously passing tests still pass
    func testNoRegression() {
        let allTestCases = testCaseProvider.getAllTestCases()
        print("\n========================================")
        print("Regression Test: All Profiles")
        print("Total: \(allTestCases.count) test cases")
        print("========================================\n")

        var totalPassed = 0
        var totalFailed = 0

        for profileId in testCaseProvider.getAvailableProfiles() {
            let testCases = testCaseProvider.getTestCases(for: profileId)

            let switchError = profileManager.switchProfile(to: profileId)
            if switchError != nil {
                print("⚠️  Profile '\(profileId)' not available, skipping...")
                continue
            }

            var passedCount = 0
            var failedCount = 0

            for testCase in testCases {
                do {
                    try runTestCase(testCase, profileId: profileId)
                    passedCount += 1
                } catch {
                    failedCount += 1
                }
            }

            print("  \(profileId): \(passedCount)/\(testCases.count) passed")

            totalPassed += passedCount
            totalFailed += failedCount
        }

        print("\n========================================")
        print("Overall Regression Test Summary")
        print("========================================")
        print("Total Passed: \(totalPassed)")
        print("Total Failed: \(totalFailed)")
        print("Success Rate: \(String(format: "%.2f", Double(totalPassed) / Double(totalPassed + totalFailed) * 100.0))%")
        print("========================================\n")

        XCTAssertEqual(totalFailed, 0, "\(totalFailed) regression test(s) failed")
    }
}
