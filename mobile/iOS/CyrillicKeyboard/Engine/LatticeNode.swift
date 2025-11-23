//
//  LatticeNode.swift
//  CyrillicKeyboard
//
//  Lattice node for Viterbi algorithm
//  Based on azooKey's statistical kana-kanji conversion
//

import Foundation

/// Node in the conversion lattice
class LatticeNode {
    // MARK: - Properties

    /// Position in the input string (character index)
    let position: Int

    /// Dictionary entry for this node (nil for BOS/EOS)
    let entry: DictionaryEntry?

    /// Length of input consumed by this node
    let inputLength: Int

    /// Accumulated cost from beginning of sentence to this node
    var totalCost: Int = Int.max

    /// Previous node in the optimal path (for backtracking)
    weak var previousNode: LatticeNode?

    /// Is this the beginning-of-sentence marker?
    let isBeginOfSentence: Bool

    /// Is this the end-of-sentence marker?
    let isEndOfSentence: Bool

    // MARK: - Initialization

    /// Initialize with dictionary entry
    init(position: Int, entry: DictionaryEntry, inputLength: Int) {
        self.position = position
        self.entry = entry
        self.inputLength = inputLength
        self.isBeginOfSentence = false
        self.isEndOfSentence = false
    }

    /// Initialize BOS (Beginning Of Sentence) marker
    static func beginOfSentence() -> LatticeNode {
        let bos = LatticeNode(
            position: 0,
            entry: DictionaryEntry(
                reading: "",
                surface: "",
                partOfSpeech: .unknown,
                wordCost: 0
            ),
            inputLength: 0
        )
        return LatticeNode(bos: bos)
    }

    /// Initialize EOS (End Of Sentence) marker
    static func endOfSentence(position: Int) -> LatticeNode {
        let eos = LatticeNode(
            position: position,
            entry: DictionaryEntry(
                reading: "",
                surface: "",
                partOfSpeech: .unknown,
                wordCost: 0
            ),
            inputLength: 0
        )
        return LatticeNode(eos: eos)
    }

    private init(bos: LatticeNode) {
        self.position = 0
        self.entry = bos.entry
        self.inputLength = 0
        self.isBeginOfSentence = true
        self.isEndOfSentence = false
        self.totalCost = 0  // BOS has cost 0
    }

    private init(eos: LatticeNode) {
        self.position = eos.position
        self.entry = eos.entry
        self.inputLength = 0
        self.isBeginOfSentence = false
        self.isEndOfSentence = true
    }

    // MARK: - Methods

    /// Calculate cost to connect to another node
    /// - Parameter nextNode: Next node to connect to
    /// - Returns: Total cost (word cost + connection cost)
    func connectionCost(to nextNode: LatticeNode) -> Int {
        guard let currentEntry = self.entry,
              let nextEntry = nextNode.entry else {
            return 0  // BOS/EOS connection
        }

        let wordCost = nextEntry.finalCost
        let connectionCost = ConnectionCost.shared.cost(
            from: currentEntry.partOfSpeech,
            to: nextEntry.partOfSpeech
        )

        return wordCost + connectionCost
    }

    /// Get the surface form (output text)
    var surface: String {
        return entry?.surface ?? ""
    }

    /// Get the part of speech
    var partOfSpeech: PartOfSpeech {
        return entry?.partOfSpeech ?? .unknown
    }
}

// MARK: - CustomStringConvertible
extension LatticeNode: CustomStringConvertible {
    var description: String {
        if isBeginOfSentence {
            return "[BOS]"
        }
        if isEndOfSentence {
            return "[EOS]"
        }
        let pos = entry?.partOfSpeech.rawValue ?? "?"
        let surface = entry?.surface ?? "?"
        let cost = entry?.wordCost ?? 0
        return "[\(position)]'\(surface)'(\(pos), cost:\(cost))"
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension LatticeNode {
    /// Create test nodes for debugging
    static func testNodes() -> [LatticeNode] {
        let entries = DictionaryEntry.examples
        return [
            LatticeNode.beginOfSentence(),
            LatticeNode(position: 0, entry: entries[0], inputLength: 2),  // さる→去る
            LatticeNode(position: 0, entry: entries[1], inputLength: 2),  // さる→猿
            LatticeNode(position: 2, entry: entries[2], inputLength: 1),  // が
            LatticeNode(position: 3, entry: entries[3], inputLength: 2),  // いる→居る
            LatticeNode.endOfSentence(position: 5)
        ]
    }

    /// Test Viterbi path calculation
    func testPath() {
        print("\n=== Lattice Path Test ===")
        print("Node: \(self)")
        print("Total cost: \(totalCost)")
        if let prev = previousNode {
            print("Previous: \(prev)")
        }
    }
}
#endif
