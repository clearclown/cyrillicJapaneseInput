//
//  CyrillicInputManager.swift
//  CyrillicKeyboard
//
//  Orchestrates Cyrillic input and Japanese conversion
//  Based on azooKey's InputManager pattern
//  Phase 3: Integrated with LiveConversionManager
//

import Foundation

/// Manages the entire input flow from Cyrillic keystroke to Japanese output
final class CyrillicInputManager {
    // MARK: - Properties

    /// Manages text display in the text field
    private let displayedTextManager: DisplayedTextManager

    /// Rust Core engine for Cyrillic → Hiragana conversion
    private let rustCore: RustCoreFFI

    /// Current profile manager
    private let profileManager: ProfileManager

    /// Kanji conversion engine (Phase 2)
    private let conversionEngine: KanjiConversionEngineProtocol

    /// Live conversion manager (Phase 3)
    private let liveConversionManager: LiveConversionManager

    /// Current composing text state
    private var composingText: CyrillicComposingText = CyrillicComposingText()

    /// Current input mode
    private var currentInputMode: InputMode = .japaneseIME

    /// Conversion candidates (for Phase 2: Manual conversion)
    private var candidates: [String] = []

    /// Whether currently in conversion mode
    private var isConverting: Bool = false

    /// Selected candidate index
    private var selectedCandidateIndex: Int = 0

    /// Whether live conversion is enabled (Phase 3)
    var isLiveConversionEnabled: Bool = true {
        didSet {
            liveConversionManager.isEnabled = isLiveConversionEnabled
        }
    }

    // MARK: - Callbacks

    /// Called when candidates should be displayed
    var onCandidatesUpdated: (([String]) -> Void)?

    /// Called when composing text changes
    var onComposingTextChanged: ((String) -> Void)?

    /// Called when clauses are updated (Phase 3)
    var onClausesUpdated: (([Clause]) -> Void)?

    // MARK: - Initialization

    init(displayedTextManager: DisplayedTextManager,
         rustCore: RustCoreFFI = .shared,
         profileManager: ProfileManager = .shared,
         conversionEngine: KanjiConversionEngineProtocol = KanjiConversionEngine.shared,
         liveConversionManager: LiveConversionManager? = nil) {
        self.displayedTextManager = displayedTextManager
        self.rustCore = rustCore
        self.profileManager = profileManager
        self.conversionEngine = conversionEngine
        self.liveConversionManager = liveConversionManager ?? LiveConversionManager(
            conversionEngine: conversionEngine
        )

        setupLiveConversionCallbacks()
    }

    /// Sets up callbacks for live conversion manager
    private func setupLiveConversionCallbacks() {
        liveConversionManager.onLiveConversionUpdated = { [weak self] text in
            self?.onComposingTextChanged?(text)
        }

        liveConversionManager.onClausesUpdated = { [weak self] clauses in
            self?.onClausesUpdated?(clauses)
        }

        liveConversionManager.onStateChanged = { [weak self] state in
            print("[CyrillicInputManager] Live conversion state: \(state)")
        }
    }

    // MARK: - Mode Management

    func setInputMode(_ mode: InputMode) {
        currentInputMode = mode
        print("[CyrillicInputManager] Input mode set to: \(mode)")
    }

    // MARK: - Key Input Processing

    /// Processes a Cyrillic key press
    /// - Parameter key: The Cyrillic key pressed
    func processKey(_ key: String) {
        guard let profile = profileManager.currentProfile else {
            print("[CyrillicInputManager] Error: No current profile")
            return
        }

        // Get current buffer for Rust Core
        let currentBuffer = composingText.cyrillicBuffer

        // Call Rust Core for Cyrillic → Hiragana conversion
        guard let result = rustCore.processKey(
            cyrillicKey: key,
            currentBuffer: currentBuffer,
            profileId: profile.id
        ) else {
            print("[CyrillicInputManager] Error: Rust Core conversion failed")
            return
        }

        print("[CyrillicInputManager] Key '\(key)' -> buffer: '\(result.buffer)', output: '\(result.output)', action: '\(result.action)'")

        // Update composing text
        composingText.append(key: key, result: result)

        // Handle based on input mode
        switch currentInputMode {
        case .directCyrillic:
            handleDirectCyrillicMode(result: result)

        case .japaneseHiragana:
            handleHiraganaMode(result: result)

        case .japaneseIME:
            handleIMEMode(result: result)
        }
    }

    // MARK: - Mode-Specific Handling

    /// Direct Cyrillic mode: Output Cyrillic characters directly
    private func handleDirectCyrillicMode(result: ConversionResult) {
        if result.action == "commit" && !result.output.isEmpty {
            // Commit Cyrillic directly (actually this mode doesn't make sense for this IME)
            // For now, just output the Cyrillic key
            displayedTextManager.insertText(result.output)
            composingText.clear()
        } else {
            // Update display (but this mode is not typical for our use case)
            displayedTextManager.updateComposingText(result.buffer)
        }
    }

    /// Hiragana mode: Output hiragana immediately without conversion
    private func handleHiraganaMode(result: ConversionResult) {
        if result.action == "commit" && !result.output.isEmpty {
            // Commit hiragana immediately
            displayedTextManager.insertText(result.output)
            // Don't clear entire composing text, just update
            composingText.setHiragana("", buffer: result.buffer)
        } else {
            // Show hiragana as composing
            displayedTextManager.updateComposingText(composingText.hiraganaTarget)
            onComposingTextChanged?(composingText.hiraganaTarget)
        }
    }

    /// IME mode: Show hiragana, allow space for conversion (Phase 2/3)
    private func handleIMEMode(result: ConversionResult) {
        let hiragana = composingText.hiraganaTarget

        if isLiveConversionEnabled {
            // Phase 3: Use live conversion
            liveConversionManager.processInput(hiragana)
            // Display will be updated via callback
        } else {
            // Phase 1/2: Manual conversion mode
            displayedTextManager.updateComposingText(hiragana)
            onComposingTextChanged?(hiragana)
        }
    }

    // MARK: - Delete Handling

    /// Handles delete/backspace key
    func processDelete() {
        if isConverting && !candidates.isEmpty {
            // Exit conversion mode
            exitConversionMode()
        } else if composingText.deleteBackward() {
            // Rebuild composing text from history
            rebuildComposingText()
        } else {
            // No composing text, delete from document
            displayedTextManager.deleteBackward()
        }
    }

    /// Rebuilds composing text from key history
    private func rebuildComposingText() {
        guard let profile = profileManager.currentProfile else { return }

        // Clear current state
        var newHiragana = ""
        var newBuffer = ""

        // Replay all keys
        for key in composingText.cyrillicKeys {
            guard let result = rustCore.processKey(
                cyrillicKey: key,
                currentBuffer: newBuffer,
                profileId: profile.id
            ) else {
                continue
            }

            if !result.output.isEmpty {
                newHiragana += result.output
            }
            newBuffer = result.buffer
        }

        // Update composing text
        composingText.setHiragana(newHiragana, buffer: newBuffer)

        // Update display
        displayedTextManager.updateComposingText(newHiragana)
        onComposingTextChanged?(newHiragana)

        print("[CyrillicInputManager] Rebuilt composing text: '\(newHiragana)'")
    }

    // MARK: - Space Key Handling

    /// Handles space key press
    func processSpace() {
        if currentInputMode == .japaneseIME && !composingText.isEmpty {
            if isLiveConversionEnabled {
                // Phase 3: Cycle selected clause candidate
                liveConversionManager.cycleSelectedClauseCandidate()
            } else if isConverting {
                // Phase 2: Already converting: cycle to next candidate
                cycleToNextCandidate()
            } else {
                // Phase 2: Start conversion
                startConversion()
            }
        } else {
            // No composing text: insert space
            commitIfNeeded()
            displayedTextManager.insertText(" ")
        }
    }

    /// Starts kanji conversion mode (Phase 2)
    private func startConversion() {
        isConverting = true

        // TODO Phase 2: Get real kanji candidates
        // For now, just show hiragana and katakana
        var candidateList = [composingText.hiraganaTarget]

        if let katakana = convertToKatakana(composingText.hiraganaTarget) {
            candidateList.append(katakana)
        }

        candidates = candidateList
        selectedCandidateIndex = 0

        onCandidatesUpdated?(candidates)

        print("[CyrillicInputManager] Started conversion with \(candidates.count) candidates")
    }

    /// Cycles to next candidate
    private func cycleToNextCandidate() {
        guard !candidates.isEmpty else { return }

        selectedCandidateIndex = (selectedCandidateIndex + 1) % candidates.count
        let selected = candidates[selectedCandidateIndex]

        // Update display with selected candidate
        displayedTextManager.updateComposingText(
            composingText.hiraganaTarget,
            liveConversionText: selected
        )

        print("[CyrillicInputManager] Cycled to candidate: '\(selected)'")
    }

    /// Exits conversion mode
    private func exitConversionMode() {
        isConverting = false
        selectedCandidateIndex = 0
        candidates = []

        // Revert to hiragana display
        displayedTextManager.updateComposingText(composingText.hiraganaTarget)
        onCandidatesUpdated?([])

        print("[CyrillicInputManager] Exited conversion mode")
    }

    // MARK: - Return Key Handling

    /// Handles return/enter key
    func processReturn() {
        if isLiveConversionEnabled && liveConversionManager.currentState != .idle {
            // Phase 3: Commit all clauses
            let result = liveConversionManager.commitAll()
            displayedTextManager.insertText(result)
            composingText.clear()
        } else if isConverting && !candidates.isEmpty {
            // Phase 2: Commit selected candidate
            commitCandidate(at: selectedCandidateIndex)
        } else if !composingText.isEmpty {
            // Commit composing text as-is
            commitText(composingText.hiraganaTarget)
        }
        // Note: Caller should insert newline after this
    }

    // MARK: - Candidate Selection

    /// Selects and commits a candidate
    /// - Parameter index: Candidate index
    func selectCandidate(at index: Int) {
        guard index < candidates.count else { return }
        commitCandidate(at: index)
    }

    /// Commits a candidate
    private func commitCandidate(at index: Int) {
        let selected = candidates[index]
        commitText(selected)

        // TODO Phase 2: Learn from selection
        // conversionEngine.learn(composingText.hiraganaTarget, selected: selected)
    }

    // MARK: - Commit and Clear

    /// Commits text and clears composing state
    private func commitText(_ text: String) {
        displayedTextManager.insertText(text)
        clearComposingState()
    }

    /// Commits composing text if any
    func commitIfNeeded() {
        if !composingText.isEmpty {
            commitText(composingText.hiraganaTarget)
        }
    }

    /// Clears all composing state
    private func clearComposingState() {
        composingText.clear()
        isConverting = false
        selectedCandidateIndex = 0
        candidates = []
        onCandidatesUpdated?([])
        onComposingTextChanged?("")
    }

    // MARK: - Utility Methods

    /// Converts hiragana to katakana
    private func convertToKatakana(_ hiragana: String) -> String? {
        let mutableString = NSMutableString(string: hiragana)
        if CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, false) {
            return mutableString as String
        }
        return nil
    }

    // MARK: - Arrow Key Handling (Phase 3)

    /// Handles left arrow key (move to previous clause)
    func processLeftArrow() {
        if isLiveConversionEnabled && liveConversionManager.currentState != .idle {
            liveConversionManager.selectPreviousClause()
        }
    }

    /// Handles right arrow key (move to next clause)
    func processRightArrow() {
        if isLiveConversionEnabled && liveConversionManager.currentState != .idle {
            liveConversionManager.selectNextClause()
        }
    }

    // MARK: - Live Conversion Control (Phase 3)

    /// Toggles live conversion on/off
    func toggleLiveConversion() {
        isLiveConversionEnabled.toggle()
        print("[CyrillicInputManager] Live conversion: \(isLiveConversionEnabled ? "enabled" : "disabled")")
    }

    /// Forces immediate conversion
    func forceConversion() {
        if isLiveConversionEnabled && !composingText.isEmpty {
            liveConversionManager.forceConversion(composingText.hiraganaTarget)
        }
    }

    // MARK: - Public State Access

    var currentComposingText: String {
        return composingText.hiraganaTarget
    }

    var hasComposingText: Bool {
        return !composingText.isEmpty
    }

    /// Current clauses (Phase 3)
    var currentClauses: [Clause] {
        return liveConversionManager.currentClauses
    }

    /// Selected clause index (Phase 3)
    var selectedClauseIndex: Int {
        return liveConversionManager.currentSelectedIndex
    }
}
