//
//  KanjiConversionEngine.swift
//  CyrillicKeyboard
//
//  Manages hiragana → kanji conversion
//  Phase 2: Basic implementation with mock dictionary
//  Future: Integration with azooKey's KanaKanjiConverter
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

/// Mock kanji conversion engine for Phase 2/3 development
/// TODO Phase 2: Replace with real azooKey integration
final class KanjiConversionEngine: KanjiConversionEngineProtocol {
    // MARK: - Properties

    /// Shared instance
    static let shared = KanjiConversionEngine()

    /// Mock dictionary: hiragana → kanji mappings
    private var mockDictionary: [String: [String]] = [:]

    /// Learning data: hiragana → selected text → frequency
    private var learningData: [String: [String: Int]] = [:]

    // MARK: - Initialization

    init() {
        loadMockDictionary()
        loadLearningData()
    }

    // MARK: - Conversion

    func requestCandidates(for hiragana: String, maxCount: Int) async throws -> [Candidate] {
        // Simulate async processing
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        var candidates: [Candidate] = []

        // 1. Add katakana candidate
        if let katakana = convertToKatakana(hiragana) {
            candidates.append(Candidate(
                text: katakana,
                reading: hiragana,
                score: 0.5,
                isLearned: false,
                partOfSpeech: "katakana"
            ))
        }

        // 2. Add hiragana itself
        candidates.append(Candidate(
            text: hiragana,
            reading: hiragana,
            score: 0.3,
            isLearned: false,
            partOfSpeech: "hiragana"
        ))

        // 3. Look up in mock dictionary
        if let kanjiOptions = mockDictionary[hiragana] {
            for (index, kanji) in kanjiOptions.enumerated() {
                let baseScore = 1.0 - (Double(index) * 0.1)
                let learningBoost = learningScore(for: hiragana, candidate: kanji)
                let finalScore = baseScore + learningBoost

                candidates.append(Candidate(
                    text: kanji,
                    reading: hiragana,
                    score: finalScore,
                    isLearned: learningBoost > 0,
                    partOfSpeech: "noun" // Simplified
                ))
            }
        }

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

    // MARK: - Mock Dictionary

    private func loadMockDictionary() {
        // Common words for testing
        mockDictionary = [
            // か行
            "かい": ["会", "開", "買", "快", "貝"],
            "かいしゃ": ["会社", "開車", "快謝"],
            "かく": ["書く", "描く", "角"],
            "かみ": ["紙", "神", "髪"],
            "かわ": ["川", "河", "皮", "革"],

            // さ行
            "さくら": ["桜", "さくら"],
            "せんせい": ["先生", "先制"],
            "そら": ["空", "そら"],

            // た行
            "たべる": ["食べる"],
            "つくる": ["作る", "創る", "造る"],
            "てんき": ["天気", "電気"],

            // な行
            "なまえ": ["名前"],
            "にほん": ["日本"],

            // は行
            "はな": ["花", "鼻", "話"],
            "ふゆ": ["冬"],

            // ま行
            "まち": ["町", "街", "待ち"],
            "みる": ["見る", "観る", "診る"],

            // や行
            "やま": ["山"],
            "ゆき": ["雪", "行き"],

            // ら行
            "りんご": ["林檎", "りんご"],

            // わ行
            "わたし": ["私", "渡し"],

            // Common phrases
            "きょう": ["今日", "教", "京"],
            "きょうは": ["今日は"],
            "いい": ["良い", "いい"],
            "です": ["です"],
            "ね": ["ね"],

            // Additional common words (Phase 2 expansion)
            "がっこう": ["学校"],
            "せんもん": ["専門"],
            "しごと": ["仕事", "私事"],
            "ともだち": ["友達", "友だち"],
            "でんわ": ["電話"],
            "じかん": ["時間"],
            "ばしょ": ["場所"],
            "もの": ["物", "者"],
            "こと": ["事", "こと"],
            "ひと": ["人"],
            "あした": ["明日"],
            "きのう": ["昨日"],
            "いま": ["今", "居間"],
            "ここ": ["ここ"],
            "そこ": ["そこ"],
            "あそこ": ["あそこ"],
            "なに": ["何"],
            "だれ": ["誰"],
            "いつ": ["何時", "いつ"],
            "どこ": ["何処", "どこ"],
            "どう": ["如何", "どう"],
            "なぜ": ["何故", "なぜ"],
            "おおきい": ["大きい"],
            "ちいさい": ["小さい"],
            "たかい": ["高い", "多い"],
            "やすい": ["安い", "易しい"],
            "あたらしい": ["新しい"],
            "ふるい": ["古い"],
            "あつい": ["暑い", "熱い"],
            "さむい": ["寒い"],
            "すずしい": ["涼しい"],
            "あたたかい": ["暖かい", "温かい"],
            "おいしい": ["美味しい"],
            "たのしい": ["楽しい"],
            "うれしい": ["嬉しい"],
            "かなしい": ["悲しい"],
            "むずかしい": ["難しい"],
            "やさしい": ["易しい", "優しい"],
            "いく": ["行く"],
            "くる": ["来る"],
            "する": ["する"],
            "ある": ["有る", "在る"],
            "いる": ["居る"],
            "なる": ["成る", "為る"],
            "もつ": ["持つ"],
            "とる": ["取る", "撮る"],
            "おもう": ["思う"],
            "いう": ["言う"],
            "きく": ["聞く", "聴く"],
            "はなす": ["話す", "離す"],
            "よむ": ["読む"],
            "かう": ["買う"],
            "うる": ["売る"],
            "のむ": ["飲む"],
            "たつ": ["立つ"],
            "すわる": ["座る"],
            "ねる": ["寝る"],
            "おきる": ["起きる"],
            "あるく": ["歩く"],
            "はしる": ["走る"],
            "とぶ": ["飛ぶ"],
            "あける": ["開ける"],
            "しめる": ["閉める"],
            "とじる": ["閉じる"],
            "つける": ["付ける", "点ける"],
            "けす": ["消す"],
        ]
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
