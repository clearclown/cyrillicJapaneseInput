//
//  ClauseSegmenter.swift
//  CyrillicKeyboard
//
//  Segments hiragana text into grammatical clauses
//  Uses Natural Language Framework for Japanese tokenization
//

import Foundation
import NaturalLanguage

// MARK: - Clause Model

/// Represents a grammatical clause
struct Clause: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// Clause text (hiragana)
    let text: String

    /// Clause type
    let type: ClauseType

    /// Conversion candidates for this clause
    var candidates: [String]

    /// Currently selected candidate index
    var selectedIndex: Int

    // MARK: - Initialization

    init(id: UUID = UUID(),
         text: String,
         type: ClauseType,
         candidates: [String] = [],
         selectedIndex: Int = 0) {
        self.id = id
        self.text = text
        self.type = type
        self.candidates = candidates.isEmpty ? [text] : candidates
        self.selectedIndex = selectedIndex
    }

    // MARK: - Computed Properties

    /// Currently selected candidate
    var selectedCandidate: String {
        guard !candidates.isEmpty, selectedIndex < candidates.count else {
            return text
        }
        return candidates[selectedIndex]
    }

    /// Cycles to next candidate
    mutating func selectNext() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % candidates.count
    }

    /// Cycles to previous candidate
    mutating func selectPrevious() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + candidates.count) % candidates.count
    }
}

// MARK: - Clause Type

/// Type of grammatical clause
enum ClauseType: String, Codable {
    case word           // Content word (noun, verb, adjective)
    case particle       // Particle (は, が, を, に, etc.)
    case auxiliary      // Auxiliary verb (です, ます, だ, etc.)
    case punctuation    // Punctuation
    case unknown        // Unknown/other
}

// MARK: - Clause Segmenter

/// Segments hiragana into grammatical clauses
final class ClauseSegmenter {
    // MARK: - Properties

    /// Natural Language tagger for Japanese
    private let tagger: NLTagger

    /// Particle list
    private let particles: Set<String> = [
        "は", "が", "を", "に", "で", "と", "から", "まで", "へ", "の",
        "も", "や", "か", "など", "ばかり", "だけ", "ほど", "くらい",
        "って", "てん", "とか", "なんて", "なんか"
    ]

    /// Auxiliary verb list
    private let auxiliaries: Set<String> = [
        "です", "でした", "だ", "である", "じゃ", "じゃない",
        "ます", "ました", "ません", "ませんでした",
        "たい", "たかった", "たくない"
    ]

    // MARK: - Initialization

    init() {
        self.tagger = NLTagger(tagSchemes: [.lexicalClass, .language])
    }

    // MARK: - Segmentation

    /// Segments hiragana into clauses
    /// - Parameter hiragana: Input hiragana text
    /// - Returns: Array of clauses
    func segment(_ hiragana: String) -> [Clause] {
        guard !hiragana.isEmpty else { return [] }

        // Set tagger string
        tagger.string = hiragana

        var clauses: [Clause] = []
        var currentClause = ""
        var currentType: ClauseType = .word

        // Enumerate tokens
        tagger.enumerateTags(
            in: hiragana.startIndex..<hiragana.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace]
        ) { tag, range in
            let word = String(hiragana[range])

            // Determine clause type
            let type = self.determineClauseType(word: word, tag: tag)

            // Particle or auxiliary creates boundary
            if type == .particle || type == .auxiliary {
                // Flush current clause if any
                if !currentClause.isEmpty {
                    clauses.append(Clause(
                        text: currentClause,
                        type: currentType
                    ))
                    currentClause = ""
                }

                // Add particle/auxiliary as separate clause
                clauses.append(Clause(
                    text: word,
                    type: type
                ))
            } else {
                // Accumulate into current clause
                if currentType != type && !currentClause.isEmpty {
                    // Type change: flush and start new
                    clauses.append(Clause(
                        text: currentClause,
                        type: currentType
                    ))
                    currentClause = word
                    currentType = type
                } else {
                    currentClause += word
                    currentType = type
                }
            }

            return true
        }

        // Add remaining clause
        if !currentClause.isEmpty {
            clauses.append(Clause(
                text: currentClause,
                type: currentType
            ))
        }

        // If no clauses were created (NL tagger failed), return whole string
        if clauses.isEmpty {
            clauses.append(Clause(
                text: hiragana,
                type: .word
            ))
        }

        return clauses
    }

    // MARK: - Type Determination

    /// Determines clause type from word and NL tag
    private func determineClauseType(word: String, tag: NLTag?) -> ClauseType {
        // Check explicit lists first
        if particles.contains(word) {
            return .particle
        }

        if auxiliaries.contains(word) {
            return .auxiliary
        }

        // Check for auxiliary verb endings
        if word.hasSuffix("です") || word.hasSuffix("ます") ||
           word.hasSuffix("でした") || word.hasSuffix("ました") {
            return .auxiliary
        }

        // Use NL tag
        guard let tag = tag else { return .word }

        switch tag {
        case .particle:
            return .particle
        case .determiner, .classifier:
            return .auxiliary
        case .punctuation:
            return .punctuation
        default:
            return .word
        }
    }

    // MARK: - Advanced Segmentation

    /// Segments with lookahead for better accuracy
    /// - Parameter hiragana: Input hiragana text
    /// - Returns: Array of clauses with optimized boundaries
    func segmentWithLookahead(_ hiragana: String) -> [Clause] {
        // Basic segmentation first
        let clauses = segment(hiragana)

        // Merge short adjacent word clauses
        var merged: [Clause] = []
        var i = 0

        while i < clauses.count {
            var current = clauses[i]

            // Look ahead for mergeable clauses
            if i + 1 < clauses.count {
                let next = clauses[i + 1]

                // Merge if both are short words
                if current.type == .word && next.type == .word &&
                   current.text.count <= 2 && next.text.count <= 2 {
                    current = Clause(
                        text: current.text + next.text,
                        type: .word
                    )
                    i += 1 // Skip next
                }
            }

            merged.append(current)
            i += 1
        }

        return merged
    }
}
