//
//  ConversionResult.swift
//  Cyrillic IME
//
//  Conversion result from Rust Core FFI
//

import Foundation

/// Rust Coreからの変換結果
struct ConversionResult: Codable {
    /// アクション種別：
    /// - "commit": 確定（outputをテキスト挿入、バッファクリア）
    /// - "composing": 入力中（bufferを表示）
    /// - "clear": クリア（バッファをクリア、何も挿入しない）
    let action: String

    /// 出力文字列（action="commit"の場合のみ有効）
    let output: String

    /// 現在の入力バッファ（action="composing"の場合に表示）
    let buffer: String

    /// 最後の出力（長音検出用）
    /// Optional for backward compatibility with Phase 2 JSON
    let lastOutput: String?

    /// 最後の母音タイプ（連続長音検出用）
    /// "ー" の母音タイプを追跡するために使用
    let lastVowelType: String?

    /// 便利プロパティ
    var isCommit: Bool { action == "commit" }
    var isComposing: Bool { action == "composing" }
    var isClear: Bool { action == "clear" }
}

// MARK: - Preview Helpers
#if DEBUG
extension ConversionResult {
    static let commitExample = ConversionResult(
        action: "commit",
        output: "きゃ",
        buffer: "",
        lastOutput: "きゃ",
        lastVowelType: "a"
    )

    static let composingExample = ConversionResult(
        action: "composing",
        output: "",
        buffer: "К",
        lastOutput: nil,
        lastVowelType: nil
    )

    static let clearExample = ConversionResult(
        action: "clear",
        output: "",
        buffer: "",
        lastOutput: nil,
        lastVowelType: nil
    )
}
#endif
