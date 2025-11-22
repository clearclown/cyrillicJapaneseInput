//
//  UserDictionaryEntry.swift
//  Cyrillic IME
//
//  User dictionary entry model
//  Phase 5: Settings & User Dictionary
//

import Foundation

/// ユーザー辞書エントリ
struct UserDictionaryEntry: Identifiable, Codable, Hashable {
    /// 一意識別子
    let id: UUID

    /// 読み（ひらがな）
    let reading: String

    /// 変換結果（漢字・カタカナ等）
    let output: String

    /// 使用頻度（学習用）
    var frequency: Int

    /// 作成日時
    let createdAt: Date

    /// 最終使用日時
    var lastUsedAt: Date?

    init(reading: String, output: String, frequency: Int = 0) {
        self.id = UUID()
        self.reading = reading
        self.output = output
        self.frequency = frequency
        self.createdAt = Date()
        self.lastUsedAt = nil
    }

    /// 使用回数を記録
    mutating func recordUsage() {
        frequency += 1
        lastUsedAt = Date()
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension UserDictionaryEntry {
    static let preview = UserDictionaryEntry(
        reading: "かんじ",
        output: "漢字",
        frequency: 5
    )

    static let previewEntries = [
        UserDictionaryEntry(reading: "かんじ", output: "漢字", frequency: 10),
        UserDictionaryEntry(reading: "ぴすも", output: "Pismo", frequency: 8),
        UserDictionaryEntry(reading: "にほんご", output: "日本語", frequency: 15),
        UserDictionaryEntry(reading: "あいえむいー", output: "IME", frequency: 3)
    ]
}
#endif
