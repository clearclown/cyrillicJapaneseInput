//
//  Candidate.swift
//  Shared
//
//  Represents a conversion candidate (for Phase 2: Kanji conversion)
//

import Foundation

/// Represents a kanji conversion candidate
struct Candidate: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// The candidate text (e.g., "会社", "開車")
    let text: String

    /// Reading in hiragana (e.g., "かいしゃ")
    let reading: String

    /// Conversion score (higher is better)
    let score: Double

    /// Whether this is a learned/user-defined word
    let isLearned: Bool

    /// Part of speech tag (optional)
    let partOfSpeech: String?

    // MARK: - Initialization

    init(id: UUID = UUID(),
         text: String,
         reading: String,
         score: Double = 0.0,
         isLearned: Bool = false,
         partOfSpeech: String? = nil) {
        self.id = id
        self.text = text
        self.reading = reading
        self.score = score
        self.isLearned = isLearned
        self.partOfSpeech = partOfSpeech
    }
}

// MARK: - Comparable

extension Candidate: Comparable {
    static func < (lhs: Candidate, rhs: Candidate) -> Bool {
        // Higher score comes first
        return lhs.score > rhs.score
    }
}
