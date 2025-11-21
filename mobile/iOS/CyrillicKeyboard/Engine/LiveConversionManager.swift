//
//  LiveConversionManager.swift
//  CyrillicKeyboard
//
//  Manages real-time conversion as user types
//  Phase 3: Live conversion with clause-based editing
//

import Foundation
import NaturalLanguage

// MARK: - Conversion State

/// State of live conversion
enum ConversionState {
    case idle           // No active conversion
    case composing      // User is typing
    case converting     // Conversion in progress
    case converted      // Conversion complete
    case selecting      // User is selecting clause
}

// MARK: - Live Conversion Manager

/// Manages live (automatic) conversion
final class LiveConversionManager {
    // MARK: - Properties

    /// Conversion engine
    private let conversionEngine: KanjiConversionEngineProtocol

    /// Clause segmenter
    private let clauseSegmenter: ClauseSegmenter

    /// Predictive engine
    private let predictiveEngine: PredictiveEngine

    /// Whether live conversion is enabled
    var isEnabled: Bool = true

    /// Minimum hiragana length to trigger conversion
    var minimumLength: Int = 3

    /// Delay before auto-conversion (seconds)
    var conversionDelay: TimeInterval = 0.5

    /// Last input timestamp
    private var lastInputTime: Date = Date()

    /// Current conversion state
    private var state: ConversionState = .idle

    /// Current clauses
    private var clauses: [Clause] = []

    /// Currently selected clause index
    private var selectedClauseIndex: Int = 0

    /// Confirmed text (already committed)
    private var confirmedText: String = ""

    /// Conversion task (for cancellation)
    private var conversionTask: Task<Void, Never>?

    // MARK: - Callbacks

    /// Called when live conversion result is ready
    var onLiveConversionUpdated: ((String) -> Void)?

    /// Called when clauses are updated
    var onClausesUpdated: (([Clause]) -> Void)?

    /// Called when state changes
    var onStateChanged: ((ConversionState) -> Void)?

    // MARK: - Initialization

    init(conversionEngine: KanjiConversionEngineProtocol = KanjiConversionEngine.shared,
         clauseSegmenter: ClauseSegmenter = ClauseSegmenter(),
         predictiveEngine: PredictiveEngine = PredictiveEngine()) {
        self.conversionEngine = conversionEngine
        self.clauseSegmenter = clauseSegmenter
        self.predictiveEngine = predictiveEngine
    }

    // MARK: - Conversion Control

    /// Processes input for live conversion
    /// - Parameter hiragana: Current hiragana input
    func processInput(_ hiragana: String) {
        guard isEnabled else { return }

        lastInputTime = Date()
        setState(.composing)

        // Cancel previous conversion
        conversionTask?.cancel()

        // Check if we should trigger conversion
        if shouldTriggerLiveConversion(hiragana) {
            scheduleConversion(hiragana)
        }
    }

    /// Schedules conversion after delay
    private func scheduleConversion(_ hiragana: String) {
        conversionTask = Task { [weak self] in
            guard let self = self else { return }

            // Wait for delay
            try? await Task.sleep(nanoseconds: UInt64(self.conversionDelay * 1_000_000_000))

            // Check if cancelled
            guard !Task.isCancelled else { return }

            // Perform conversion
            await self.performLiveConversion(hiragana)
        }
    }

    /// Forces immediate conversion
    func forceConversion(_ hiragana: String) {
        conversionTask?.cancel()

        Task {
            await performLiveConversion(hiragana)
        }
    }

    /// Clears conversion state
    func reset() {
        conversionTask?.cancel()
        setState(.idle)
        clauses.removeAll()
        selectedClauseIndex = 0
        confirmedText = ""
        onLiveConversionUpdated?("")
        onClausesUpdated?([])
    }

    // MARK: - Private Conversion Methods

    /// Determines if live conversion should trigger
    private func shouldTriggerLiveConversion(_ hiragana: String) -> Bool {
        // Minimum length
        guard hiragana.count >= minimumLength else { return false }

        // Check if ends with particle or verb ending
        if endsWithParticle(hiragana) { return true }
        if endsWithVerbEnding(hiragana) { return true }

        // Check time elapsed since last input
        let elapsed = Date().timeIntervalSince(lastInputTime)
        if elapsed >= conversionDelay { return true }

        return false
    }

    /// Performs live conversion
    private func performLiveConversion(_ hiragana: String) async {
        setState(.converting)

        // Segment into clauses
        let segmentedClauses = clauseSegmenter.segment(hiragana)

        // Get candidates for each clause
        var clausesWithCandidates: [Clause] = []

        for clause in segmentedClauses {
            var mutableClause = clause

            // Only convert word clauses
            if clause.type == .word {
                do {
                    let candidates = try await conversionEngine.requestCandidates(
                        for: clause.text,
                        maxCount: 10
                    )
                    mutableClause.candidates = [clause.text] + candidates.map { $0.text }
                } catch {
                    print("[LiveConversionManager] Conversion failed for '\(clause.text)': \(error)")
                    mutableClause.candidates = [clause.text]
                }
            }

            clausesWithCandidates.append(mutableClause)
        }

        // Update state on main thread
        await MainActor.run {
            self.clauses = clausesWithCandidates
            self.selectedClauseIndex = 0
            self.setState(.converted)

            // Notify
            self.onClausesUpdated?(self.clauses)
            self.onLiveConversionUpdated?(self.composedText)
        }
    }

    // MARK: - Clause Navigation

    /// Moves selection to next clause
    func selectNextClause() {
        guard !clauses.isEmpty else { return }

        selectedClauseIndex = (selectedClauseIndex + 1) % clauses.count
        setState(.selecting)
        onClausesUpdated?(clauses)
    }

    /// Moves selection to previous clause
    func selectPreviousClause() {
        guard !clauses.isEmpty else { return }

        selectedClauseIndex = (selectedClauseIndex - 1 + clauses.count) % clauses.count
        setState(.selecting)
        onClausesUpdated?(clauses)
    }

    /// Cycles selected clause to next candidate
    func cycleSelectedClauseCandidate() {
        guard !clauses.isEmpty, selectedClauseIndex < clauses.count else { return }

        clauses[selectedClauseIndex].selectNext()
        setState(.selecting)
        onClausesUpdated?(clauses)
        onLiveConversionUpdated?(composedText)
    }

    /// Cycles selected clause to previous candidate
    func cyclePreviousClauseCandidate() {
        guard !clauses.isEmpty, selectedClauseIndex < clauses.count else { return }

        clauses[selectedClauseIndex].selectPrevious()
        setState(.selecting)
        onClausesUpdated?(clauses)
        onLiveConversionUpdated?(composedText)
    }

    // MARK: - Commit

    /// Commits selected clause and moves to next
    func commitSelectedClause() {
        guard !clauses.isEmpty, selectedClauseIndex < clauses.count else { return }

        let clause = clauses[selectedClauseIndex]
        confirmedText += clause.selectedCandidate

        // Learn from selection
        if clause.type == .word {
            conversionEngine.learn(clause.text, selected: clause.selectedCandidate)

            // Record in predictive engine
            if selectedClauseIndex > 0 {
                let previousClause = clauses[selectedClauseIndex - 1]
                predictiveEngine.recordSelection(
                    context: previousClause.selectedCandidate,
                    selected: clause.selectedCandidate
                )
            }
        }

        // Remove committed clause
        clauses.remove(at: selectedClauseIndex)

        // Adjust selection
        if clauses.isEmpty {
            reset()
        } else if selectedClauseIndex >= clauses.count {
            selectedClauseIndex = clauses.count - 1
        }

        onClausesUpdated?(clauses)
        onLiveConversionUpdated?(composedText)
    }

    /// Commits all clauses
    func commitAll() -> String {
        let result = composedText

        // Learn from all clauses
        for i in 0..<clauses.count {
            let clause = clauses[i]

            if clause.type == .word {
                conversionEngine.learn(clause.text, selected: clause.selectedCandidate)

                // Record bigrams
                if i > 0 {
                    let previous = clauses[i - 1]
                    predictiveEngine.recordSelection(
                        context: previous.selectedCandidate,
                        selected: clause.selectedCandidate
                    )
                }
            }
        }

        // Record full phrase
        predictiveEngine.recordPhrase(result)

        reset()
        return result
    }

    // MARK: - Helper Methods

    /// Returns composed text from all clauses
    var composedText: String {
        return confirmedText + clauses.map { $0.selectedCandidate }.joined()
    }

    /// Checks if hiragana ends with a particle
    private func endsWithParticle(_ hiragana: String) -> Bool {
        let particles = ["は", "が", "を", "に", "で", "と", "から", "まで", "へ", "の"]
        return particles.contains { hiragana.hasSuffix($0) }
    }

    /// Checks if hiragana ends with verb ending
    private func endsWithVerbEnding(_ hiragana: String) -> Bool {
        let endings = ["ます", "ました", "ません", "ませんでした", "です", "でした"]
        return endings.contains { hiragana.hasSuffix($0) }
    }

    /// Sets state and notifies
    private func setState(_ newState: ConversionState) {
        guard state != newState else { return }
        state = newState
        onStateChanged?(state)
    }

    // MARK: - Public Properties

    /// Current state
    var currentState: ConversionState {
        return state
    }

    /// Current clauses
    var currentClauses: [Clause] {
        return clauses
    }

    /// Selected clause index
    var currentSelectedIndex: Int {
        return selectedClauseIndex
    }
}
