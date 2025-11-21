//
//  UserDictionary.swift
//  CyrillicKeyboard
//
//  Phase 2: User learning dictionary for kanji conversion
//  Stores user's conversion choices to improve future suggestions
//

import Foundation

/// User dictionary for learning conversion preferences
final class UserDictionary {
    // MARK: - Properties

    /// Dictionary entries: Hiragana → [Kanji outputs in order of recent use]
    private var entries: [String: [String]] = [:]

    /// UserDefaults for persistence (using App Group for sharing)
    private let userDefaults: UserDefaults

    /// Storage key
    private let storageKey = "com.pismo.userDictionary"

    /// Maximum entries per input
    private let maxEntriesPerInput = 10

    /// Maximum total entries (to prevent unbounded growth)
    private let maxTotalEntries = 10000

    // MARK: - Initialization

    init(userDefaults: UserDefaults? = nil) {
        // Use App Group shared UserDefaults if available, otherwise standard
        if let sharedDefaults = UserDefaults(suiteName: "group.com.pismo") {
            self.userDefaults = sharedDefaults
        } else if let customDefaults = userDefaults {
            self.userDefaults = customDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }

        load()
    }

    // MARK: - Dictionary Management

    /// Adds a learning entry
    /// - Parameters:
    ///   - input: Hiragana input
    ///   - output: User's selected kanji output
    func add(input: String, output: String) {
        var outputs = entries[input] ?? []

        // Remove if already exists (to move to front)
        if let existingIndex = outputs.firstIndex(of: output) {
            outputs.remove(at: existingIndex)
        }

        // Add to front (most recent)
        outputs.insert(output, at: 0)

        // Limit entries per input
        if outputs.count > maxEntriesPerInput {
            outputs = Array(outputs.prefix(maxEntriesPerInput))
        }

        entries[input] = outputs

        // Check total entries limit
        if entries.count > maxTotalEntries {
            pruneOldEntries()
        }

        save()

        print("[UserDictionary] Added: '\(input)' → '\(output)' (total entries: \(entries.count))")
    }

    /// Looks up candidates from user dictionary
    /// - Parameter input: Hiragana input
    /// - Returns: Array of candidates sorted by recent use
    func lookup(_ input: String) -> [Candidate] {
        guard let outputs = entries[input] else {
            return []
        }

        return outputs.enumerated().map { (index, output) in
            // Score decreases with age (most recent = highest score)
            let score = 10.0 - Double(index) * 0.5

            return Candidate(
                text: output,
                type: .userDictionary,
                score: score,
                metadata: CandidateMetadata(
                    partOfSpeech: nil,
                    frequency: nil,
                    source: "user"
                )
            )
        }
    }

    /// Removes a specific entry
    /// - Parameters:
    ///   - input: Hiragana input
    ///   - output: Kanji output to remove
    func remove(input: String, output: String) {
        guard var outputs = entries[input] else { return }

        if let index = outputs.firstIndex(of: output) {
            outputs.remove(at: index)

            if outputs.isEmpty {
                entries.removeValue(forKey: input)
            } else {
                entries[input] = outputs
            }

            save()
            print("[UserDictionary] Removed: '\(input)' → '\(output)'")
        }
    }

    /// Clears all user dictionary entries
    func clear() {
        entries.removeAll()
        save()
        print("[UserDictionary] Cleared all entries")
    }

    /// Gets all entries (for debugging/export)
    func getAllEntries() -> [String: [String]] {
        return entries
    }

    /// Gets statistics
    func getStatistics() -> (totalInputs: Int, totalOutputs: Int) {
        let totalOutputs = entries.values.reduce(0) { $0 + $1.count }
        return (entries.count, totalOutputs)
    }

    // MARK: - Persistence

    /// Loads dictionary from UserDefaults
    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            print("[UserDictionary] No saved data or decode failed, starting fresh")
            return
        }

        entries = decoded
        print("[UserDictionary] Loaded \(entries.count) input entries")
    }

    /// Saves dictionary to UserDefaults
    private func save() {
        guard let encoded = try? JSONEncoder().encode(entries) else {
            print("[UserDictionary] Error: Failed to encode entries")
            return
        }

        userDefaults.set(encoded, forKey: storageKey)

        // Force synchronization for App Extensions
        userDefaults.synchronize()
    }

    /// Prunes old entries when limit is exceeded
    /// Keeps entries with most outputs (most frequently used)
    private func pruneOldEntries() {
        print("[UserDictionary] Pruning old entries (current: \(entries.count))")

        // Sort by number of outputs (descending) and keep top entries
        let sorted = entries.sorted { $0.value.count > $1.value.count }
        let keepCount = Int(Double(maxTotalEntries) * 0.8) // Keep 80% of max

        entries = Dictionary(uniqueKeysWithValues: sorted.prefix(keepCount))

        print("[UserDictionary] Pruned to \(entries.count) entries")
    }
}

// MARK: - Debug Extension

#if DEBUG
extension UserDictionary {
    /// Adds multiple test entries for debugging
    func addTestEntries() {
        add(input: "かいしゃ", output: "会社")
        add(input: "かいしゃ", output: "開車")
        add(input: "がっこう", output: "学校")
        add(input: "せんせい", output: "先生")
        add(input: "ともだち", output: "友達")
        print("[UserDictionary] Added test entries")
    }

    /// Prints all entries for debugging
    func printAllEntries() {
        print("[UserDictionary] === All Entries ===")
        for (input, outputs) in entries.sorted(by: { $0.key < $1.key }) {
            print("  \(input): \(outputs.joined(separator: ", "))")
        }
        print("[UserDictionary] === Total: \(entries.count) ===")
    }
}
#endif
