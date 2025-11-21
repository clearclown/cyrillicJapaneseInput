//
//  Profile.swift
//  Cyrillic IME
//
//  Shared data model representing an input profile
//

import Foundation

/// キーボードレイアウト（行ベース）
struct KeyboardLayout: Codable, Hashable {
    let row1: [String]
    let row2: [String]
    let row3: [String]

    /// 全キーをフラットな配列として取得
    var allKeys: [String] {
        return row1 + row2 + row3
    }

    /// 行ごとの配列として取得
    var rows: [[String]] {
        return [row1, row2, row3]
    }
}

/// プロファイル：キリル文字配列の言語バリアント情報
struct Profile: Codable, Identifiable, Hashable {
    /// 一意識別子（例: "rus_standard", "srb_cyrillic"）
    let id: String

    /// 日本語表示名（例: "ロシア語 (標準)"）
    let nameJa: String

    /// 英語表示名（例: "Russian (Standard)"）
    let nameEn: String

    /// キーボードレイアウト（行ベースの構造）
    let keyboardLayout: KeyboardLayout

    /// 対応する入力スキーマID（例: "schema_rus_v1"）
    let inputSchemaId: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameJa = "name_ja"
        case nameEn = "name_en"
        case keyboardLayout
        case inputSchemaId
    }

    /// 現在のロケールに応じた表示名を返す
    var displayName: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode.hasPrefix("ja") ? nameJa : nameEn
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension Profile {
    static let preview = Profile(
        id: "rus_standard",
        nameJa: "ロシア語 (標準)",
        nameEn: "Russian (Standard)",
        keyboardLayout: KeyboardLayout(
            row1: ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З"],
            row2: ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д"],
            row3: ["Я", "Ч", "С", "М", "И", "Т", "Ь"]
        ),
        inputSchemaId: "schema_rus_v1"
    )

    static let previewProfiles = [
        Profile(
            id: "rus_standard",
            nameJa: "ロシア語 (標準)",
            nameEn: "Russian (Standard)",
            keyboardLayout: KeyboardLayout(
                row1: ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З"],
                row2: ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж"],
                row3: ["Я", "Ч", "С", "М", "И", "Т", "Ь"]
            ),
            inputSchemaId: "schema_rus_v1"
        ),
        Profile(
            id: "srb_cyrillic",
            nameJa: "セルビア語",
            nameEn: "Serbian",
            keyboardLayout: KeyboardLayout(
                row1: ["Љ", "Њ", "Е", "Р", "Т", "З", "У", "И", "О", "П"],
                row2: ["Ш", "А", "С", "Д", "Ф", "Г", "Х", "Ј", "К"],
                row3: ["Ч", "Ћ", "Џ", "Ц", "В", "Б", "Н"]
            ),
            inputSchemaId: "schema_srb_v1"
        ),
        Profile(
            id: "ukr_cyrillic",
            nameJa: "ウクライナ語",
            nameEn: "Ukrainian",
            keyboardLayout: KeyboardLayout(
                row1: ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З"],
                row2: ["Ф", "Ї", "В", "А", "П", "Р", "О", "Л", "Д"],
                row3: ["Я", "Ч", "С", "М", "І", "Т", "Ь"]
            ),
            inputSchemaId: "schema_ukr_v1"
        )
    ]
}
#endif
