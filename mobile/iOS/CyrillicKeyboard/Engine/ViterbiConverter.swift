//
//  ViterbiConverter.swift
//  CyrillicKeyboard
//
//  Viterbi algorithm for statistical kana-kanji conversion
//  Based on azooKey's architecture (Mozc-inspired)
//

import Foundation

/// Viterbi-based statistical converter
class ViterbiConverter {
    // MARK: - Properties

    /// Dictionary entries indexed by reading
    private var dictionary: [String: [DictionaryEntry]] = [:]

    /// Connection cost calculator
    private let connectionCost = ConnectionCost.shared

    // MARK: - Initialization

    init(dictionary: [String: [DictionaryEntry]]) {
        self.dictionary = dictionary
        print("[ViterbiConverter] Initialized with \(dictionary.count) readings")
    }

    // MARK: - Public Interface

    /// Convert hiragana to kanji using Viterbi algorithm
    /// - Parameters:
    ///   - hiragana: Input hiragana string
    ///   - maxCandidates: Maximum number of candidates to return
    /// - Returns: Sorted candidates (best first)
    func convert(_ hiragana: String, maxCandidates: Int = 10) -> [String] {
        // Build lattice
        let lattice = buildLattice(for: hiragana)

        // Find optimal path using Viterbi
        guard let bestPath = findBestPath(lattice: lattice, inputLength: hiragana.count) else {
            print("[ViterbiConverter] No valid path found for: \(hiragana)")
            return []
        }

        // Extract surface forms from path
        let result = extractSurface(from: bestPath)

        // For now, return just the best result
        // TODO: Generate N-best candidates
        return [result]
    }

    // MARK: - Lattice Construction

    /// Build lattice from input hiragana
    private func buildLattice(for hiragana: String) -> [[LatticeNode]] {
        // Convert to array for easier indexing
        let chars = Array(hiragana)
        let inputLength = chars.count
        var lattice: [[LatticeNode]] = Array(repeating: [], count: inputLength + 1)

        // Add BOS (Beginning Of Sentence) at position 0
        lattice[0].append(LatticeNode.beginOfSentence())

        // For each position, try to find matching dictionary entries
        for startPos in 0..<inputLength {
            // Try all possible lengths from this position
            let maxLen = min(inputLength - startPos, 10)  // Max 10 characters
            for length in 1...maxLen {
                let endPos = startPos + length
                let substring = String(chars[startPos..<endPos])

                // Look up in dictionary
                if let entries = dictionary[substring] {
                    for entry in entries {
                        let node = LatticeNode(
                            position: startPos,
                            entry: entry,
                            inputLength: length
                        )
                        lattice[endPos].append(node)
                    }
                }
            }

            // Add single character fallback (unknown word)
            if startPos < inputLength {
                let char = String(chars[startPos])
                let unknownEntry = DictionaryEntry(
                    reading: char,
                    surface: char,
                    partOfSpeech: .unknown,
                    wordCost: 10000  // High cost for unknown words
                )
                let unknownNode = LatticeNode(
                    position: startPos,
                    entry: unknownEntry,
                    inputLength: 1
                )
                lattice[startPos + 1].append(unknownNode)
            }
        }

        // Add EOS (End Of Sentence) at final position
        lattice[inputLength].append(LatticeNode.endOfSentence(position: inputLength))

        // Debug output
        print("[ViterbiConverter] Built lattice with \(lattice.count) positions")
        for (pos, nodes) in lattice.enumerated() {
            if !nodes.isEmpty {
                print("  Position \(pos): \(nodes.count) nodes")
            }
        }

        return lattice
    }

    // MARK: - Viterbi Algorithm

    /// Find best path through lattice using Viterbi algorithm
    private func findBestPath(lattice: [[LatticeNode]], inputLength: Int) -> [LatticeNode]? {
        // Forward pass: calculate minimum cost to reach each node
        for position in 0...inputLength {
            for currentNode in lattice[position] {
                // Find predecessors (nodes that can connect to this node)
                let prevPosition = position - currentNode.inputLength
                guard prevPosition >= 0 else { continue }

                for prevNode in lattice[prevPosition] {
                    // Calculate cost of this connection
                    let edgeCost = prevNode.connectionCost(to: currentNode)
                    let newCost = prevNode.totalCost + edgeCost

                    // Update if this is a better path
                    if newCost < currentNode.totalCost {
                        currentNode.totalCost = newCost
                        currentNode.previousNode = prevNode
                    }
                }
            }
        }

        // Backward pass: trace best path from EOS to BOS
        guard let eosNode = lattice[inputLength].first(where: { $0.isEndOfSentence }) else {
            print("[ViterbiConverter] EOS node not found")
            return nil
        }

        var path: [LatticeNode] = []
        var currentNode: LatticeNode? = eosNode

        while let node = currentNode {
            if !node.isBeginOfSentence && !node.isEndOfSentence {
                path.insert(node, at: 0)  // Insert at beginning to reverse order
            }
            currentNode = node.previousNode
        }

        print("[ViterbiConverter] Best path cost: \(eosNode.totalCost)")
        print("[ViterbiConverter] Path length: \(path.count) nodes")

        return path
    }

    // MARK: - Result Extraction

    /// Extract surface form from path
    private func extractSurface(from path: [LatticeNode]) -> String {
        return path.map { $0.surface }.joined()
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ViterbiConverter {
    /// Create test converter with example dictionary
    static func testConverter() -> ViterbiConverter {
        let testDictionary: [String: [DictionaryEntry]] = [
            "さる": [
                DictionaryEntry(reading: "さる", surface: "猿", partOfSpeech: .noun, wordCost: 1000),
                DictionaryEntry(reading: "さる", surface: "去る", partOfSpeech: .verbGodan, wordCost: 800),
            ],
            "が": [
                DictionaryEntry(reading: "が", surface: "が", partOfSpeech: .caseParticle, wordCost: 100),
            ],
            "いる": [
                DictionaryEntry(reading: "いる", surface: "居る", partOfSpeech: .verbIchidan, wordCost: 500),
                DictionaryEntry(reading: "いる", surface: "要る", partOfSpeech: .verbGodan, wordCost: 800),
            ],
        ]

        return ViterbiConverter(dictionary: testDictionary)
    }

    /// Test conversion
    func testConvert() {
        print("\n=== Viterbi Conversion Test ===")
        let results = convert("さるがいる", maxCandidates: 3)
        print("Input: さるがいる")
        for (i, result) in results.enumerated() {
            print("  [\(i + 1)] \(result)")
        }
    }
}
#endif
