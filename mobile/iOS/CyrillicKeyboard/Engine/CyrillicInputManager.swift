//
//  CyrillicInputManager.swift
//  CyrillicKeyboard
//
//  Orchestrates Cyrillic input and Japanese conversion
//  Based on azooKey's InputManager pattern
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
    private let conversionEngine: KanjiConversionEngine?

    /// Current composing text state
    private var composingText: CyrillicComposingText = CyrillicComposingText()

    /// Current input mode
    private var currentInputMode: InputMode = .japaneseIME

    /// Conversion candidates (Phase 2: Kanji conversion)
    private var candidates: [Candidate] = []

    /// Whether currently in conversion mode
    private var isConverting: Bool = false

    /// Selected candidate index
    private var selectedCandidateIndex: Int = 0

    // MARK: - Callbacks

    /// Called when candidates should be displayed
    var onCandidatesUpdated: (([String]) -> Void)?

    /// Called when composing text changes
    var onComposingTextChanged: ((String) -> Void)?

    // MARK: - Initialization

    init(displayedTextManager: DisplayedTextManager,
         rustCore: RustCoreFFI = .shared,
         profileManager: ProfileManager = .shared,
         conversionEngine: KanjiConversionEngine? = nil) {
        self.displayedTextManager = displayedTextManager
        self.rustCore = rustCore
        self.profileManager = profileManager
        self.conversionEngine = conversionEngine
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

    /// IME mode: Show hiragana, allow space for conversion (Phase 2)
    private func handleIMEMode(result: ConversionResult) {
        // Show hiragana as composing text
        displayedTextManager.updateComposingText(composingText.hiraganaTarget)
        onComposingTextChanged?(composingText.hiraganaTarget)

        // Phase 2: Request kanji candidates for live preview (optional)
        if !composingText.hiraganaTarget.isEmpty {
            requestConversionCandidatesAsync()
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
            if isConverting {
                // Already converting: cycle to next candidate
                cycleToNextCandidate()
            } else {
                // Start conversion
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

        // Phase 2: Get real kanji candidates from conversion engine
        if let engine = conversionEngine {
            Task {
                do {
                    let candidateList = try await engine.requestCandidates(
                        for: composingText.hiraganaTarget,
                        maxCount: 10
                    )

                    await MainActor.run {
                        self.candidates = candidateList
                        self.selectedCandidateIndex = 0
                        self.onCandidatesUpdated?(candidateList.map { $0.text })

                        // Show first candidate as live conversion
                        if !candidateList.isEmpty {
                            self.displayedTextManager.updateComposingText(
                                self.composingText.hiraganaTarget,
                                liveConversionText: candidateList[0].text
                            )
                        }

                        print("[CyrillicInputManager] Started conversion with \(candidateList.count) candidates")
                    }
                } catch {
                    print("[CyrillicInputManager] Conversion error: \(error)")
                    await MainActor.run {
                        self.showFallbackCandidates()
                    }
                }
            }
        } else {
            // Fallback: No conversion engine, show hiragana and katakana only
            showFallbackCandidates()
        }
    }

    /// Cycles to next candidate
    private func cycleToNextCandidate() {
        guard !candidates.isEmpty else { return }

        selectedCandidateIndex = (selectedCandidateIndex + 1) % candidates.count
        let selected = candidates[selectedCandidateIndex]

        // Update display with selected candidate
        displayedTextManager.updateComposingText(
            composingText.hiraganaTarget,
            liveConversionText: selected.text
        )

        print("[CyrillicInputManager] Cycled to candidate: '\(selected.text)'")
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
        if isConverting && !candidates.isEmpty {
            // Commit selected candidate
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

        // Phase 2: Learn from selection
        conversionEngine?.learn(input: composingText.hiraganaTarget, selected: selected)

        commitText(selected.text)
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

    // MARK: - Conversion Helpers (Phase 2)

    /// Requests conversion candidates asynchronously (for live preview)
    /// Does not enter conversion mode, just prepares candidates
    private func requestConversionCandidatesAsync() {
        guard let engine = conversionEngine else { return }

        Task {
            do {
                let candidateList = try await engine.requestCandidates(
                    for: composingText.hiraganaTarget,
                    maxCount: 5 // Fewer for live preview
                )

                await MainActor.run {
                    // Only update if still composing the same text
                    if !self.composingText.hiraganaTarget.isEmpty {
                        self.candidates = candidateList
                        print("[CyrillicInputManager] Live candidates ready: \(candidateList.map { $0.text })")
                    }
                }
            } catch {
                // Silently fail for live preview
                print("[CyrillicInputManager] Live conversion failed: \(error)")
            }
        }
    }

    /// Shows fallback candidates (hiragana + katakana only)
    /// Used when conversion engine is not available or fails
    private func showFallbackCandidates() {
        var candidateList = [Candidate]()

        // Hiragana as-is
        candidateList.append(Candidate(
            text: composingText.hiraganaTarget,
            type: .hiragana,
            score: 1.0,
            metadata: CandidateMetadata(partOfSpeech: nil, frequency: nil, source: "hiragana")
        ))

        // Katakana
        if let katakana = convertToKatakana(composingText.hiraganaTarget) {
            candidateList.append(Candidate(
                text: katakana,
                type: .katakana,
                score: 0.5,
                metadata: CandidateMetadata(partOfSpeech: nil, frequency: nil, source: "katakana")
            ))
        }

        candidates = candidateList
        selectedCandidateIndex = 0
        onCandidatesUpdated?(candidateList.map { $0.text })

        print("[CyrillicInputManager] Fallback candidates: \(candidateList.map { $0.text })")
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

    // MARK: - Public State Access

    var currentComposingText: String {
        return composingText.hiraganaTarget
    }

    var hasComposingText: Bool {
        return !composingText.isEmpty
    }
}
