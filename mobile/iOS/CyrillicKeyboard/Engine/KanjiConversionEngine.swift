//
//  KanjiConversionEngine.swift
//  CyrillicKeyboard
//
//  Viterbi-based kana-kanji conversion engine
//  Based on azooKey's statistical conversion architecture
//

import Foundation

/// Protocol for kanji conversion engines
protocol KanjiConversionEngineProtocol {
    /// Requests conversion candidates for hiragana input
    /// - Parameters:
    ///   - hiragana: Hiragana string to convert
    ///   - maxCount: Maximum number of candidates
    /// - Returns: Array of candidates sorted by score
    func requestCandidates(for hiragana: String, maxCount: Int) async throws -> [Candidate]

    /// Records user selection for learning
    /// - Parameters:
    ///   - hiragana: Original hiragana input
    ///   - selected: Selected candidate text
    func learn(_ hiragana: String, selected: String)

    /// Clears learning data
    func clearLearningData()
}

/// Viterbi-based kanji conversion engine
/// Implementation based on azooKey's statistical conversion architecture
final class KanjiConversionEngine: KanjiConversionEngineProtocol {
    // MARK: - Properties

    /// Shared instance
    static let shared = KanjiConversionEngine()

    /// Viterbi converter for statistical conversion
    private var viterbiConverter: ViterbiConverter!

    /// Learning data: hiragana → selected text → frequency
    private var learningData: [String: [String: Int]] = [:]

    // MARK: - Initialization

    init() {
        loadEnhancedDictionary()
        loadLearningData()
    }

    // MARK: - Conversion

    func requestCandidates(for hiragana: String, maxCount: Int) async throws -> [Candidate] {
        // Simulate async processing
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        var candidates: [Candidate] = []

        // 1. Use Viterbi converter for kanji conversion
        let viterbiResults = viterbiConverter.convert(hiragana, maxCandidates: maxCount)
        for (index, surface) in viterbiResults.enumerated() {
            let baseScore = 1.0 - (Double(index) * 0.1)
            let learningBoost = learningScore(for: hiragana, candidate: surface)
            let finalScore = baseScore + learningBoost

            candidates.append(Candidate(
                text: surface,
                reading: hiragana,
                score: finalScore,
                isLearned: learningBoost > 0,
                partOfSpeech: "mixed"
            ))
        }

        // 2. Add katakana candidate
        if let katakana = convertToKatakana(hiragana) {
            candidates.append(Candidate(
                text: katakana,
                reading: hiragana,
                score: 0.5,
                isLearned: false,
                partOfSpeech: "katakana"
            ))
        }

        // 3. Add hiragana itself
        candidates.append(Candidate(
            text: hiragana,
            reading: hiragana,
            score: 0.3,
            isLearned: false,
            partOfSpeech: "hiragana"
        ))

        // 4. Sort by score and limit
        candidates.sort()
        return Array(candidates.prefix(maxCount))
    }

    func learn(_ hiragana: String, selected: String) {
        if learningData[hiragana] == nil {
            learningData[hiragana] = [:]
        }
        learningData[hiragana]?[selected, default: 0] += 1

        saveLearningData()
        print("[KanjiConversionEngine] Learned: '\(hiragana)' → '\(selected)'")
    }

    func clearLearningData() {
        learningData.removeAll()
        saveLearningData()
        print("[KanjiConversionEngine] Learning data cleared")
    }

    // MARK: - Private Methods

    private func learningScore(for hiragana: String, candidate: String) -> Double {
        guard let frequencies = learningData[hiragana],
              let frequency = frequencies[candidate] else {
            return 0.0
        }

        // Learning boost: up to +0.5
        return min(0.5, Double(frequency) * 0.1)
    }

    private func convertToKatakana(_ hiragana: String) -> String? {
        let mutableString = NSMutableString(string: hiragana)
        if CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, false) {
            return mutableString as String
        }
        return nil
    }

    // MARK: - Enhanced Dictionary with POS Data

    private func loadEnhancedDictionary() {
        var dictionary: [String: [DictionaryEntry]] = [:]

        // か行
        dictionary["かい"] = [
            DictionaryEntry(reading: "かい", surface: "会", partOfSpeech: .noun, wordCost: 600),
            DictionaryEntry(reading: "かい", surface: "開", partOfSpeech: .noun, wordCost: 800),
            DictionaryEntry(reading: "かい", surface: "買", partOfSpeech: .noun, wordCost: 900),
            DictionaryEntry(reading: "かい", surface: "快", partOfSpeech: .naAdjective, wordCost: 1200),
            DictionaryEntry(reading: "かい", surface: "貝", partOfSpeech: .noun, wordCost: 1500),
        ]
        dictionary["かいしゃ"] = [
            DictionaryEntry(reading: "かいしゃ", surface: "会社", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["かく"] = [
            DictionaryEntry(reading: "かく", surface: "書く", partOfSpeech: .verbGodan, wordCost: 500),
            DictionaryEntry(reading: "かく", surface: "描く", partOfSpeech: .verbGodan, wordCost: 800),
            DictionaryEntry(reading: "かく", surface: "角", partOfSpeech: .noun, wordCost: 1000),
        ]
        dictionary["かみ"] = [
            DictionaryEntry(reading: "かみ", surface: "紙", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "かみ", surface: "神", partOfSpeech: .noun, wordCost: 600),
            DictionaryEntry(reading: "かみ", surface: "髪", partOfSpeech: .noun, wordCost: 700),
        ]
        dictionary["かわ"] = [
            DictionaryEntry(reading: "かわ", surface: "川", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "かわ", surface: "河", partOfSpeech: .noun, wordCost: 800),
            DictionaryEntry(reading: "かわ", surface: "皮", partOfSpeech: .noun, wordCost: 900),
            DictionaryEntry(reading: "かわ", surface: "革", partOfSpeech: .noun, wordCost: 1000),
        ]

        // さ行
        dictionary["さくら"] = [
            DictionaryEntry(reading: "さくら", surface: "桜", partOfSpeech: .noun, wordCost: 600),
            DictionaryEntry(reading: "さくら", surface: "さくら", partOfSpeech: .hiragana, wordCost: 1500),
        ]
        dictionary["せんせい"] = [
            DictionaryEntry(reading: "せんせい", surface: "先生", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["そら"] = [
            DictionaryEntry(reading: "そら", surface: "空", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "そら", surface: "そら", partOfSpeech: .hiragana, wordCost: 1500),
        ]

        // た行
        dictionary["たべる"] = [
            DictionaryEntry(reading: "たべる", surface: "食べる", partOfSpeech: .verbIchidan, wordCost: 400),
        ]
        dictionary["つくる"] = [
            DictionaryEntry(reading: "つくる", surface: "作る", partOfSpeech: .verbGodan, wordCost: 500),
            DictionaryEntry(reading: "つくる", surface: "創る", partOfSpeech: .verbGodan, wordCost: 1000),
            DictionaryEntry(reading: "つくる", surface: "造る", partOfSpeech: .verbGodan, wordCost: 1200),
        ]
        dictionary["てんき"] = [
            DictionaryEntry(reading: "てんき", surface: "天気", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "てんき", surface: "電気", partOfSpeech: .noun, wordCost: 600),
        ]

        // な行
        dictionary["なまえ"] = [
            DictionaryEntry(reading: "なまえ", surface: "名前", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["にほん"] = [
            DictionaryEntry(reading: "にほん", surface: "日本", partOfSpeech: .properNoun, wordCost: 300),
        ]

        // は行
        dictionary["はな"] = [
            DictionaryEntry(reading: "はな", surface: "花", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "はな", surface: "鼻", partOfSpeech: .noun, wordCost: 700),
            DictionaryEntry(reading: "はな", surface: "話", partOfSpeech: .noun, wordCost: 800),
        ]
        dictionary["ふゆ"] = [
            DictionaryEntry(reading: "ふゆ", surface: "冬", partOfSpeech: .noun, wordCost: 500),
        ]

        // ま行
        dictionary["まち"] = [
            DictionaryEntry(reading: "まち", surface: "町", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "まち", surface: "街", partOfSpeech: .noun, wordCost: 600),
            DictionaryEntry(reading: "まち", surface: "待ち", partOfSpeech: .noun, wordCost: 800),
        ]
        dictionary["みる"] = [
            DictionaryEntry(reading: "みる", surface: "見る", partOfSpeech: .verbIchidan, wordCost: 400),
            DictionaryEntry(reading: "みる", surface: "観る", partOfSpeech: .verbIchidan, wordCost: 800),
            DictionaryEntry(reading: "みる", surface: "診る", partOfSpeech: .verbIchidan, wordCost: 1000),
        ]

        // や行
        dictionary["やま"] = [
            DictionaryEntry(reading: "やま", surface: "山", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["ゆき"] = [
            DictionaryEntry(reading: "ゆき", surface: "雪", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "ゆき", surface: "行き", partOfSpeech: .noun, wordCost: 800),
        ]

        // ら行
        dictionary["りんご"] = [
            DictionaryEntry(reading: "りんご", surface: "林檎", partOfSpeech: .noun, wordCost: 800),
            DictionaryEntry(reading: "りんご", surface: "りんご", partOfSpeech: .hiragana, wordCost: 600),
        ]

        // わ行
        dictionary["わたし"] = [
            DictionaryEntry(reading: "わたし", surface: "私", partOfSpeech: .noun, wordCost: 300),
            DictionaryEntry(reading: "わたし", surface: "渡し", partOfSpeech: .noun, wordCost: 1200),
        ]

        // Common particles and auxiliary verbs
        dictionary["が"] = [
            DictionaryEntry(reading: "が", surface: "が", partOfSpeech: .caseParticle, wordCost: 100),
        ]
        dictionary["は"] = [
            DictionaryEntry(reading: "は", surface: "は", partOfSpeech: .topicParticle, wordCost: 100),
        ]
        dictionary["を"] = [
            DictionaryEntry(reading: "を", surface: "を", partOfSpeech: .caseParticle, wordCost: 100),
        ]
        dictionary["に"] = [
            DictionaryEntry(reading: "に", surface: "に", partOfSpeech: .caseParticle, wordCost: 100),
        ]
        dictionary["で"] = [
            DictionaryEntry(reading: "で", surface: "で", partOfSpeech: .caseParticle, wordCost: 100),
        ]
        dictionary["と"] = [
            DictionaryEntry(reading: "と", surface: "と", partOfSpeech: .caseParticle, wordCost: 100),
        ]
        dictionary["も"] = [
            DictionaryEntry(reading: "も", surface: "も", partOfSpeech: .topicParticle, wordCost: 150),
        ]
        dictionary["の"] = [
            DictionaryEntry(reading: "の", surface: "の", partOfSpeech: .particle, wordCost: 100),
        ]
        dictionary["や"] = [
            DictionaryEntry(reading: "や", surface: "や", partOfSpeech: .particle, wordCost: 200),
        ]
        dictionary["か"] = [
            DictionaryEntry(reading: "か", surface: "か", partOfSpeech: .particle, wordCost: 150),
        ]
        dictionary["ね"] = [
            DictionaryEntry(reading: "ね", surface: "ね", partOfSpeech: .particle, wordCost: 200),
        ]
        dictionary["です"] = [
            DictionaryEntry(reading: "です", surface: "です", partOfSpeech: .auxiliary, wordCost: 200),
        ]

        // Common phrases
        dictionary["きょう"] = [
            DictionaryEntry(reading: "きょう", surface: "今日", partOfSpeech: .noun, wordCost: 400),
            DictionaryEntry(reading: "きょう", surface: "教", partOfSpeech: .noun, wordCost: 1000),
            DictionaryEntry(reading: "きょう", surface: "京", partOfSpeech: .noun, wordCost: 1200),
        ]
        dictionary["きょうは"] = [
            DictionaryEntry(reading: "きょうは", surface: "今日は", partOfSpeech: .noun, wordCost: 300),
        ]
        dictionary["いい"] = [
            DictionaryEntry(reading: "いい", surface: "良い", partOfSpeech: .iAdjective, wordCost: 400),
            DictionaryEntry(reading: "いい", surface: "いい", partOfSpeech: .hiragana, wordCost: 800),
        ]

        // Additional common words
        dictionary["がっこう"] = [
            DictionaryEntry(reading: "がっこう", surface: "学校", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["せんもん"] = [
            DictionaryEntry(reading: "せんもん", surface: "専門", partOfSpeech: .noun, wordCost: 600),
        ]
        dictionary["しごと"] = [
            DictionaryEntry(reading: "しごと", surface: "仕事", partOfSpeech: .noun, wordCost: 400),
            DictionaryEntry(reading: "しごと", surface: "私事", partOfSpeech: .noun, wordCost: 1500),
        ]
        dictionary["ともだち"] = [
            DictionaryEntry(reading: "ともだち", surface: "友達", partOfSpeech: .noun, wordCost: 400),
            DictionaryEntry(reading: "ともだち", surface: "友だち", partOfSpeech: .noun, wordCost: 500),
        ]
        dictionary["でんわ"] = [
            DictionaryEntry(reading: "でんわ", surface: "電話", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["じかん"] = [
            DictionaryEntry(reading: "じかん", surface: "時間", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["ばしょ"] = [
            DictionaryEntry(reading: "ばしょ", surface: "場所", partOfSpeech: .noun, wordCost: 500),
        ]
        dictionary["もの"] = [
            DictionaryEntry(reading: "もの", surface: "物", partOfSpeech: .noun, wordCost: 400),
            DictionaryEntry(reading: "もの", surface: "者", partOfSpeech: .noun, wordCost: 600),
        ]
        dictionary["こと"] = [
            DictionaryEntry(reading: "こと", surface: "事", partOfSpeech: .noun, wordCost: 400),
            DictionaryEntry(reading: "こと", surface: "こと", partOfSpeech: .hiragana, wordCost: 800),
        ]
        dictionary["ひと"] = [
            DictionaryEntry(reading: "ひと", surface: "人", partOfSpeech: .noun, wordCost: 300),
        ]

        // Time expressions
        dictionary["あした"] = [
            DictionaryEntry(reading: "あした", surface: "明日", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["きのう"] = [
            DictionaryEntry(reading: "きのう", surface: "昨日", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["いま"] = [
            DictionaryEntry(reading: "いま", surface: "今", partOfSpeech: .noun, wordCost: 300),
            DictionaryEntry(reading: "いま", surface: "居間", partOfSpeech: .noun, wordCost: 1000),
        ]

        // Location words
        dictionary["ここ"] = [
            DictionaryEntry(reading: "ここ", surface: "ここ", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["そこ"] = [
            DictionaryEntry(reading: "そこ", surface: "そこ", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["あそこ"] = [
            DictionaryEntry(reading: "あそこ", surface: "あそこ", partOfSpeech: .noun, wordCost: 500),
        ]

        // Question words
        dictionary["なに"] = [
            DictionaryEntry(reading: "なに", surface: "何", partOfSpeech: .noun, wordCost: 300),
        ]
        dictionary["だれ"] = [
            DictionaryEntry(reading: "だれ", surface: "誰", partOfSpeech: .noun, wordCost: 400),
        ]
        dictionary["いつ"] = [
            DictionaryEntry(reading: "いつ", surface: "何時", partOfSpeech: .noun, wordCost: 500),
            DictionaryEntry(reading: "いつ", surface: "いつ", partOfSpeech: .hiragana, wordCost: 400),
        ]
        dictionary["どこ"] = [
            DictionaryEntry(reading: "どこ", surface: "何処", partOfSpeech: .noun, wordCost: 800),
            DictionaryEntry(reading: "どこ", surface: "どこ", partOfSpeech: .hiragana, wordCost: 400),
        ]
        dictionary["どう"] = [
            DictionaryEntry(reading: "どう", surface: "如何", partOfSpeech: .adverb, wordCost: 1000),
            DictionaryEntry(reading: "どう", surface: "どう", partOfSpeech: .hiragana, wordCost: 400),
        ]
        dictionary["なぜ"] = [
            DictionaryEntry(reading: "なぜ", surface: "何故", partOfSpeech: .adverb, wordCost: 800),
            DictionaryEntry(reading: "なぜ", surface: "なぜ", partOfSpeech: .hiragana, wordCost: 500),
        ]

        // i-Adjectives
        dictionary["おおきい"] = [
            DictionaryEntry(reading: "おおきい", surface: "大きい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["ちいさい"] = [
            DictionaryEntry(reading: "ちいさい", surface: "小さい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["たかい"] = [
            DictionaryEntry(reading: "たかい", surface: "高い", partOfSpeech: .iAdjective, wordCost: 400),
            DictionaryEntry(reading: "たかい", surface: "多い", partOfSpeech: .iAdjective, wordCost: 1000),
        ]
        dictionary["やすい"] = [
            DictionaryEntry(reading: "やすい", surface: "安い", partOfSpeech: .iAdjective, wordCost: 500),
            DictionaryEntry(reading: "やすい", surface: "易しい", partOfSpeech: .iAdjective, wordCost: 1000),
        ]
        dictionary["あたらしい"] = [
            DictionaryEntry(reading: "あたらしい", surface: "新しい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["ふるい"] = [
            DictionaryEntry(reading: "ふるい", surface: "古い", partOfSpeech: .iAdjective, wordCost: 500),
        ]
        dictionary["あつい"] = [
            DictionaryEntry(reading: "あつい", surface: "暑い", partOfSpeech: .iAdjective, wordCost: 500),
            DictionaryEntry(reading: "あつい", surface: "熱い", partOfSpeech: .iAdjective, wordCost: 600),
        ]
        dictionary["さむい"] = [
            DictionaryEntry(reading: "さむい", surface: "寒い", partOfSpeech: .iAdjective, wordCost: 500),
        ]
        dictionary["すずしい"] = [
            DictionaryEntry(reading: "すずしい", surface: "涼しい", partOfSpeech: .iAdjective, wordCost: 600),
        ]
        dictionary["あたたかい"] = [
            DictionaryEntry(reading: "あたたかい", surface: "暖かい", partOfSpeech: .iAdjective, wordCost: 500),
            DictionaryEntry(reading: "あたたかい", surface: "温かい", partOfSpeech: .iAdjective, wordCost: 600),
        ]
        dictionary["おいしい"] = [
            DictionaryEntry(reading: "おいしい", surface: "美味しい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["たのしい"] = [
            DictionaryEntry(reading: "たのしい", surface: "楽しい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["うれしい"] = [
            DictionaryEntry(reading: "うれしい", surface: "嬉しい", partOfSpeech: .iAdjective, wordCost: 500),
        ]
        dictionary["かなしい"] = [
            DictionaryEntry(reading: "かなしい", surface: "悲しい", partOfSpeech: .iAdjective, wordCost: 600),
        ]
        dictionary["むずかしい"] = [
            DictionaryEntry(reading: "むずかしい", surface: "難しい", partOfSpeech: .iAdjective, wordCost: 400),
        ]
        dictionary["やさしい"] = [
            DictionaryEntry(reading: "やさしい", surface: "易しい", partOfSpeech: .iAdjective, wordCost: 600),
            DictionaryEntry(reading: "やさしい", surface: "優しい", partOfSpeech: .iAdjective, wordCost: 500),
        ]

        // Common verbs
        dictionary["いく"] = [
            DictionaryEntry(reading: "いく", surface: "行く", partOfSpeech: .verbGodan, wordCost: 300),
        ]
        dictionary["くる"] = [
            DictionaryEntry(reading: "くる", surface: "来る", partOfSpeech: .verbIrregular, wordCost: 300),
        ]
        dictionary["する"] = [
            DictionaryEntry(reading: "する", surface: "する", partOfSpeech: .verbIrregular, wordCost: 200),
        ]
        dictionary["ある"] = [
            DictionaryEntry(reading: "ある", surface: "有る", partOfSpeech: .verbGodan, wordCost: 400),
            DictionaryEntry(reading: "ある", surface: "在る", partOfSpeech: .verbGodan, wordCost: 600),
        ]
        dictionary["いる"] = [
            DictionaryEntry(reading: "いる", surface: "居る", partOfSpeech: .verbIchidan, wordCost: 400),
        ]
        dictionary["なる"] = [
            DictionaryEntry(reading: "なる", surface: "成る", partOfSpeech: .verbGodan, wordCost: 400),
            DictionaryEntry(reading: "なる", surface: "為る", partOfSpeech: .verbGodan, wordCost: 1000),
        ]
        dictionary["もつ"] = [
            DictionaryEntry(reading: "もつ", surface: "持つ", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["とる"] = [
            DictionaryEntry(reading: "とる", surface: "取る", partOfSpeech: .verbGodan, wordCost: 400),
            DictionaryEntry(reading: "とる", surface: "撮る", partOfSpeech: .verbGodan, wordCost: 600),
        ]
        dictionary["おもう"] = [
            DictionaryEntry(reading: "おもう", surface: "思う", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["いう"] = [
            DictionaryEntry(reading: "いう", surface: "言う", partOfSpeech: .verbGodan, wordCost: 300),
        ]
        dictionary["きく"] = [
            DictionaryEntry(reading: "きく", surface: "聞く", partOfSpeech: .verbGodan, wordCost: 400),
            DictionaryEntry(reading: "きく", surface: "聴く", partOfSpeech: .verbGodan, wordCost: 800),
        ]
        dictionary["はなす"] = [
            DictionaryEntry(reading: "はなす", surface: "話す", partOfSpeech: .verbGodan, wordCost: 400),
            DictionaryEntry(reading: "はなす", surface: "離す", partOfSpeech: .verbGodan, wordCost: 800),
        ]
        dictionary["よむ"] = [
            DictionaryEntry(reading: "よむ", surface: "読む", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["かう"] = [
            DictionaryEntry(reading: "かう", surface: "買う", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["うる"] = [
            DictionaryEntry(reading: "うる", surface: "売る", partOfSpeech: .verbGodan, wordCost: 500),
        ]
        dictionary["のむ"] = [
            DictionaryEntry(reading: "のむ", surface: "飲む", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["たつ"] = [
            DictionaryEntry(reading: "たつ", surface: "立つ", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["すわる"] = [
            DictionaryEntry(reading: "すわる", surface: "座る", partOfSpeech: .verbGodan, wordCost: 500),
        ]
        dictionary["ねる"] = [
            DictionaryEntry(reading: "ねる", surface: "寝る", partOfSpeech: .verbIchidan, wordCost: 400),
        ]
        dictionary["おきる"] = [
            DictionaryEntry(reading: "おきる", surface: "起きる", partOfSpeech: .verbIchidan, wordCost: 400),
        ]
        dictionary["あるく"] = [
            DictionaryEntry(reading: "あるく", surface: "歩く", partOfSpeech: .verbGodan, wordCost: 400),
        ]
        dictionary["はしる"] = [
            DictionaryEntry(reading: "はしる", surface: "走る", partOfSpeech: .verbGodan, wordCost: 500),
        ]
        dictionary["とぶ"] = [
            DictionaryEntry(reading: "とぶ", surface: "飛ぶ", partOfSpeech: .verbGodan, wordCost: 600),
        ]
        dictionary["あける"] = [
            DictionaryEntry(reading: "あける", surface: "開ける", partOfSpeech: .verbIchidan, wordCost: 500),
        ]
        dictionary["しめる"] = [
            DictionaryEntry(reading: "しめる", surface: "閉める", partOfSpeech: .verbIchidan, wordCost: 600),
        ]
        dictionary["とじる"] = [
            DictionaryEntry(reading: "とじる", surface: "閉じる", partOfSpeech: .verbIchidan, wordCost: 600),
        ]
        dictionary["つける"] = [
            DictionaryEntry(reading: "つける", surface: "付ける", partOfSpeech: .verbIchidan, wordCost: 500),
            DictionaryEntry(reading: "つける", surface: "点ける", partOfSpeech: .verbIchidan, wordCost: 700),
        ]
        dictionary["けす"] = [
            DictionaryEntry(reading: "けす", surface: "消す", partOfSpeech: .verbGodan, wordCost: 500),
        ]

        viterbiConverter = ViterbiConverter(dictionary: dictionary)
        print("[KanjiConversionEngine] Loaded \(dictionary.count) dictionary entries with POS data")
    }

    // MARK: - Persistence

    private func loadLearningData() {
        if let data = UserDefaults.standard.data(forKey: "KanjiConversionLearningData"),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            learningData = decoded
            print("[KanjiConversionEngine] Loaded learning data: \(learningData.count) entries")
        }
    }

    private func saveLearningData() {
        if let encoded = try? JSONEncoder().encode(learningData) {
            UserDefaults.standard.set(encoded, forKey: "KanjiConversionLearningData")
        }
    }
}
