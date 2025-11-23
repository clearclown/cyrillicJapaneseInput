//
//  ConnectionCost.swift
//  CyrillicKeyboard
//
//  Connection cost matrix for part-of-speech bigrams
//  Based on azooKey's statistical conversion architecture
//
//  Connection cost represents how likely one POS follows another
//  Lower cost = more natural transition
//

import Foundation

/// Connection cost manager for POS bigrams
class ConnectionCost {
    // MARK: - Singleton
    static let shared = ConnectionCost()

    // MARK: - Properties

    /// Connection cost matrix: [leftPOS][rightPOS] = cost
    /// Based on Japanese grammar rules
    private var costMatrix: [PartOfSpeech: [PartOfSpeech: Int]] = [:]

    // MARK: - Initialization

    private init() {
        buildCostMatrix()
    }

    // MARK: - Public Interface

    /// Get connection cost between two parts of speech
    /// - Parameters:
    ///   - leftPOS: Left word's part of speech
    ///   - rightPOS: Right word's part of speech
    /// - Returns: Connection cost (0-10000, lower is better)
    func cost(from leftPOS: PartOfSpeech, to rightPOS: PartOfSpeech) -> Int {
        return costMatrix[leftPOS]?[rightPOS] ?? 5000  // Default: medium cost
    }

    // MARK: - Private Methods

    /// Build connection cost matrix based on Japanese grammar
    private func buildCostMatrix() {
        // Default costs for all combinations
        let defaultCost = 5000
        let lowCost = 100      // Very natural
        let mediumCost = 1000  // Natural
        let highCost = 8000    // Unnatural

        // Initialize all combinations with default
        for leftPOS in PartOfSpeech.allCases {
            costMatrix[leftPOS] = [:]
            for rightPOS in PartOfSpeech.allCases {
                costMatrix[leftPOS]?[rightPOS] = defaultCost
            }
        }

        // NOUN patterns (名詞)
        setCost(from: .noun, to: .caseParticle, cost: lowCost)      // 猿が
        setCost(from: .noun, to: .topicParticle, cost: lowCost)     // 猿は
        setCost(from: .noun, to: .particle, cost: lowCost)          // 猿も
        setCost(from: .noun, to: .auxiliary, cost: mediumCost)      // 猿です
        setCost(from: .noun, to: .noun, cost: mediumCost)           // 会社員

        setCost(from: .properNoun, to: .caseParticle, cost: lowCost)
        setCost(from: .properNoun, to: .topicParticle, cost: lowCost)

        // VERB patterns (動詞)
        // Verb base form → particle/auxiliary
        setCost(from: .verb, to: .particle, cost: highCost)         // 行くが (unnatural)
        setCost(from: .verbGodan, to: .particle, cost: highCost)
        setCost(from: .verbIchidan, to: .particle, cost: highCost)

        // Verb base form → auxiliary is OK
        setCost(from: .verb, to: .auxiliary, cost: mediumCost)      // 行く+です
        setCost(from: .verbGodan, to: .auxiliary, cost: mediumCost)
        setCost(from: .verbIchidan, to: .auxiliary, cost: mediumCost)
        setCost(from: .verbBaseForm, to: .auxiliary, cost: mediumCost)

        // Verb stem form → noun/auxiliary
        setCost(from: .verbStemForm, to: .noun, cost: mediumCost)   // 走り+方
        setCost(from: .verbStemForm, to: .auxiliary, cost: lowCost) // 走り+ます

        // PARTICLE patterns (助詞)
        setCost(from: .particle, to: .noun, cost: mediumCost)       // が+猿
        setCost(from: .particle, to: .verb, cost: mediumCost)       // を+食べる
        setCost(from: .particle, to: .verbGodan, cost: mediumCost)
        setCost(from: .particle, to: .verbIchidan, cost: mediumCost)
        setCost(from: .particle, to: .iAdjective, cost: mediumCost)
        setCost(from: .particle, to: .naAdjective, cost: mediumCost)

        setCost(from: .caseParticle, to: .noun, cost: mediumCost)
        setCost(from: .caseParticle, to: .verb, cost: lowCost)      // が+居る
        setCost(from: .caseParticle, to: .verbGodan, cost: lowCost)
        setCost(from: .caseParticle, to: .verbIchidan, cost: lowCost)
        setCost(from: .caseParticle, to: .iAdjective, cost: mediumCost)

        setCost(from: .topicParticle, to: .noun, cost: mediumCost)
        setCost(from: .topicParticle, to: .verb, cost: mediumCost)
        setCost(from: .topicParticle, to: .iAdjective, cost: mediumCost)

        // ADJECTIVE patterns (形容詞)
        setCost(from: .iAdjective, to: .noun, cost: lowCost)        // 美しい+花
        setCost(from: .iAdjective, to: .particle, cost: mediumCost)
        setCost(from: .iAdjective, to: .auxiliary, cost: mediumCost)

        setCost(from: .naAdjective, to: .noun, cost: lowCost)       // 静かな+部屋
        setCost(from: .naAdjective, to: .particle, cost: mediumCost)

        // AUXILIARY patterns (助動詞)
        setCost(from: .auxiliary, to: .particle, cost: mediumCost)  // です+が
        setCost(from: .auxiliary, to: .auxiliary, cost: highCost)   // です+です (bad)

        // ADVERB patterns (副詞)
        setCost(from: .adverb, to: .verb, cost: lowCost)            // とても+美しい
        setCost(from: .adverb, to: .iAdjective, cost: lowCost)
        setCost(from: .adverb, to: .naAdjective, cost: lowCost)

        // Special cases (katakana, hiragana)
        setCost(from: .katakana, to: .particle, cost: lowCost)
        setCost(from: .hiragana, to: .particle, cost: lowCost)

        print("[ConnectionCost] Initialized cost matrix with \(costMatrix.count) POS types")
    }

    /// Set connection cost for a specific POS pair
    private func setCost(from leftPOS: PartOfSpeech, to rightPOS: PartOfSpeech, cost: Int) {
        costMatrix[leftPOS]?[rightPOS] = cost
    }
}

// MARK: - PartOfSpeech Extension
extension PartOfSpeech: CaseIterable {
    static var allCases: [PartOfSpeech] {
        return [
            .noun, .properNoun,
            .verb, .verbGodan, .verbIchidan, .verbIrregular,
            .verbStemForm, .verbBaseForm, .verbConditionalForm,
            .iAdjective, .naAdjective,
            .particle, .caseParticle, .topicParticle,
            .auxiliary,
            .adverb, .conjunction, .interjection,
            .prefix, .suffix,
            .symbol,
            .katakana, .hiragana, .unknown
        ]
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ConnectionCost {
    /// Test connection costs for common patterns
    func testCommonPatterns() {
        print("\n=== Connection Cost Examples ===")
        print("Noun → Particle: \(cost(from: .noun, to: .caseParticle))")  // Should be low
        print("Verb → Particle: \(cost(from: .verbGodan, to: .caseParticle))")  // Should be high
        print("Particle → Verb: \(cost(from: .caseParticle, to: .verbIchidan))")  // Should be low
        print("Noun → Noun: \(cost(from: .noun, to: .noun))")  // Medium
    }
}
#endif
