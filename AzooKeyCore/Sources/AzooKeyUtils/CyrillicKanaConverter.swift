//
//  CyrillicKanaConverter.swift
//  Keyboard
//
//  Created by Pismo on 2025/11/23.
//

import Foundation
import KanaKanjiConverterModule

/// キリル文字入力から平仮名への変換を担当するクラス
public final class CyrillicKanaConverter {
    public enum Profile: String, CaseIterable {
        case standard = "Standard"
        case ukrainian = "UKR"
        case belarusian = "BEL"
        case bulgarian = "BUL"
        case serbian = "SRB"
    }

    private var currentProfile: Profile = .standard

    // Mapping: Input Sequence -> Hiragana
    // e.g. "Ка" -> "か"
    private var mapping: [String: String] = [:]

    // Prefix set for fast lookup of "Wait" state
    private var mappingPrefixes: Set<String> = []

    public init() {
        self.updateMapping()
    }

    public func setProfile(_ profile: Profile) {
        self.currentProfile = profile
        self.updateMapping()
    }

    public struct InputOperation {
        public let deleteLast: Int
        public let input: String
    }

    /// 入力を処理し、必要な操作を返す
    /// - Parameters:
    ///   - input: 新たに入力された1文字 (キリル文字)
    ///   - composingText: 現在の入力バッファ
    /// - Returns: 実行すべき操作 (削除数と挿入テキスト)
    public func process(input: String, composingText: String) -> InputOperation {
        // 入力文字を大文字に正規化（マッピングはCase-Sensitiveで大文字定義と仮定）
        // ただし、マッピングデータがMixedの場合はそれに合わせる。今回は定義書通りUpperで統一する。
        let inputUpper = input.uppercased()

        // 1. 現在のバッファの未確定部分(Suffix)を取得
        // 単純化のため、バッファの最後尾から最大3文字程度を見る
        // (例: "Дз" + "а" -> "Дза")

        let maxSuffixLength = 4 // 3文字 + 1文字程度
        let buffer = composingText

        // 長い順にマッチを試みる
        // suffixCandidate = bufferSuffix + input

        // バッファのsuffix + 新規入力で候補を生成
        // i=0 の場合は suffix が空なので inputUpper 単体でチェックすることになる
        for i in (0...min(buffer.count, maxSuffixLength)).reversed() {
            let suffix = String(buffer.suffix(i))
            let candidate = suffix.uppercased() + inputUpper

            // プレフィックス一致チェック (Wait状態) - 完全一致より優先
            // より長いマッピングの可能性がある場合は待機する
            if mappingPrefixes.contains(candidate) {
                // 待機するなら、そのまま入力文字を追加するだけ
                return InputOperation(deleteLast: 0, input: input)
            }

            // 完全一致チェック
            if let kana = mapping[candidate] {
                return InputOperation(deleteLast: i, input: kana)
            }
        }

        // マッチしない場合

        // 直前の文字を取得
        let lastChar = buffer.last.map { String($0) }

        // 特殊規則: 促音 (Sokuon)
        // 同じ子音が連続した場合 (例: "К" + "К")
        if let last = lastChar, last.uppercased() == inputUpper, isConsonant(inputUpper) {
            // "っ" + input に置き換える
            // delete 1 ("K"), insert "っ", insert "K"
            // InputOperationは単一操作しか定義していないので、"っ" + input を返す
            return InputOperation(deleteLast: 1, input: "っ" + input)
        }

        // 特殊規則: 撥音 (N)
        // "н" + 子音 -> "ん" + 子音
        if let last = lastChar, (last == "н" || last == "Н") {
            // 次が母音または記号でないなら "ん" に確定
            if !isVowelOrSign(inputUpper) {
                return InputOperation(deleteLast: 1, input: "ん" + input)
            }
        }

        // 何もマッチしない場合はそのまま入力
        return InputOperation(deleteLast: 0, input: input)
    }

    private func isConsonant(_ char: String) -> Bool {
        let vowelsAndSigns = "АИУЭОЯЮЁЕІЇЄЪЬ'’"
        return !vowelsAndSigns.contains(char)
    }

    private func isVowelOrSign(_ char: String) -> Bool {
        let vowelsAndSigns = "АИУЭОЯЮЁЕІЇЄЪЬ'’"
        return vowelsAndSigns.contains(char)
    }

    private func updateMapping() {
        var newMapping: [String: String] = [:]

        // Load Standard Seion
        // CSV format: Key,Output,Standard,UKR,BEL,BUL,SRB
        // Embedded Data for simplicity

        let seionData = [
            ("a", "あ", "А", "А", "А", "А", "А"),
            ("i", "い", "И", "І", "І", "И", "И"),
            ("u", "う", "У", "У", "У", "Ъ", "У"),
            ("e", "え", "Э", "Э", "Э", "Е", "Э"),
            ("o", "お", "О", "О", "О", "О", "О"),
            ("ka", "か", "Ка", "Ка", "Ка", "Ка", "Ка"),
            ("ki", "き", "Ки", "Кі", "Кі", "Ки", "Ки"),
            ("ku", "く", "Ку", "Ку", "Ку", "Къ", "Ку"),
            ("ke", "け", "Кэ", "Кэ", "Кэ", "Ке", "Кэ"),
            ("ko", "こ", "Ко", "Ко", "Ко", "Ко", "Ко"),
            ("sa", "さ", "Са", "Са", "Са", "Са", "Са"),
            ("shi", "し", "Си", "Сі", "Сі", "Си", "Си"),
            ("su", "す", "Су", "Су", "Су", "Съ", "Су"),
            ("se", "せ", "Сэ", "Сэ", "Сэ", "Се", "Сэ"),
            ("so", "そ", "Со", "Со", "Со", "Со", "Со"),
            ("ta", "た", "Та", "Та", "Та", "Та", "Та"),
            ("chi", "ち", "Чи", "Чі", "Чі", "Чи", "Ћ"),
            ("tsu", "つ", "Цу", "Цу", "Цу", "Цъ", "Цу"),
            ("te", "て", "Тэ", "Тэ", "Тэ", "Те", "Тэ"),
            ("to", "と", "То", "То", "То", "То", "То"),
            ("na", "な", "На", "На", "На", "На", "На"),
            ("ni", "に", "Ни", "Ні", "Ні", "Ни", "Ни"),
            ("nu", "ぬ", "Ну", "Ну", "Ну", "Нъ", "Ну"),
            ("ne", "ね", "Нэ", "Нэ", "Нэ", "Не", "Нэ"),
            ("no", "の", "Но", "Но", "Но", "Но", "Но"),
            ("ha", "は", "Ха", "Ха", "Ха", "Ха", "Ха"),
            ("hi", "ひ", "Хи", "Хі", "Хі", "Хи", "Хи"),
            ("fu", "ふ", "Фу", "Фу", "Фу", "Фъ", "Фу"),
            ("he", "へ", "Хэ", "Хэ", "Хэ", "Хе", "Хэ"),
            ("ho", "ほ", "Хо", "Хо", "Хо", "Хо", "Хо"),
            ("ma", "ま", "Ма", "Ма", "Ма", "Ма", "Ма"),
            ("mi", "み", "Ми", "Мі", "Мі", "Ми", "Ми"),
            ("mu", "む", "Му", "Му", "Му", "Мъ", "Му"),
            ("me", "め", "Мэ", "Мэ", "Мэ", "Ме", "Мэ"),
            ("mo", "も", "Мо", "Мо", "Мо", "Мо", "Мо"),
            ("ya", "や", "Я", "Я", "Я", "Я", "Ја"),
            ("yu", "ゆ", "Ю", "Ю", "Ю", "Ю", "Ју"),
            ("yo", "よ", "Ё", "Ё", "Ё", "Ё", "Јо"),
            ("ra", "ら", "Ра", "Ра", "Ра", "Ра", "Ра"),
            ("ri", "り", "Ри", "Рі", "Рі", "Ри", "Ри"),
            ("ru", "る", "Ру", "Ру", "Ру", "Ръ", "Ру"),
            ("re", "れ", "Рэ", "Рэ", "Рэ", "Ре", "Рэ"),
            ("ro", "ろ", "Ро", "Ро", "Ро", "Ро", "Ро"),
            ("wa", "わ", "Ва", "Ва", "Ўа", "Ва", "Ва"),
            ("wi", "ゐ", "Ви", "Ві", "Ўі", "Ви", "Ви"),
            ("we", "ゑ", "Вэ", "Вэ", "Ўэ", "Ве", "Вэ"),
            // "wo" (を) is intentionally omitted - О maps to お (o)
            ("n", "ん", "Н", "Н", "Н", "Н", "Н")
        ]

        let dakutenData = [
            ("ga", "が", "Га", "Ґа", "Га", "Га", "Га"),
            ("gi", "ぎ", "Ги", "Ґі", "Ги", "Ги", "Ги"),
            ("gu", "ぐ", "Гу", "Ґу", "Гу", "Гу", "Гу"),
            ("ge", "げ", "Гэ", "Ґе", "Гэ", "Гэ", "Гэ"),
            ("go", "ご", "Го", "Ґо", "Го", "Го", "Го"),
            ("za", "ざ", "Дза", "Дза", "Дза", "Дза", "Дза"),
            ("ji", "じ", "Дзи", "Дзі", "Дзі", "Дзи", "Дзи"),
            ("zu", "ず", "Дзу", "Дзу", "Дзу", "Дзъ", "Дзу"),
            ("ze", "ぜ", "Дзэ", "Дзэ", "Дзэ", "Дзе", "Дзэ"),
            ("zo", "ぞ", "Дзо", "Дзо", "Дзо", "Дзо", "Дзо"),
            ("da", "だ", "Да", "Да", "Да", "Да", "Да"),
            // ぢ (ji_d) and づ (zu_d) are phonetically same as じ/ず, handled by same keys
            ("de", "で", "Дэ", "Дэ", "Дэ", "Де", "Дэ"),
            ("do", "ど", "До", "До", "До", "До", "До"),
            ("ba", "ば", "Ба", "Ба", "Ба", "Ба", "Ба"),
            ("bi", "び", "Би", "Бі", "Бі", "Би", "Би"),
            ("bu", "ぶ", "Бу", "Бу", "Бу", "Бъ", "Бу"),
            ("be", "べ", "Бэ", "Бэ", "Бэ", "Бе", "Бэ"),
            ("bo", "ぼ", "Бо", "Бо", "Бо", "Бо", "Бо"),
            ("pa", "ぱ", "Па", "Па", "Па", "Па", "Па"),
            ("pi", "ぴ", "Пи", "Пі", "Пі", "Пи", "Пи"),
            ("pu", "ぷ", "Пу", "Пу", "Пу", "Пъ", "Пу"),
            ("pe", "ぺ", "Пэ", "Пэ", "Пэ", "Пе", "Пэ"),
            ("po", "ぽ", "По", "По", "По", "По", "По")
        ]

        let specialData = [
            ("n", "ん", "н", "н"),
            ("sokuon", "っ", "ъ", "ъ"), // Analytical mode only? No, standard sokuon is double char
            ("long_vowel", "ー", "ー", "ー"), // Placeholder, logic handles vowel repeat
            ("separator_a", "んあ", "н'а", "н'а"),
            ("separator_ya", "んや", "н'я", "н'я")
        ]

        // Helper to pick column
        func pick(_ row: (String, String, String, String, String, String, String)) -> String {
            switch currentProfile {
            case .standard: return row.2
            case .ukrainian: return row.3
            case .belarusian: return row.4
            case .bulgarian: return row.5
            case .serbian: return row.6
            }
        }

        // Register Seion
        for row in seionData {
            let key = pick(row).uppercased()
            let value = row.1
            newMapping[key] = value
        }

        // Register Dakuten
        for row in dakutenData {
            let key = pick(row).uppercased()
            // Some data might have comma (e.g. "Би, Би") if copy paste error, assume simple
            let cleanKey = key.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? key
            let value = row.1
            newMapping[cleanKey] = value
        }

        // Register Special
        for row in specialData {
            // Special data tuple is different size in CSV logic but here we map manually
            // The CSV had 5 columns: Type,Output,Standard,Analytical,Note
            // We will just map the Standard/Analytical keys directly
            // For now, map the explicit separators
            if row.0.starts(with: "separator") {
                newMapping[row.2.uppercased()] = row.1
            }
        }

        self.mapping = newMapping

        // Build Prefixes
        var prefixes: Set<String> = []
        for key in mapping.keys {
            for i in 1..<key.count {
                prefixes.insert(String(key.prefix(i)))
            }
        }
        self.mappingPrefixes = prefixes
    }
}
