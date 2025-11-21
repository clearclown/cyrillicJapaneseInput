//
//  Candidate.swift
//  Shared
//
//  Represents a conversion candidate for Japanese input
//

import Foundation

/// Type of candidate
public enum CandidateType: String, Codable {
    case kanji          // 漢字変換候補
    case hiragana       // ひらがな
    case katakana       // カタカナ
    case userDictionary // ユーザー辞書
}

/// Metadata for a candidate
public struct CandidateMetadata: Codable {
    /// Reading (yomi) for kanji candidates
    public let reading: String?

    /// Part of speech (品詞)
    public let partOfSpeech: String?

    /// Frequency score (higher = more common)
    public let frequency: Int?

    public init(reading: String? = nil, partOfSpeech: String? = nil, frequency: Int? = nil) {
        self.reading = reading
        self.partOfSpeech = partOfSpeech
        self.frequency = frequency
    }
}

/// Represents a conversion candidate
public struct Candidate: Codable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Display text (e.g., "会社", "かいしゃ", "カイシャ")
    public let text: String

    /// Type of candidate
    public let type: CandidateType

    /// Optional metadata
    public let metadata: CandidateMetadata?

    /// Rank/score for sorting
    public let rank: Int

    public init(
        id: UUID = UUID(),
        text: String,
        type: CandidateType,
        metadata: CandidateMetadata? = nil,
        rank: Int = 0
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.metadata = metadata
        self.rank = rank
    }
}

// MARK: - Convenience Initializers

extension Candidate {
    /// Creates a simple hiragana candidate
    public static func hiragana(_ text: String, rank: Int = 0) -> Candidate {
        return Candidate(text: text, type: .hiragana, rank: rank)
    }

    /// Creates a simple katakana candidate
    public static func katakana(_ text: String, rank: Int = 0) -> Candidate {
        return Candidate(text: text, type: .katakana, rank: rank)
    }

    /// Creates a kanji candidate with reading
    public static func kanji(_ text: String, reading: String?, partOfSpeech: String? = nil, rank: Int = 0) -> Candidate {
        let metadata = CandidateMetadata(reading: reading, partOfSpeech: partOfSpeech)
        return Candidate(text: text, type: .kanji, metadata: metadata, rank: rank)
    }
}
