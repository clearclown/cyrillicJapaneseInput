//
//  SchemaEntry.swift
//  Cyrillic IME
//
//  Schema entry model with hint labels and popup characters
//

import Foundation

/// スキーマエントリ：キリル文字から仮名への変換マッピング
struct SchemaEntry: Codable, Hashable {
    /// 変換先の仮名キー（例: "ka", "shi", "tsu"）
    let kanaKey: String

    /// ヒントラベル（数字や記号）
    let hintLabel: String?

    /// 長押しで表示されるバリエーション文字
    let popupCharacters: [String]?

    enum CodingKeys: String, CodingKey {
        case kanaKey = "kana_key"
        case hintLabel
        case popupCharacters
    }
}

/// スキーマ：キリル文字配列からSchemaEntryへのマッピング
typealias Schema = [String: SchemaEntry]
