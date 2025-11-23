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

    /// User dictionary manager (Phase 5)
    private let userDictionary: UserDictionaryManager

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

    // Smartphone-appropriate: Live conversion is always enabled
    // No need for isLiveConversionEnabled property - it's always true

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
         userDictionary: UserDictionaryManager = .shared,
         liveConversionManager: LiveConversionManager? = nil) {
        self.displayedTextManager = displayedTextManager
        self.rustCore = rustCore
        self.profileManager = profileManager
        self.conversionEngine = conversionEngine
        self.userDictionary = userDictionary
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
            profileId: profile.id,
            lastOutput: composingText.lastOutput,
            lastVowelType: composingText.lastVowelType
        ) else {
            print("[CyrillicInputManager] Error: Rust Core conversion failed")
            return
        }

        print("[CyrillicInputManager] Key '\(key)' -> buffer: '\(result.buffer)', output: '\(result.output)', action: '\(result.action)'")

        // Update composing text
        composingText.append(key: key, result: result)

        // Smartphone-appropriate: Always use automatic live conversion (japaneseIME mode)
        // No mode switching needed
        let hiragana = composingText.hiraganaTarget
        liveConversionManager.processInput(hiragana)
        // Display will be updated via callback from LiveConversionManager
    }

    // MARK: - Mode-Specific Handling
    // Smartphone-appropriate: No mode-specific handlers needed
    // Always use automatic live conversion (japaneseIME mode)

    // MARK: - Delete Handling

    /// Handles delete/backspace key (Smartphone-appropriate: no manual conversion mode)
    func processDelete() {
        // Smartphone paradigm: No manual conversion mode to exit
        if composingText.deleteBackward() {
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

    /// Handles space key press (Smartphone-appropriate: just insert space)
    /// Space key no longer triggers manual conversion - automatic live conversion handles kanji
    func processSpace() {
        // Smartphone paradigm: Commit any live conversion, then insert space
        // No manual conversion triggered by space key
        if !composingText.isEmpty {
            // Commit whatever live conversion has been done
            commitIfNeeded()
        }
        // Always insert space character
        displayedTextManager.insertText(" ")
    }

    // Smartphone-appropriate: No manual conversion methods needed
    // Automatic live conversion handles kanji conversion seamlessly

    // MARK: - Return Key Handling

    /// Handles return/enter key (Smartphone-appropriate: always use live conversion)
    func processReturn() {
        // Smartphone paradigm: Always using automatic live conversion
        if liveConversionManager.currentState != .idle {
            // Commit all live conversion clauses
            let result = liveConversionManager.commitAll()
            displayedTextManager.insertText(result)
            composingText.clear()
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
        let hiragana = composingText.hiraganaTarget

        // Phase 5: Record usage in user dictionary
        userDictionary.recordUsage(reading: hiragana, output: selected)

        // Learn from user selection in system conversion engine
        conversionEngine.learn(hiragana, selected: selected)

        commitText(selected)
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

    // MARK: - Arrow Key Handling (Smartphone-appropriate: always enabled)

    /// Handles left arrow key (move to previous clause)
    func processLeftArrow() {
        // Smartphone paradigm: Live conversion always enabled
        if liveConversionManager.currentState != .idle {
            liveConversionManager.selectPreviousClause()
        }
    }

    /// Handles right arrow key (move to next clause)
    func processRightArrow() {
        // Smartphone paradigm: Live conversion always enabled
        if liveConversionManager.currentState != .idle {
            liveConversionManager.selectNextClause()
        }
    }

    // MARK: - Live Conversion Control (Smartphone-appropriate: always enabled)

    // Smartphone paradigm: No toggle needed - live conversion always enabled
    // toggleLiveConversion() method removed

    /// Forces immediate conversion
    func forceConversion() {
        // Smartphone paradigm: Live conversion always enabled
        if !composingText.isEmpty {
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
