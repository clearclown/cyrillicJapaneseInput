//
//  KanjiConversionEngine.swift
//  CyrillicKeyboard
//
//  Phase 2: Hiragana → Kanji conversion engine
//  Provides protocol-based design for future integration with full dictionary (e.g., azooKey)
//

import Foundation

// MARK: - Conversion Errors

/// Errors that can occur during conversion
enum ConversionError: Error {
    case dictionaryNotFound
    case invalidInput
    case conversionFailed(String)
    case engineNotInitialized
}

// MARK: - Candidate Models

/// Represents a conversion candidate
struct Candidate: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// Display text (e.g., "会社")
    let text: String

    /// Candidate type
    let type: CandidateType

    /// Priority score (higher = more priority)
    let score: Double

    /// Additional metadata
    let metadata: CandidateMetadata?

    init(id: UUID = UUID(), text: String, type: CandidateType, score: Double, metadata: CandidateMetadata? = nil) {
        self.id = id
        self.text = text
        self.type = type
        self.score = score
        self.metadata = metadata
    }
}

/// Candidate type classification
enum CandidateType: String, Codable {
    case kanji          // Kanji conversion
    case hiragana       // Hiragana as-is
    case katakana       // Katakana
    case userDictionary // User learning dictionary
    case emoji          // Emoji (future)
}

/// Candidate metadata
struct CandidateMetadata: Equatable {
    /// Part of speech (品詞)
    let partOfSpeech: String?

    /// Frequency rank
    let frequency: Int?

    /// Source dictionary
    let source: String?
}

// MARK: - Conversion Options

/// Options for conversion behavior
struct ConversionOptions {
    /// Maximum number of candidates to return
    var maxCandidateCount: Int

    /// Include katakana candidates
    var includeKatakana: Bool

    /// Include hiragana candidates
    var includeHiragana: Bool

    /// Prioritize user dictionary
    var prioritizeUserDictionary: Bool

    static let `default` = ConversionOptions(
        maxCandidateCount: 10,
        includeKatakana: true,
        includeHiragana: true,
        prioritizeUserDictionary: true
    )
}

// MARK: - Conversion Engine Protocol

/// Protocol for hiragana → kanji conversion engines
/// Allows swapping implementations (mock, azooKey, etc.)
protocol KanjiConverterProtocol {
    /// Requests conversion candidates for hiragana input
    /// - Parameters:
    ///   - hiragana: Input hiragana string
    ///   - maxCount: Maximum number of candidates
    /// - Returns: Array of conversion candidates
    /// - Throws: ConversionError on failure
    func requestCandidates(for hiragana: String, maxCount: Int) async throws -> [Candidate]

    /// Learns from user selection
    /// - Parameters:
    ///   - input: Input hiragana
    ///   - selected: User's selected candidate
    func learn(input: String, selected: Candidate)

    /// Clears all learning data
    func clearLearningData()
}

// MARK: - Main Conversion Engine

/// Main conversion engine that orchestrates user dictionary and system dictionary
final class KanjiConversionEngine: KanjiConverterProtocol {
    // MARK: - Properties

    /// User dictionary for learning
    private let userDictionary: UserDictionary

    /// System dictionary (mock implementation for Phase 2)
    private let systemDictionary: SystemDictionary

    /// Conversion options
    private var options: ConversionOptions

    // MARK: - Initialization

    init(options: ConversionOptions = .default) throws {
        self.options = options
        self.userDictionary = UserDictionary()
        self.systemDictionary = SystemDictionary()

        print("[KanjiConversionEngine] Initialized with mock system dictionary")
    }

    // MARK: - Conversion

    func requestCandidates(for hiragana: String, maxCount: Int = 10) async throws -> [Candidate] {
        guard !hiragana.isEmpty else {
            throw ConversionError.invalidInput
        }

        print("[KanjiConversionEngine] Requesting candidates for: '\(hiragana)'")

        var candidates: [Candidate] = []

        // 1. User dictionary (highest priority)
        if options.prioritizeUserDictionary {
            let userCandidates = userDictionary.lookup(hiragana)
            candidates.append(contentsOf: userCandidates)
        }

        // 2. System dictionary
        let systemCandidates = systemDictionary.lookup(hiragana)
        candidates.append(contentsOf: systemCandidates)

        // 3. Hiragana as-is
        if options.includeHiragana {
            candidates.append(Candidate(
                text: hiragana,
                type: .hiragana,
                score: 0.1,
                metadata: CandidateMetadata(partOfSpeech: nil, frequency: nil, source: "hiragana")
            ))
        }

        // 4. Katakana
        if options.includeKatakana, let katakana = convertToKatakana(hiragana) {
            candidates.append(Candidate(
                text: katakana,
                type: .katakana,
                score: 0.05,
                metadata: CandidateMetadata(partOfSpeech: nil, frequency: nil, source: "katakana")
            ))
        }

        // Sort by score (descending)
        candidates.sort { $0.score > $1.score }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        candidates = candidates.filter { candidate in
            if seen.contains(candidate.text) {
                return false
            }
            seen.insert(candidate.text)
            return true
        }

        // Limit count
        let limited = Array(candidates.prefix(maxCount))

        print("[KanjiConversionEngine] Returned \(limited.count) candidates: \(limited.map { $0.text })")
        return limited
    }

    func learn(input: String, selected: Candidate) {
        userDictionary.add(input: input, output: selected.text)
        print("[KanjiConversionEngine] Learned: '\(input)' → '\(selected.text)'")
    }

    func clearLearningData() {
        userDictionary.clear()
        print("[KanjiConversionEngine] Cleared learning data")
    }

    // MARK: - Utility

    private func convertToKatakana(_ hiragana: String) -> String? {
        let mutableString = NSMutableString(string: hiragana)
        if CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, false) {
            return mutableString as String
        }
        return nil
    }
}

// MARK: - System Dictionary (Mock Implementation)

/// Mock system dictionary for Phase 2
/// In Phase 3, this can be replaced with azooKey or other full dictionary
final class SystemDictionary {
    // Mock dictionary: Hiragana → [Kanji candidates]
    // This is a VERY simplified dictionary for demonstration
    private let dictionary: [String: [(kanji: String, score: Double)]] = [
        // Common words
        "かいしゃ": [("会社", 1.0), ("開車", 0.5), ("快謝", 0.3)],
        "がっこう": [("学校", 1.0), ("学行", 0.3)],
        "せんせい": [("先生", 1.0), ("千生", 0.2)],
        "がくせい": [("学生", 1.0)],
        "にほん": [("日本", 1.0), ("二本", 0.3)],
        "にっぽん": [("日本", 1.0)],
        "ともだち": [("友達", 1.0)],
        "かぞく": [("家族", 1.0)],
        "しごと": [("仕事", 1.0), ("私事", 0.3)],
        "でんわ": [("電話", 1.0)],
        "めーる": [("メール", 1.0), ("メイル", 0.5)],

        // Particles
        "は": [("は", 1.0)],
        "を": [("を", 1.0)],
        "に": [("に", 1.0)],
        "が": [("が", 1.0)],
        "の": [("の", 1.0)],
        "と": [("と", 1.0)],
        "へ": [("へ", 1.0)],

        // Common verbs
        "いく": [("行く", 1.0), ("逝く", 0.2)],
        "くる": [("来る", 1.0)],
        "する": [("する", 1.0)],
        "みる": [("見る", 1.0), ("観る", 0.5), ("診る", 0.3)],
        "きく": [("聞く", 1.0), ("聴く", 0.5)],
        "たべる": [("食べる", 1.0)],
        "のむ": [("飲む", 1.0)],
        "よむ": [("読む", 1.0)],
        "かく": [("書く", 1.0)],

        // Common adjectives
        "おおきい": [("大きい", 1.0)],
        "ちいさい": [("小さい", 1.0)],
        "あたらしい": [("新しい", 1.0)],
        "ふるい": [("古い", 1.0)],
        "たかい": [("高い", 1.0), ("多い", 0.3)],
        "やすい": [("安い", 1.0), ("易しい", 0.5)],

        // Numbers
        "いち": [("一", 1.0), ("１", 0.5)],
        "に": [("二", 1.0), ("２", 0.5)],
        "さん": [("三", 1.0), ("３", 0.5)],
        "よん": [("四", 1.0), ("４", 0.5)],
        "ご": [("五", 1.0), ("５", 0.5)],

        // Greetings
        "おはよう": [("おはよう", 1.0)],
        "こんにちは": [("こんにちは", 1.0), ("今日は", 0.3)],
        "こんばんは": [("こんばんは", 1.0), ("今晩は", 0.3)],
        "ありがとう": [("ありがとう", 1.0), ("有難う", 0.5)],
        "さようなら": [("さようなら", 1.0), ("左様なら", 0.2)],
    ]

    func lookup(_ hiragana: String) -> [Candidate] {
        guard let entries = dictionary[hiragana] else {
            return []
        }

        return entries.map { entry in
            Candidate(
                text: entry.kanji,
                type: .kanji,
                score: entry.score,
                metadata: CandidateMetadata(
                    partOfSpeech: nil,
                    frequency: nil,
                    source: "system"
                )
            )
        }
    }
}
