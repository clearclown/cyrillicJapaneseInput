//
//  DictionaryEntry.swift
//  CyrillicKeyboard
//
//  Dictionary entry with part-of-speech and costs
//  Based on azooKey's statistical kana-kanji conversion architecture
//

import Foundation

/// Part of speech (品詞) for Japanese grammar
enum PartOfSpeech: String, Codable {
    // Nouns (名詞)
    case noun = "名詞"
    case properNoun = "固有名詞"

    // Verbs (動詞)
    case verb = "動詞"
    case verbGodan = "五段動詞"
    case verbIchidan = "一段動詞"
    case verbIrregular = "不規則動詞"

    // Verb forms
    case verbStemForm = "動詞連用形"      // て-form stem
    case verbBaseForm = "動詞終止形"      // dictionary form
    case verbConditionalForm = "動詞仮定形"

    // Adjectives (形容詞)
    case iAdjective = "イ形容詞"
    case naAdjective = "ナ形容詞"

    // Particles (助詞)
    case particle = "助詞"
    case caseParticle = "格助詞"         // が、を、に、で、と
    case topicParticle = "係助詞"        // は、も

    // Auxiliary verbs (助動詞)
    case auxiliary = "助動詞"

    // Others
    case adverb = "副詞"
    case conjunction = "接続詞"
    case interjection = "感動詞"
    case prefix = "接頭辞"
    case suffix = "接尾辞"
    case symbol = "記号"

    // Special (for katakana, hiragana)
    case katakana = "カタカナ"
    case hiragana = "ひらがな"
    case unknown = "未知語"
}

/// Dictionary entry with statistical information
struct DictionaryEntry: Codable, Hashable {
    /// Reading in hiragana (読み)
    let reading: String

    /// Surface form - kanji or kana output (単語)
    let surface: String

    /// Part of speech (品詞)
    let partOfSpeech: PartOfSpeech

    /// Word cost - lower is more frequent (単語コスト)
    /// Based on corpus frequency: -log(P(word))
    /// Range: 0-10000, typical values 500-5000
    let wordCost: Int

    /// Optional user frequency for learning
    var userFrequency: Int = 0

    init(reading: String, surface: String, partOfSpeech: PartOfSpeech, wordCost: Int) {
        self.reading = reading
        self.surface = surface
        self.partOfSpeech = partOfSpeech
        self.wordCost = wordCost
        self.userFrequency = 0
    }

    /// Final cost including learning boost
    var finalCost: Int {
        // Learning reduces cost (makes word more likely)
        // Each use reduces cost by 50, max reduction 500
        let learningBoost = min(500, userFrequency * 50)
        return max(0, wordCost - learningBoost)
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension DictionaryEntry {
    static let examples = [
        DictionaryEntry(reading: "さる", surface: "去る", partOfSpeech: .verbGodan, wordCost: 800),
        DictionaryEntry(reading: "さる", surface: "猿", partOfSpeech: .noun, wordCost: 1000),
        DictionaryEntry(reading: "が", surface: "が", partOfSpeech: .caseParticle, wordCost: 100),
        DictionaryEntry(reading: "いる", surface: "居る", partOfSpeech: .verbIchidan, wordCost: 500),
        DictionaryEntry(reading: "かい", surface: "会", partOfSpeech: .noun, wordCost: 600),
        DictionaryEntry(reading: "かい", surface: "買", partOfSpeech: .noun, wordCost: 800),
        DictionaryEntry(reading: "かいしゃ", surface: "会社", partOfSpeech: .noun, wordCost: 400),
    ]
}
#endif
