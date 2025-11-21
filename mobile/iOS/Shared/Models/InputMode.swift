//
//  InputMode.swift
//  Cyrillic IME
//
//  Input mode enumeration
//

import Foundation

/// 入力モード
enum InputMode: String, Codable, CaseIterable {
    /// キリル文字を直接入力（変換なし）
    case directCyrillic

    /// キリル文字→日本語平仮名（変換なし）
    case japaneseHiragana

    /// キリル文字→日本語平仮名→変換（漢字/カタカナ）
    case japaneseIME

    /// 表示名（日本語）
    var displayNameJa: String {
        switch self {
        case .directCyrillic:
            return "キリル文字直接入力"
        case .japaneseHiragana:
            return "日本語（平仮名）"
        case .japaneseIME:
            return "日本語（IME）"
        }
    }

    /// 表示名（英語）
    var displayNameEn: String {
        switch self {
        case .directCyrillic:
            return "Direct Cyrillic"
        case .japaneseHiragana:
            return "Japanese (Hiragana)"
        case .japaneseIME:
            return "Japanese (IME)"
        }
    }

    /// 短縮表示名
    var shortName: String {
        switch self {
        case .directCyrillic:
            return "АБВ"
        case .japaneseHiragana:
            return "あ"
        case .japaneseIME:
            return "あ変"
        }
    }
}
