//
//  CyrillicComposingText.swift
//  Cyrillic IME
//
//  Model for managing Cyrillic composing text state
//

import Foundation

/// Represents the composing text state for Cyrillic → Japanese input
struct CyrillicComposingText {
    // MARK: - Properties

    /// History of Cyrillic keys pressed (for reconstruction on delete)
    private(set) var cyrillicKeys: [String] = []

    /// Current Cyrillic buffer (incomplete characters, e.g., "К")
    private(set) var cyrillicBuffer: String = ""

    /// Converted hiragana target (e.g., "か", "かい")
    private(set) var hiraganaTarget: String = ""

    /// Cursor position within hiragana target
    private(set) var cursorPosition: Int = 0

    /// Last output from conversion (for long vowel detection)
    private(set) var lastOutput: String = ""

    /// Last vowel type (for consecutive long vowel detection)
    private(set) var lastVowelType: String? = nil

    // MARK: - Computed Properties

    /// Whether there is any composing text
    var isEmpty: Bool {
        return cyrillicKeys.isEmpty && cyrillicBuffer.isEmpty && hiraganaTarget.isEmpty
    }

    /// Total number of hiragana characters
    var hiraganaCount: Int {
        return hiraganaTarget.count
    }

    /// Debug description
    var debugDescription: String {
        return """
        CyrillicComposingText:
          keys: \(cyrillicKeys)
          buffer: '\(cyrillicBuffer)'
          hiragana: '\(hiraganaTarget)'
          cursor: \(cursorPosition)
        """
    }

    // MARK: - Initialization

    init() {}

    init(cyrillicKeys: [String], cyrillicBuffer: String, hiraganaTarget: String, cursorPosition: Int = 0) {
        self.cyrillicKeys = cyrillicKeys
        self.cyrillicBuffer = cyrillicBuffer
        self.hiraganaTarget = hiraganaTarget
        self.cursorPosition = min(cursorPosition, hiraganaTarget.count)
    }

    // MARK: - Mutation Methods

    /// Appends a new Cyrillic key and its conversion result
    /// - Parameters:
    ///   - key: The Cyrillic key pressed
    ///   - result: Conversion result from Rust Core
    mutating func append(key: String, result: ConversionResult) {
        // Add to history
        cyrillicKeys.append(key)

        // Update buffer
        cyrillicBuffer = result.buffer

        // Track last output and vowel type for long vowel detection
        if !result.output.isEmpty {
            hiraganaTarget += result.output
            cursorPosition = hiraganaTarget.count
            lastOutput = result.lastOutput ?? ""
            lastVowelType = result.lastVowelType
        }

        print("[CyrillicComposingText] Appended '\(key)' -> buffer: '\(cyrillicBuffer)', hiragana: '\(hiraganaTarget)', lastOutput: '\(lastOutput)', lastVowelType: '\(lastVowelType ?? "nil")'")
    }

    /// Deletes the last character backward
    /// - Returns: Whether deletion was successful
    @discardableResult
    mutating func deleteBackward() -> Bool {
        guard !cyrillicKeys.isEmpty else {
            return false
        }

        // Remove last key from history
        cyrillicKeys.removeLast()

        // Need to rebuild from scratch
        // This is handled by CyrillicInputManager.rebuildComposingText()
        // Here we just mark that we need rebuilding

        print("[CyrillicComposingText] Deleted backward, keys remaining: \(cyrillicKeys.count)")
        return true
    }

    /// Clears all composing text
    mutating func clear() {
        cyrillicKeys.removeAll()
        cyrillicBuffer = ""
        hiraganaTarget = ""
        cursorPosition = 0
        lastOutput = ""
        lastVowelType = nil

        print("[CyrillicComposingText] Cleared all composing text")
    }

    /// Updates the cursor position
    /// - Parameter position: New cursor position (clamped to valid range)
    mutating func updateCursorPosition(_ position: Int) {
        cursorPosition = max(0, min(position, hiraganaTarget.count))
    }

    /// Sets the hiragana target and buffer (used during rebuild)
    /// - Parameters:
    ///   - hiragana: New hiragana string
    ///   - buffer: New Cyrillic buffer
    mutating func setHiragana(_ hiragana: String, buffer: String) {
        self.hiraganaTarget = hiragana
        self.cyrillicBuffer = buffer
        self.cursorPosition = hiragana.count
    }

    // MARK: - Query Methods

    /// Gets the convertible target (hiragana for kanji conversion)
    var convertTarget: String {
        return hiraganaTarget
    }

    /// Gets the text before cursor
    var textBeforeCursor: String {
        guard cursorPosition > 0, cursorPosition <= hiraganaTarget.count else {
            return ""
        }
        let index = hiraganaTarget.index(hiraganaTarget.startIndex, offsetBy: cursorPosition)
        return String(hiraganaTarget[..<index])
    }

    /// Gets the text after cursor
    var textAfterCursor: String {
        guard cursorPosition < hiraganaTarget.count else {
            return ""
        }
        let index = hiraganaTarget.index(hiraganaTarget.startIndex, offsetBy: cursorPosition)
        return String(hiraganaTarget[index...])
    }
}

// MARK: - Equatable

extension CyrillicComposingText: Equatable {
    static func == (lhs: CyrillicComposingText, rhs: CyrillicComposingText) -> Bool {
        return lhs.cyrillicKeys == rhs.cyrillicKeys &&
               lhs.cyrillicBuffer == rhs.cyrillicBuffer &&
               lhs.hiraganaTarget == rhs.hiraganaTarget &&
               lhs.cursorPosition == rhs.cursorPosition
    }
}

// MARK: - CustomStringConvertible

extension CyrillicComposingText: CustomStringConvertible {
    var description: String {
        return "CyrillicComposingText(keys: \(cyrillicKeys), hiragana: '\(hiraganaTarget)')"
    }
}
