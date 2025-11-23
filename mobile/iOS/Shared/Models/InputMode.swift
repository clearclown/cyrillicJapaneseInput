//
//  InputMode.swift
//  Cyrillic IME
//
//  Smartphone-appropriate Japanese IME mode
//  Redesigned 2025-11-23: Removed mode switching for smartphone UX
//

import Foundation

/// 入力モード (Simplified for smartphone IME)
enum InputMode: String, Codable {
    /// キリル文字→日本語平仮名→変換（漢字/カタカナ）
    /// This is the only mode needed for smartphone Japanese IME
    case japaneseIME

    /// 表示名（日本語）
    var displayNameJa: String {
        return "日本語（IME）"
    }

    /// 表示名（英語）
    var displayNameEn: String {
        return "Japanese (IME)"
    }
}
