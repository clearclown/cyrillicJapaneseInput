//
//  PredictiveEngine.swift
//  CyrillicKeyboard
//
//  Predicts next words based on context using bigram model
//  Learns from user input patterns
//

import Foundation

/// Predicts next words based on context
final class PredictiveEngine {
    // MARK: - Properties

    /// Bigram frequency map: "previous word" → ["next word": frequency]
    private var bigramMap: [String: [String: Double]] = [:]

    /// Unigram frequency map: "word" → frequency
    private var unigramMap: [String: Double] = [:]

    /// Recent usage: "word" → last used timestamp
    private var recentUsage: [String: Date] = [:]

    /// Maximum entries in bigram map
    private let maxBigramEntries = 10000

    /// Maximum entries per bigram key
    private let maxBigramsPerKey = 100

    // MARK: - Initialization

    init() {
        loadBigramModel()
    }

    // MARK: - Prediction

    /// Predicts next words based on context and prefix
    /// - Parameters:
    ///   - context: Previous word or phrase (e.g., "今日は")
    ///   - prefix: Current input prefix (e.g., "い")
    ///   - maxCount: Maximum number of predictions to return
    /// - Returns: Array of predicted words sorted by relevance
    func predict(after context: String, prefix: String = "", maxCount: Int = 5) -> [String] {
        var candidates: [(word: String, score: Double)] = []

        // Get bigram candidates
        if let bigrams = bigramMap[context] {
            for (word, bigramScore) in bigrams {
                // Filter by prefix if provided
                if prefix.isEmpty || word.hasPrefix(prefix) {
                    let finalScore = calculateScore(
                        word: word,
                        bigramScore: bigramScore,
                        context: context
                    )
                    candidates.append((word, finalScore))
                }
            }
        }

        // If not enough bigram candidates, add unigram candidates
        if candidates.count < maxCount {
            for (word, unigramScore) in unigramMap {
                // Skip if already in candidates
                if candidates.contains(where: { $0.word == word }) {
                    continue
                }

                // Filter by prefix
                if prefix.isEmpty || word.hasPrefix(prefix) {
                    let finalScore = calculateScore(
                        word: word,
                        bigramScore: 0.0,
                        context: context
                    )
                    candidates.append((word, finalScore))
                }
            }
        }

        // Sort by score and limit
        candidates.sort { $0.score > $1.score }
        return Array(candidates.prefix(maxCount)).map { $0.word }
    }

    /// Predicts full phrases based on prefix
    /// - Parameters:
    ///   - prefix: Current input prefix
    ///   - maxCount: Maximum predictions
    /// - Returns: Array of predicted phrases
    func predictPhrase(prefix: String, maxCount: Int = 3) -> [String] {
        // For now, just return unigram matches
        // TODO: Implement n-gram phrase prediction
        var matches: [(String, Double)] = []

        for (word, score) in unigramMap {
            if word.hasPrefix(prefix) && word != prefix {
                matches.append((word, score))
            }
        }

        matches.sort { $0.1 > $1.1 }
        return Array(matches.prefix(maxCount)).map { $0.0 }
    }

    // MARK: - Learning

    /// Records user selection for learning
    /// - Parameters:
    ///   - context: Previous word/phrase
    ///   - selected: Selected word
    func recordSelection(context: String, selected: String) {
        // Update bigram
        if bigramMap[context] == nil {
            bigramMap[context] = [:]
        }

        // Increment bigram frequency
        bigramMap[context]?[selected, default: 0] += 1.0

        // Prune if too many entries
        if let count = bigramMap[context]?.count, count > maxBigramsPerKey {
            pruneBigrams(for: context)
        }

        // Update unigram
        unigramMap[selected, default: 0] += 1.0

        // Record recent usage
        recentUsage[selected] = Date()

        // Check total bigram size
        if bigramMap.count > maxBigramEntries {
            pruneOldBigrams()
        }

        // Persist
        saveBigramModel()

        print("[PredictiveEngine] Learned: '\(context)' → '\(selected)'")
    }

    /// Records a phrase for learning
    /// - Parameter phrase: Complete phrase
    func recordPhrase(_ phrase: String) {
        // Split into words (simple space-based for now)
        let words = phrase.components(separatedBy: CharacterSet.whitespaces)
            .filter { !$0.isEmpty }

        // Record bigrams
        for i in 0..<(words.count - 1) {
            recordSelection(context: words[i], selected: words[i + 1])
        }

        // Record unigrams
        for word in words {
            unigramMap[word, default: 0] += 1.0
            recentUsage[word] = Date()
        }

        saveBigramModel()
    }

    /// Clears all learning data
    func clearLearningData() {
        bigramMap.removeAll()
        unigramMap.removeAll()
        recentUsage.removeAll()
        saveBigramModel()
        print("[PredictiveEngine] Learning data cleared")
    }

    // MARK: - Scoring

    /// Calculates final score for a word
    private func calculateScore(word: String, bigramScore: Double, context: String) -> Double {
        // Weight factors
        let bigramWeight = 0.5
        let unigramWeight = 0.3
        let recencyWeight = 0.2

        // Normalize scores
        let normalizedBigram = normalizeBigramScore(bigramScore, context: context)
        let normalizedUnigram = normalizeUnigramScore(word)
        let recencyScore = recencyScoreForWord(word)

        return (normalizedBigram * bigramWeight) +
               (normalizedUnigram * unigramWeight) +
               (recencyScore * recencyWeight)
    }

    /// Normalizes bigram score (0.0 - 1.0)
    private func normalizeBigramScore(_ score: Double, context: String) -> Double {
        guard let bigrams = bigramMap[context], !bigrams.isEmpty else {
            return 0.0
        }

        let maxScore = bigrams.values.max() ?? 1.0
        return min(1.0, score / maxScore)
    }

    /// Normalizes unigram score (0.0 - 1.0)
    private func normalizeUnigramScore(_ word: String) -> Double {
        let score = unigramMap[word] ?? 0.0
        let maxScore = unigramMap.values.max() ?? 1.0
        return min(1.0, score / maxScore)
    }

    /// Calculates recency score (0.0 - 1.0)
    private func recencyScoreForWord(_ word: String) -> Double {
        guard let lastUsed = recentUsage[word] else { return 0.0 }

        let elapsed = Date().timeIntervalSince(lastUsed)
        let hours = elapsed / 3600.0

        // Decay over 7 days (168 hours)
        // 1.0 at 0 hours, 0.0 at 168 hours
        return max(0.0, 1.0 - (hours / 168.0))
    }

    // MARK: - Pruning

    /// Prunes bigrams for a specific context
    private func pruneBigrams(for context: String) {
        guard var bigrams = bigramMap[context] else { return }

        // Keep only top entries
        let sorted = bigrams.sorted { $0.value > $1.value }
        let topEntries = Array(sorted.prefix(maxBigramsPerKey))
        let pruned = Dictionary(uniqueKeysWithValues: topEntries)

        bigramMap[context] = pruned
    }

    /// Prunes old bigram contexts
    private func pruneOldBigrams() {
        // Calculate usage for each context
        var contextScores: [(String, Double)] = []

        for (context, bigrams) in bigramMap {
            let totalFrequency = bigrams.values.reduce(0, +)
            let recency = recencyScoreForWord(context)
            let score = totalFrequency * 0.7 + recency * 0.3

            contextScores.append((context, score))
        }

        // Keep top 80% of entries
        contextScores.sort { $0.1 > $1.1 }
        let keepCount = Int(Double(maxBigramEntries) * 0.8)
        let contextsToKeep = Set(contextScores.prefix(keepCount).map { $0.0 })

        // Remove low-scoring contexts
        bigramMap = bigramMap.filter { contextsToKeep.contains($0.key) }

        print("[PredictiveEngine] Pruned to \(bigramMap.count) contexts")
    }

    // MARK: - Persistence

    /// Loads bigram model from storage
    private func loadBigramModel() {
        // Load bigram map
        if let data = UserDefaults.standard.data(forKey: "PredictiveEngine.BigramMap"),
           let decoded = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            bigramMap = decoded
        }

        // Load unigram map
        if let data = UserDefaults.standard.data(forKey: "PredictiveEngine.UnigramMap"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            unigramMap = decoded
        }

        // Load recent usage
        if let data = UserDefaults.standard.data(forKey: "PredictiveEngine.RecentUsage"),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            recentUsage = decoded
        }

        print("[PredictiveEngine] Loaded: \(bigramMap.count) bigrams, \(unigramMap.count) unigrams")
    }

    /// Saves bigram model to storage
    private func saveBigramModel() {
        // Save bigram map
        if let encoded = try? JSONEncoder().encode(bigramMap) {
            UserDefaults.standard.set(encoded, forKey: "PredictiveEngine.BigramMap")
        }

        // Save unigram map
        if let encoded = try? JSONEncoder().encode(unigramMap) {
            UserDefaults.standard.set(encoded, forKey: "PredictiveEngine.UnigramMap")
        }

        // Save recent usage
        if let encoded = try? JSONEncoder().encode(recentUsage) {
            UserDefaults.standard.set(encoded, forKey: "PredictiveEngine.RecentUsage")
        }
    }
}
