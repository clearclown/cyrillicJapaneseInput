//
//  DisplayedTextManager.swift
//  CyrillicKeyboard
//
//  Manages text display in the text field using iOS standard IME protocols
//  Based on azooKey's DisplayedTextManager pattern
//

import UIKit

/// Manages the display of composing and committed text using UITextDocumentProxy
final class DisplayedTextManager {
    // MARK: - Properties

    /// Reference to the text document proxy
    private weak var proxy: UITextDocumentProxy?

    /// Current composing text (hiragana)
    private(set) var composingText: String = ""

    /// Live conversion result (kanji/katakana) - what's actually displayed
    private(set) var displayedLiveConversionText: String?

    /// Whether to use iOS standard marked text API
    private let isMarkedTextEnabled: Bool

    /// Cursor position within composing text
    private var cursorPosition: Int = 0

    // MARK: - Initialization

    init(isMarkedTextEnabled: Bool = true) {
        self.isMarkedTextEnabled = isMarkedTextEnabled
    }

    // MARK: - Proxy Management

    func setTextDocumentProxy(_ proxy: UITextDocumentProxy) {
        self.proxy = proxy
    }

    // MARK: - Composing Text Management

    /// Updates the composing (unmarked) text in the text field
    /// - Parameters:
    ///   - composingText: The base composing text (hiragana)
    ///   - liveConversionText: Optional converted text (kanji) to display instead
    func updateComposingText(_ composingText: String, liveConversionText: String? = nil) {
        guard let proxy = proxy else {
            print("[DisplayedTextManager] Warning: No text document proxy set")
            return
        }

        self.composingText = composingText
        self.displayedLiveConversionText = liveConversionText

        if composingText.isEmpty && liveConversionText == nil {
            // Nothing to display - clear marked text
            proxy.unmarkText()
            return
        }

        // Determine what to display (live conversion takes precedence)
        let displayText = liveConversionText ?? composingText

        if isMarkedTextEnabled {
            // iOS standard: Use setMarkedText for composing text (underlined)
            let range = NSRange(location: displayText.count, length: 0)
            proxy.setMarkedText(displayText, selectedRange: range)

            print("[DisplayedTextManager] Set marked text: '\(displayText)'")
        } else {
            // Fallback: Manual text manipulation (for apps that don't support marked text)
            updateViaDirectManipulation(displayText)
        }
    }

    /// Stops composition and clears marked text
    func stopComposition() {
        guard let proxy = proxy else { return }

        proxy.unmarkText()
        composingText = ""
        displayedLiveConversionText = nil
        cursorPosition = 0

        print("[DisplayedTextManager] Stopped composition")
    }

    // MARK: - Text Insertion

    /// Inserts committed text (removes marked text and inserts final text)
    /// - Parameter text: The text to commit and insert
    func insertText(_ text: String) {
        guard let proxy = proxy else { return }

        // Clear any marked text first
        proxy.unmarkText()

        // Insert the committed text
        proxy.insertText(text)

        // Clear internal state
        composingText = ""
        displayedLiveConversionText = nil
        cursorPosition = 0

        print("[DisplayedTextManager] Inserted committed text: '\(text)'")
    }

    // MARK: - Deletion

    /// Deletes characters backward
    /// - Parameter count: Number of characters to delete
    func deleteBackward(count: Int = 1) {
        guard let proxy = proxy else { return }

        for _ in 0..<count {
            proxy.deleteBackward()
        }

        print("[DisplayedTextManager] Deleted \(count) character(s) backward")
    }

    // MARK: - Cursor Management

    /// Updates cursor position within composing text
    /// - Parameter position: New cursor position
    func updateCursorPosition(_ position: Int) {
        guard let proxy = proxy else { return }

        cursorPosition = max(0, min(position, composingText.count))

        // Update marked text with new cursor position
        if isMarkedTextEnabled, !composingText.isEmpty {
            let displayText = displayedLiveConversionText ?? composingText
            let range = NSRange(location: cursorPosition, length: 0)
            proxy.setMarkedText(displayText, selectedRange: range)
        }
    }

    // MARK: - Context Information

    /// Gets the text before the cursor
    var documentContextBeforeInput: String? {
        return proxy?.documentContextBeforeInput
    }

    /// Gets the text after the cursor
    var documentContextAfterInput: String? {
        return proxy?.documentContextAfterInput
    }

    // MARK: - Private Helpers

    /// Fallback method for apps that don't support marked text
    /// Updates text by deleting old composing text and inserting new
    private func updateViaDirectManipulation(_ newText: String) {
        guard let proxy = proxy else { return }

        // Delete old composing text
        if !composingText.isEmpty {
            for _ in 0..<composingText.count {
                proxy.deleteBackward()
            }
        }

        // Insert new text
        proxy.insertText(newText)

        print("[DisplayedTextManager] Updated via direct manipulation: '\(newText)'")
    }
}

// MARK: - Debug Extension

#if DEBUG
extension DisplayedTextManager {
    var debugDescription: String {
        return """
        DisplayedTextManager:
          composingText: '\(composingText)'
          liveConversion: '\(displayedLiveConversionText ?? "nil")'
          cursorPosition: \(cursorPosition)
          isMarkedTextEnabled: \(isMarkedTextEnabled)
        """
    }
}
#endif
