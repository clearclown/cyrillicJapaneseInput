//
//  Profile.swift
//  Cyrillic IME
//
//  Shared data model representing an input profile
//

import Foundation

/// プロファイル：キリル文字配列の言語バリアント情報
struct Profile: Codable, Identifiable, Hashable {
    /// 一意識別子（例: "rus_standard", "srb_cyrillic"）
    let id: String

    /// 日本語表示名（例: "ロシア語 (標準)"）
    let nameJa: String

    /// 英語表示名（例: "Russian (Standard)"）
    let nameEn: String

    /// キーボードレイアウト（キリル文字の配列）
    let keyboardLayout: [String]

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
        keyboardLayout: ["А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И"],
        inputSchemaId: "schema_rus_v1"
    )

    static let previewProfiles = [
        Profile(
            id: "rus_standard",
            nameJa: "ロシア語 (標準)",
            nameEn: "Russian (Standard)",
            keyboardLayout: ["А", "И", "У", "Э", "О", "К", "С", "Т", "Н", "Х"],
            inputSchemaId: "schema_rus_v1"
        ),
        Profile(
            id: "srb_cyrillic",
            nameJa: "セルビア語",
            nameEn: "Serbian",
            keyboardLayout: ["А", "Б", "В", "Г", "Д", "Ђ", "Е", "Ж", "З", "И"],
            inputSchemaId: "schema_srb_v1"
        ),
        Profile(
            id: "ukr_cyrillic",
            nameJa: "ウクライナ語",
            nameEn: "Ukrainian",
            keyboardLayout: ["А", "Б", "В", "Г", "Ґ", "Д", "Е", "Є", "Ж", "З"],
            inputSchemaId: "schema_ukr_v1"
        )
    ]
}
#endif
