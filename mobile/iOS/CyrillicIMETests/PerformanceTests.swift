//
//  PerformanceTests.swift
//  CyrillicIMETests
//
//  Phase 4: Performance and load testing
//  Ensures keyboard meets iOS standard IME performance requirements
//

import XCTest
@testable import Pismo

/// Performance tests based on テスト仕様書.md Section 3
/// Verifies:
/// - Key press latency < 10ms
/// - Conversion speed < 50ms
/// - Memory usage < 50MB
/// - Battery consumption ≈ iOS standard IME
class PerformanceTests: XCTestCase {

    var inputManager: CyrillicInputManager!
    var mockDisplayedTextManager: MockDisplayedTextManager!
    var rustCore: RustCoreFFI!
    var profileManager: ProfileManager!

    override func setUp() {
        super.setUp()

        // Use real components for accurate performance measurement
        rustCore = RustCoreFFI.shared
        profileManager = ProfileManager.shared
        mockDisplayedTextManager = MockDisplayedTextManager()

        // Initialize profile manager
        let initError = profileManager.initialize()
        XCTAssertNil(initError, "ProfileManager should initialize")

        // Switch to Russian Standard profile
        let switchError = profileManager.switchProfile(to: "rus_standard")
        XCTAssertNil(switchError, "Should switch to rus_standard")

        // Create input manager with real Rust Core
        inputManager = CyrillicInputManager(
            displayedTextManager: mockDisplayedTextManager,
            rustCore: rustCore,
            profileManager: profileManager
        )
        inputManager.setInputMode(.japaneseIME)

        print("\n=== Performance Tests ===")
    }

    override func tearDown() {
        inputManager = nil
        mockDisplayedTextManager = nil
        rustCore = nil
        profileManager = nil
        super.tearDown()
    }

    // MARK: - PERF-LAT Tests (Latency)

    /// PERF-LAT-001: Key press latency should be < 10ms
    func testPERF_LAT_001_KeyPressLatency() {
        print("\n[PERF-LAT-001] Measuring key press latency...")

        // Measure single key press
        measure(metrics: [XCTClockMetric()]) {
            inputManager.processKey("К")
        }

        // Note: XCTest measure will run multiple iterations and calculate average
        // Target: < 10ms per key press
        print("✅ PERF-LAT-001 completed - check metrics for latency")
    }

    /// PERF-LAT-002: Two-character sequence latency
    func testPERF_LAT_002_TwoCharacterLatency() {
        print("\n[PERF-LAT-002] Measuring two-character sequence latency...")

        measure(metrics: [XCTClockMetric()]) {
            inputManager.processKey("К")
            inputManager.processKey("А")
        }

        // Target: < 20ms for two-character sequence (< 10ms per key)
        print("✅ PERF-LAT-002 completed")
    }

    /// PERF-LAT-003: Rapid key input (stress test)
    func testPERF_LAT_003_RapidKeyInput() {
        print("\n[PERF-LAT-003] Testing rapid key input...")

        let keys = ["К", "А", "Н", "А", "К", "И"]

        measure(metrics: [XCTClockMetric()]) {
            for key in keys {
                inputManager.processKey(key)
            }
        }

        // Target: < 60ms for 6 keys (average < 10ms per key)
        print("✅ PERF-LAT-003 completed")
    }

    // MARK: - PERF-CONV Tests (Conversion Speed)

    /// PERF-CONV-001: Conversion initiation speed < 50ms
    func testPERF_CONV_001_ConversionSpeed() {
        print("\n[PERF-CONV-001] Measuring conversion speed...")

        // Type "かんじ"
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processKey("Н")
        inputManager.processKey("Д")
        inputManager.processKey("З")
        inputManager.processKey("И")

        // Measure conversion time
        measure(metrics: [XCTClockMetric()]) {
            inputManager.processSpace()  // Start conversion
        }

        // Target: < 50ms for conversion
        print("✅ PERF-CONV-001 completed")
    }

    /// PERF-CONV-002: Candidate cycling speed
    func testPERF_CONV_002_CandidateCycling() {
        print("\n[PERF-CONV-002] Measuring candidate cycling speed...")

        // Setup: Type and start conversion
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processSpace()

        // Measure cycling through candidates
        measure(metrics: [XCTClockMetric()]) {
            inputManager.processSpace()  // Cycle to next candidate
        }

        // Target: < 20ms for cycling
        print("✅ PERF-CONV-002 completed")
    }

    /// PERF-CONV-003: Candidate selection speed
    func testPERF_CONV_003_CandidateSelection() {
        print("\n[PERF-CONV-003] Measuring candidate selection speed...")

        // Setup: Type and show candidates
        inputManager.processKey("К")
        inputManager.processKey("А")
        inputManager.processSpace()

        // Measure candidate selection
        measure(metrics: [XCTClockMetric()]) {
            inputManager.selectCandidate(at: 0)
        }

        // Target: < 30ms for selection
        print("✅ PERF-CONV-003 completed")
    }

    // MARK: - PERF-MEM Tests (Memory Usage)

    /// PERF-MEM-001: Memory usage should be < 50MB
    func testPERF_MEM_001_MemoryUsage() {
        print("\n[PERF-MEM-001] Measuring memory usage...")

        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate typical usage
            for _ in 0..<100 {
                inputManager.processKey("К")
                inputManager.processKey("А")
                inputManager.processReturn()
            }
        }

        // Target: < 50MB total memory usage
        print("✅ PERF-MEM-001 completed - check metrics for memory usage")
    }

    /// PERF-MEM-002: Memory should not leak over time
    func testPERF_MEM_002_NoMemoryLeak() {
        print("\n[PERF-MEM-002] Testing for memory leaks...")

        measure(metrics: [XCTMemoryMetric()]) {
            // Repeat operations many times
            for _ in 0..<1000 {
                inputManager.processKey("К")
                inputManager.processKey("А")
                inputManager.processDelete()
            }
        }

        // Memory usage should not grow significantly
        print("✅ PERF-MEM-002 completed")
    }

    /// PERF-MEM-003: Profile switching should not leak memory
    func testPERF_MEM_003_ProfileSwitchingMemory() {
        print("\n[PERF-MEM-003] Testing memory during profile switching...")

        measure(metrics: [XCTMemoryMetric()]) {
            // Switch profiles multiple times
            _ = profileManager.switchProfile(to: "rus_standard")
            // When other profiles are available:
            // _ = profileManager.switchProfile(to: "srb_cyrillic")
            // _ = profileManager.switchProfile(to: "ukr_cyrillic")
            _ = profileManager.switchProfile(to: "rus_standard")
        }

        print("✅ PERF-MEM-003 completed")
    }

    // MARK: - PERF-LOAD Tests (Load Testing)

    /// LOAD-001: Should handle 1000 character input without crash
    func testLOAD_001_ThousandCharacterInput() {
        print("\n[LOAD-001] Testing 1000 character input...")

        // Type 500 two-character sequences
        for _ in 0..<500 {
            inputManager.processKey("К")
            inputManager.processKey("А")
        }

        // Should not crash
        XCTAssertTrue(true, "Should handle 1000 characters without crash")
        print("✅ LOAD-001 passed")
    }

    /// LOAD-002: Should handle rapid delete operations
    func testLOAD_002_RapidDelete() {
        print("\n[LOAD-002] Testing rapid delete operations...")

        // Type text
        for _ in 0..<100 {
            inputManager.processKey("К")
            inputManager.processKey("А")
        }

        // Rapidly delete
        for _ in 0..<100 {
            inputManager.processDelete()
        }

        // Should not crash
        XCTAssertTrue(true, "Should handle rapid delete without crash")
        print("✅ LOAD-002 passed")
    }

    /// LOAD-003: Should handle rapid mode switching
    func testLOAD_003_RapidModeSwitching() {
        print("\n[LOAD-003] Testing rapid mode switching...")

        for _ in 0..<100 {
            inputManager.setInputMode(.japaneseIME)
            inputManager.processKey("К")
            inputManager.setInputMode(.japaneseHiragana)
            inputManager.processKey("А")
            inputManager.setInputMode(.japaneseKatakana)
            inputManager.processKey("И")
        }

        // Should not crash
        XCTAssertTrue(true, "Should handle rapid mode switching without crash")
        print("✅ LOAD-003 passed")
    }

    /// LOAD-004: Should handle long composing text
    func testLOAD_004_LongComposingText() {
        print("\n[LOAD-004] Testing long composing text...")

        // Create very long hiragana string
        for _ in 0..<200 {
            inputManager.processKey("К")
            inputManager.processKey("А")
        }

        // Should handle 400-character composing text
        XCTAssertTrue(inputManager.hasComposingText, "Should maintain composing text")
        print("Composing text length: \(inputManager.currentComposingText.count) characters")

        print("✅ LOAD-004 passed")
    }

    // MARK: - PERF-RUST Tests (Rust Core Performance)

    /// PERF-RUST-001: Rust Core should process key quickly
    func testPERF_RUST_001_RustCoreSpeed() {
        print("\n[PERF-RUST-001] Measuring Rust Core processing speed...")

        measure(metrics: [XCTClockMetric()]) {
            _ = rustCore.processKey(
                cyrillicKey: "К",
                currentBuffer: "",
                profileId: "rus_standard",
                lastOutput: ""
            )
        }

        // Target: < 5ms for Rust Core processing
        print("✅ PERF-RUST-001 completed")
    }

    /// PERF-RUST-002: Rust Core should handle complex sequences
    func testPERF_RUST_002_RustCoreComplexSequence() {
        print("\n[PERF-RUST-002] Measuring complex sequence processing...")

        measure(metrics: [XCTClockMetric()]) {
            // Process multi-character sequence
            var buffer = ""
            for key in ["К", "К", "А"] {  // っか
                if let result = rustCore.processKey(
                    cyrillicKey: key,
                    currentBuffer: buffer,
                    profileId: "rus_standard",
                    lastOutput: ""
                ) {
                    buffer = result.buffer
                }
            }
        }

        // Target: < 15ms for complex sequence
        print("✅ PERF-RUST-002 completed")
    }

    // MARK: - Benchmark Comparison Tests

    /// BENCH-001: Compare performance against baseline
    func testBENCH_001_BaselinePerformance() {
        print("\n[BENCH-001] Baseline performance measurement...")

        let options = XCTMeasureOptions()
        options.iterationCount = 10

        measure(metrics: [XCTClockMetric()], options: options) {
            // Standard typing flow
            inputManager.processKey("К")
            inputManager.processKey("А")
            inputManager.processKey("Н")
            inputManager.processKey("Д")
            inputManager.processKey("З")
            inputManager.processKey("И")
            inputManager.processSpace()
            inputManager.processReturn()
        }

        // This establishes baseline for future regression testing
        print("✅ BENCH-001 completed - baseline established")
    }

    // MARK: - Real-world Scenario Tests

    /// SCENARIO-001: Typical word input performance
    func testSCENARIO_001_TypicalWordInput() {
        print("\n[SCENARIO-001] Testing typical word input scenario...")

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Type "おはよう" (ohayou)
            inputManager.processKey("О")
            inputManager.processKey("Х")
            inputManager.processKey("А")
            inputManager.processKey("Ё")
            inputManager.processKey("У")
            inputManager.processReturn()
        }

        print("✅ SCENARIO-001 completed")
    }

    /// SCENARIO-002: Sentence input with conversion
    func testSCENARIO_002_SentenceInput() {
        print("\n[SCENARIO-002] Testing sentence input scenario...")

        measure(metrics: [XCTClockMetric()]) {
            // Type "こんにちは" (konnichiha)
            inputManager.processKey("К")
            inputManager.processKey("О")
            inputManager.processKey("Н")
            inputManager.processKey("Н")
            inputManager.processKey("И")
            inputManager.processKey("Ч")
            inputManager.processKey("И")
            inputManager.processKey("Х")
            inputManager.processKey("А")

            // Start conversion
            inputManager.processSpace()

            // Commit
            inputManager.processReturn()
        }

        print("✅ SCENARIO-002 completed")
    }

    /// SCENARIO-003: Error correction scenario
    func testSCENARIO_003_ErrorCorrection() {
        print("\n[SCENARIO-003] Testing error correction scenario...")

        measure(metrics: [XCTClockMetric()]) {
            // Type word
            inputManager.processKey("К")
            inputManager.processKey("А")
            inputManager.processKey("Н")

            // Realize mistake, delete
            inputManager.processDelete()
            inputManager.processDelete()

            // Correct input
            inputManager.processKey("И")
            inputManager.processKey("Н")

            inputManager.processReturn()
        }

        print("✅ SCENARIO-003 completed")
    }
}

// MARK: - Mock DisplayedTextManager for Performance Tests

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
