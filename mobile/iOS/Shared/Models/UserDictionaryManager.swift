//
//  UserDictionaryManager.swift
//  Cyrillic IME
//
//  Manages user dictionary entries with persistence
//  Phase 5: Settings & User Dictionary
//

import Foundation
import Combine

/// ユーザー辞書マネージャー
class UserDictionaryManager: ObservableObject {
    // MARK: - Singleton
    static let shared = UserDictionaryManager()

    // MARK: - Properties
    @Published private(set) var entries: [UserDictionaryEntry] = []

    private let userDefaults = UserDefaults.shared
    private let entriesKey = "user_dictionary_entries"

    // MARK: - Initialization

    private init() {
        loadEntries()
    }

    // MARK: - CRUD Operations

    /// エントリを追加
    func addEntry(_ entry: UserDictionaryEntry) {
        entries.append(entry)
        saveEntries()
        print("[UserDictionary] Added entry: \(entry.reading) → \(entry.output)")
    }

    /// 複数のエントリを追加
    func addEntries(_ newEntries: [UserDictionaryEntry]) {
        entries.append(contentsOf: newEntries)
        saveEntries()
        print("[UserDictionary] Added \(newEntries.count) entries")
    }

    /// エントリを削除
    func removeEntry(_ entry: UserDictionaryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
        print("[UserDictionary] Removed entry: \(entry.reading)")
    }

    /// インデックスでエントリを削除
    func removeEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
        print("[UserDictionary] Removed \(offsets.count) entries")
    }

    /// エントリを更新
    func updateEntry(_ entry: UserDictionaryEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
            print("[UserDictionary] Updated entry: \(entry.reading)")
        }
    }

    /// 全エントリを削除
    func clearAll() {
        entries.removeAll()
        saveEntries()
        print("[UserDictionary] Cleared all entries")
    }

    // MARK: - Lookup Operations

    /// 読みで候補を検索
    /// - Parameter reading: ひらがな読み
    /// - Returns: 候補配列（頻度順）
    func lookup(reading: String) -> [String] {
        let matches = entries
            .filter { $0.reading == reading }
            .sorted { $0.frequency > $1.frequency }  // 頻度順
            .map { $0.output }

        return matches
    }

    /// 前方一致で候補を検索
    /// - Parameter prefix: 読みの前方部分
    /// - Returns: マッチしたエントリ配列
    func lookupByPrefix(_ prefix: String) -> [UserDictionaryEntry] {
        return entries
            .filter { $0.reading.hasPrefix(prefix) }
            .sorted { $0.frequency > $1.frequency }
    }

    /// 使用を記録（学習）
    /// - Parameters:
    ///   - reading: 読み
    ///   - output: 選択された変換結果
    func recordUsage(reading: String, output: String) {
        if let index = entries.firstIndex(where: { $0.reading == reading && $0.output == output }) {
            entries[index].recordUsage()
            saveEntries()
            print("[UserDictionary] Recorded usage: \(reading) → \(output) (freq: \(entries[index].frequency))")
        }
    }

    // MARK: - Persistence

    /// エントリをロード
    private func loadEntries() {
        guard let data = userDefaults.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([UserDictionaryEntry].self, from: data) else {
            print("[UserDictionary] No saved entries found, starting fresh")
            return
        }

        entries = decoded
        print("[UserDictionary] Loaded \(entries.count) entries")
    }

    /// エントリを保存
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: entriesKey)
            print("[UserDictionary] Saved \(entries.count) entries")
        } else {
            print("[UserDictionary] Error: Failed to encode entries")
        }
    }

    // MARK: - Statistics

    /// 統計情報を取得
    var statistics: DictionaryStatistics {
        return DictionaryStatistics(
            totalEntries: entries.count,
            totalUsage: entries.reduce(0) { $0 + $1.frequency },
            mostUsedEntry: entries.max { $0.frequency < $1.frequency }
        )
    }
}

// MARK: - Supporting Types

struct DictionaryStatistics {
    let totalEntries: Int
    let totalUsage: Int
    let mostUsedEntry: UserDictionaryEntry?
}

// MARK: - Preview Helpers
#if DEBUG
extension UserDictionaryManager {
    /// テスト用の初期化
    func initializeForTesting(entries: [UserDictionaryEntry]) {
        self.entries = entries
    }
}
#endif
