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
        case macedonian = "MKD"
        case kazakh = "KAZ"
        case kyrgyz = "KGZ"
        case mongolian = "MNG"
        case tajik = "TJK"
        case uzbek = "UZB"
        case tatar = "TAT"
        case bashkir = "BAS"
        case chuvash = "CHU"
        case sakha = "SAH"
        case buryat = "BUA"
        case kalmyk = "KAL"
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
        let inputUpper = input.uppercased()
        let maxSuffixLength = 4
        let buffer = composingText
        let lastChar = buffer.last.map { String($0) }

        // Debug: バッファの内容を確認
        #if DEBUG
        print("[CyrillicConverter] input='\(input)' inputUpper='\(inputUpper)' buffer='\(buffer)' buffer.count=\(buffer.count)")
        print("[CyrillicConverter] buffer hex: \(buffer.unicodeScalars.map { String(format: "%04X", $0.value) }.joined(separator: " "))")
        #endif

        // Step 1: 長い順にマッチを試みる（バッファ + 入力の組み合わせ）
        // i > 0 の場合のみ: バッファの末尾と新規入力を組み合わせてマッピングを検索
        // Note: stride を使用して空バッファ (buffer.count == 0) の場合のクラッシュを防ぐ
        for i in stride(from: min(buffer.count, maxSuffixLength), through: 1, by: -1) {
            let suffix = String(buffer.suffix(i))
            let candidate = suffix.uppercased() + inputUpper

            #if DEBUG
            print("[CyrillicConverter] i=\(i) suffix='\(suffix)' candidate='\(candidate)' inMapping=\(mapping[candidate] != nil) inPrefix=\(mappingPrefixes.contains(candidate))")
            #endif

            // 完全一致チェック (プレフィックスより優先)
            if let kana = mapping[candidate] {
                #if DEBUG
                print("[CyrillicConverter] -> Match! deleteLast=\(i) output='\(kana)'")
                #endif
                return InputOperation(deleteLast: i, input: kana)
            }

            // プレフィックス一致チェック (Wait状態)
            if mappingPrefixes.contains(candidate) {
                #if DEBUG
                print("[CyrillicConverter] -> Wait (prefix match)")
                #endif
                return InputOperation(deleteLast: 0, input: input)
            }
        }

        // Step 2: 特殊規則チェック（単一文字のプレフィックスチェックより先に行う）
        // これにより、НН → ん や КК → っК が正しく処理される

        // 撥音 (Nasal sound - ん)
        // "нн" -> "ん" (double н becomes ん)
        // "н" + 子音 -> "ん" + 子音
        if let last = lastChar, (last == "н" || last == "Н") {
            if inputUpper == "Н" {
                return InputOperation(deleteLast: 1, input: "ん")
            }
            if !isVowelOrSign(inputUpper) {
                return InputOperation(deleteLast: 1, input: "ん" + input)
            }
        }

        // 促音 (Sokuon - っ)
        // 同じ子音が連続した場合 (例: "К" + "К") → っ + 子音
        // Н は撥音として上で処理済みなので除外
        if let last = lastChar, last.uppercased() == inputUpper, isConsonantForSokuon(inputUpper) {
            return InputOperation(deleteLast: 1, input: "っ" + input)
        }

        // Step 3: 単一文字のマッピングチェック (i=0 case)
        let singleCandidate = inputUpper

        // 完全一致チェック (プレフィックスより優先)
        if let kana = mapping[singleCandidate] {
            return InputOperation(deleteLast: 0, input: kana)
        }

        // プレフィックス一致チェック (Wait状態)
        if mappingPrefixes.contains(singleCandidate) {
            return InputOperation(deleteLast: 0, input: input)
        }

        // 何もマッチしない場合はそのまま入力
        return InputOperation(deleteLast: 0, input: input)
    }

    private func isConsonant(_ char: String) -> Bool {
        let vowelsAndSigns = "АИУЭОЯЮЁЕІЇЄЪЬ''"
        return !vowelsAndSigns.contains(char)
    }

    private func isVowelOrSign(_ char: String) -> Bool {
        let vowelsAndSigns = "АИУЭОЯЮЁЕІЇЄЪЬ''"
        return vowelsAndSigns.contains(char)
    }

    /// 促音（っ）を生成する子音かどうか
    /// Н は撥音（ん）用なので除外
    private func isConsonantForSokuon(_ char: String) -> Bool {
        let vowelsAndSigns = "АИУЭОЯЮЁЕІЇЄЪЬ''Н"
        return !vowelsAndSigns.contains(char)
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
            ("we", "ゑ", "Вэ", "Вэ", "Ўэ", "Ве", "Вэ")
            // "wo" (を) is intentionally omitted - О maps to お (o)
            // "n" (ん) is handled by special rules: НН → ん, Н + consonant → ん + consonant
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

        // 拗音 (Youon) - Palatalized sounds
        // Format: (key, hiragana, Standard, UKR, BEL, BUL, SRB)
        let youonData = [
            // きゃ行
            ("kya", "きゃ", "Кя", "Кя", "Кя", "Кя", "Кја"),
            ("kyu", "きゅ", "Кю", "Кю", "Кю", "Кю", "Кју"),
            ("kyo", "きょ", "Кё", "Кё", "Кё", "Кё", "Кјо"),
            // しゃ行
            ("sha", "しゃ", "Ся", "Ся", "Ся", "Ся", "Сја"),
            ("shu", "しゅ", "Сю", "Сю", "Сю", "Сю", "Сју"),
            ("sho", "しょ", "Сё", "Сё", "Сё", "Сё", "Сјо"),
            // ちゃ行
            ("cha", "ちゃ", "Ча", "Ча", "Ча", "Ча", "Ћа"),
            ("chu", "ちゅ", "Чу", "Чу", "Чу", "Чу", "Ћу"),
            ("cho", "ちょ", "Чо", "Чо", "Чо", "Чо", "Ћо"),
            // にゃ行
            ("nya", "にゃ", "Ня", "Ня", "Ня", "Ня", "Ња"),
            ("nyu", "にゅ", "Ню", "Ню", "Ню", "Ню", "Њу"),
            ("nyo", "にょ", "Нё", "Нё", "Нё", "Нё", "Њо"),
            // ひゃ行
            ("hya", "ひゃ", "Хя", "Хя", "Хя", "Хя", "Хја"),
            ("hyu", "ひゅ", "Хю", "Хю", "Хю", "Хю", "Хју"),
            ("hyo", "ひょ", "Хё", "Хё", "Хё", "Хё", "Хјо"),
            // みゃ行
            ("mya", "みゃ", "Мя", "Мя", "Мя", "Мя", "Мја"),
            ("myu", "みゅ", "Мю", "Мю", "Мю", "Мю", "Мју"),
            ("myo", "みょ", "Мё", "Мё", "Мё", "Мё", "Мјо"),
            // りゃ行
            ("rya", "りゃ", "Ря", "Ря", "Ря", "Ря", "Рја"),
            ("ryu", "りゅ", "Рю", "Рю", "Рю", "Рю", "Рју"),
            ("ryo", "りょ", "Рё", "Рё", "Рё", "Рё", "Рјо"),
            // ぎゃ行
            ("gya", "ぎゃ", "Гя", "Гя", "Гя", "Гя", "Гја"),
            ("gyu", "ぎゅ", "Гю", "Гю", "Гю", "Гю", "Гју"),
            ("gyo", "ぎょ", "Гё", "Гё", "Гё", "Гё", "Гјо"),
            // じゃ行
            ("ja", "じゃ", "Дзя", "Дзя", "Дзя", "Дзя", "Ђа"),
            ("ju", "じゅ", "Дзю", "Дзю", "Дзю", "Дзю", "Ђу"),
            ("jo", "じょ", "Дзё", "Дзё", "Дзё", "Дзё", "Ђо"),
            // びゃ行
            ("bya", "びゃ", "Бя", "Бя", "Бя", "Бя", "Бја"),
            ("byu", "びゅ", "Бю", "Бю", "Бю", "Бю", "Бју"),
            ("byo", "びょ", "Бё", "Бё", "Бё", "Бё", "Бјо"),
            // ぴゃ行
            ("pya", "ぴゃ", "Пя", "Пя", "Пя", "Пя", "Пја"),
            ("pyu", "ぴゅ", "Пю", "Пю", "Пю", "Пю", "Пју"),
            ("pyo", "ぴょ", "Пё", "Пё", "Пё", "Пё", "Пјо")
        ]

        // 外来語音 (Gairaigo) - Foreign loan word sounds
        // Format: (key, hiragana, Standard, UKR, BEL, BUL, SRB)
        let gairaigoData = [
            // ファ行 (f + vowel)
            ("fa", "ふぁ", "Фа", "Фа", "Фа", "Фа", "Фа"),
            ("fi", "ふぃ", "Фи", "Фі", "Фі", "Фи", "Фи"),
            ("fe", "ふぇ", "Фэ", "Фэ", "Фэ", "Фе", "Фэ"),
            ("fo", "ふぉ", "Фо", "Фо", "Фо", "Фо", "Фо"),
            ("fyu", "ふゅ", "Фю", "Фю", "Фю", "Фю", "Фју"),
            // ティ/ディ行
            ("ti", "てぃ", "Ти", "Ті", "Ті", "Ти", "Ти"),
            ("di", "でぃ", "Ди", "Ді", "Ді", "Ди", "Ди"),
            ("tu", "とぅ", "Ту", "Ту", "Ту", "Ту", "Ту"),
            ("du", "どぅ", "Ду", "Ду", "Ду", "Ду", "Ду"),
            ("tyu", "てゅ", "Тю", "Тю", "Тю", "Тю", "Тју"),
            ("dyu", "でゅ", "Дю", "Дю", "Дю", "Дю", "Дју"),
            // ツァ行 (ts + vowel)
            ("tsa", "つぁ", "Ца", "Ца", "Ца", "Ца", "Ца"),
            ("tsi", "つぃ", "Ци", "Ці", "Ці", "Ци", "Ци"),
            ("tso", "つぉ", "Цо", "Цо", "Цо", "Цо", "Цо"),
            // スィ/ズィ
            ("si", "すぃ", "Сьи", "Сьі", "Сьі", "Сьи", "Сји"),
            ("zi", "ずぃ", "Дзьи", "Дзьі", "Дзьі", "Дзьи", "Дзји"),
            // イェ
            ("ye", "いぇ", "Йэ", "Йе", "Йэ", "Йе", "Је"),
            // ウァ/ウィ/ウェ/ウォ (modern) - Use У to distinguish from В (わ行/古語ゐゑ)
            ("wa_m", "うぁ", "Уа", "Уа", "Уа", "Уа", "Уа"),
            ("wi_m", "うぃ", "Уи", "Уі", "Уі", "Уи", "Уи"),
            ("we_m", "うぇ", "Уэ", "Уэ", "Уэ", "Уе", "Уэ"),
            ("wo_m", "うぉ", "Уо", "Уо", "Уо", "Уо", "Уо"),
            // クァ行
            ("kwa", "くゎ", "Ква", "Ква", "Ква", "Ква", "Ква"),
            ("kwi", "くぃ", "Куи", "Куі", "Куі", "Куи", "Куи"),
            ("kwe", "くぇ", "Куэ", "Куэ", "Куэ", "Куе", "Куэ"),
            ("kwo", "くぉ", "Куо", "Куо", "Куо", "Куо", "Куо"),
            // グァ行
            ("gwa", "ぐゎ", "Гва", "Гва", "Гва", "Гва", "Гва"),
            ("gwi", "ぐぃ", "Гуи", "Гуі", "Гуі", "Гуи", "Гуи"),
            ("gwe", "ぐぇ", "Гуэ", "Гуэ", "Гуэ", "Гуе", "Гуэ"),
            ("gwo", "ぐぉ", "Гуо", "Гуо", "Гуо", "Гуо", "Гуо"),
            // シェ/ジェ/チェ/ツェ - Use ь (soft sign) to distinguish from regular え row
            ("she", "しぇ", "Сье", "Сье", "Сье", "Сье", "Сје"),
            ("je", "じぇ", "Дзье", "Дзье", "Дзье", "Дзье", "Џе"),
            ("che", "ちぇ", "Чье", "Чье", "Чье", "Чье", "Ће"),
            ("tse", "つぇ", "Цье", "Цье", "Цье", "Цье", "Цје"),
            // ニェ/ヒェ/ミェ/リェ等
            ("nye", "にぇ", "Нье", "Нье", "Нье", "Нье", "Ње"),
            ("hye", "ひぇ", "Хье", "Хье", "Хье", "Хье", "Хје"),
            ("mye", "みぇ", "Мье", "Мье", "Мье", "Мье", "Мје"),
            ("rye", "りぇ", "Рье", "Рье", "Рье", "Рье", "Рје"),
            ("kye", "きぇ", "Кье", "Кье", "Кье", "Кье", "Кје"),
            ("gye", "ぎぇ", "Гье", "Гье", "Гье", "Гье", "Гје"),
            ("bye", "びぇ", "Бье", "Бье", "Бье", "Бье", "Бје"),
            ("pye", "ぴぇ", "Пье", "Пье", "Пье", "Пье", "Пје"),
            // ヴ行 (v sound) - Use Ву prefix to distinguish from В=わ行
            ("va", "ゔぁ", "Вуа", "Вуа", "Вуа", "Въа", "Вуа"),
            ("vi", "ゔぃ", "Вуи", "Вуі", "Вуі", "Въи", "Вуи"),
            ("vu", "ゔ", "Ву", "Ву", "Ву", "Въ", "Ву"),
            ("ve", "ゔぇ", "Вуэ", "Вуэ", "Вуэ", "Въе", "Вуэ"),
            ("vo", "ゔぉ", "Вуо", "Вуо", "Вуо", "Въо", "Вуо"),
            ("vya", "ゔゃ", "Вуя", "Вуя", "Вуя", "Въя", "Вуја"),
            ("vyu", "ゔゅ", "Вую", "Вую", "Вую", "Въю", "Вују"),
            ("vyo", "ゔょ", "Вуё", "Вуё", "Вуё", "Въё", "Вујо"),
            // 小書き仮名 (small kana) - Use ъ (hard sign) prefix
            ("xa", "ぁ", "ъа", "ъа", "ъа", "ъа", "ъа"),
            ("xi", "ぃ", "ъи", "ъі", "ъі", "ъи", "ъи"),
            ("xu", "ぅ", "ъу", "ъу", "ъу", "ъу", "ъу"),
            ("xe", "ぇ", "ъэ", "ъэ", "ъэ", "ъе", "ъэ"),
            ("xo", "ぉ", "ъо", "ъо", "ъо", "ъо", "ъо"),
            ("xya", "ゃ", "ъя", "ъя", "ъя", "ъя", "ъја"),
            ("xyu", "ゅ", "ъю", "ъю", "ъю", "ъю", "ъју"),
            ("xyo", "ょ", "ъё", "ъё", "ъё", "ъё", "ъјо"),
            ("xwa", "ゎ", "ъва", "ъва", "ъўа", "ъва", "ъва"),
            ("xtu", "っ", "ъц", "ъц", "ъц", "ъц", "ъц"),
            ("xka", "ゕ", "ъка", "ъка", "ъка", "ъка", "ъка"),
            ("xke", "ゖ", "ъкэ", "ъкэ", "ъкэ", "ъке", "ъкэ")
        ]

        let specialData = [
            ("n", "ん", "н", "н"),
            ("sokuon", "っ", "ъ", "ъ"), // Analytical mode only? No, standard sokuon is double char
            ("long_vowel", "ー", "ー", "ー") // Placeholder, logic handles vowel repeat
        ]

        // Syllable separators (n + vowel disambiguation)
        // Support both ' (apostrophe) and ъ (hard sign) as separators
        // Example: Gin'iro = гинъиро (銀色)
        let separatorData = [
            // Using apostrophe (')
            ("separator_a_apos", "んあ", "н'а"),
            ("separator_i_apos", "んい", "н'и"),
            ("separator_u_apos", "んう", "н'у"),
            ("separator_e_apos", "んえ", "н'э"),
            ("separator_o_apos", "んお", "н'о"),
            ("separator_ya_apos", "んや", "н'я"),
            ("separator_yu_apos", "んゆ", "н'ю"),
            ("separator_yo_apos", "んよ", "н'ё"),
            // Using hard sign (ъ) - for Russian keyboard users
            ("separator_a_hard", "んあ", "нъа"),
            ("separator_i_hard", "んい", "нъи"),
            ("separator_u_hard", "んう", "нъу"),
            ("separator_e_hard", "んえ", "нъэ"),
            ("separator_o_hard", "んお", "нъо"),
            ("separator_ya_hard", "んや", "нъя"),
            ("separator_yu_hard", "んゆ", "нъю"),
            ("separator_yo_hard", "んよ", "нъё")
        ]

        // Helper to pick column
        // New languages use fallbacks: Macedonian→Serbian, Kazakh/Kyrgyz/Mongolian→Standard
        func pick(_ row: (String, String, String, String, String, String, String)) -> String {
            switch currentProfile {
            case .standard: return row.2
            case .ukrainian: return row.3
            case .belarusian: return row.4
            case .bulgarian: return row.5
            case .serbian: return row.6
            case .macedonian: return row.6  // Fallback to Serbian (similar alphabet)
            case .kazakh: return row.2      // Fallback to Standard Russian
            case .kyrgyz: return row.2      // Fallback to Standard Russian
            case .mongolian: return row.2   // Fallback to Standard Russian
            case .tajik: return row.2       // Fallback to Standard Russian
            case .uzbek: return row.2       // Fallback to Standard Russian
            case .tatar: return row.2       // Fallback to Standard Russian
            case .bashkir: return row.2     // Fallback to Standard Russian
            case .chuvash: return row.2     // Fallback to Standard Russian
            case .sakha: return row.2       // Fallback to Standard Russian
            case .buryat: return row.2      // Fallback to Standard Russian
            case .kalmyk: return row.2      // Fallback to Standard Russian
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

        // Register Youon (拗音)
        for row in youonData {
            let key = pick(row).uppercased()
            let value = row.1
            newMapping[key] = value
        }

        // Register Gairaigo (外来語音)
        for row in gairaigoData {
            let key = pick(row).uppercased()
            let value = row.1
            newMapping[key] = value
        }

        // Register Special (currently unused separators - they are in separatorData now)
        // Note: specialData no longer contains separators

        // Register Separators (both apostrophe and soft sign variants)
        for row in separatorData {
            let key = row.2.uppercased()
            let value = row.1
            newMapping[key] = value
        }

        // ============================================================
        // Alternative mappings for keyboards without Ё and Ъ keys
        // ============================================================
        // йо as alternative for ё (useful when keyboard lacks ё key)
        // These are added AFTER the main mappings so they don't override
        // the primary ё-based mappings (which take precedence in greedy matching)

        // Basic йо → よ (alternative for ё)
        newMapping["ЙО"] = "よ"

        // Compound sounds with йо as alternative for ё
        // きょ行 (kyo-group)
        newMapping["КЙО"] = "きょ"
        // しょ行 (sho-group)
        newMapping["СЙО"] = "しょ"
        // にょ行 (nyo-group)
        newMapping["НЙО"] = "にょ"
        // ひょ行 (hyo-group)
        newMapping["ХЙО"] = "ひょ"
        // みょ行 (myo-group)
        newMapping["МЙО"] = "みょ"
        // りょ行 (ryo-group)
        newMapping["РЙО"] = "りょ"
        // ぎょ行 (gyo-group)
        newMapping["ГЙО"] = "ぎょ"
        // じょ行 (jo-group)
        newMapping["ДЗЙО"] = "じょ"
        // びょ行 (byo-group)
        newMapping["БЙО"] = "びょ"
        // ぴょ行 (pyo-group)
        newMapping["ПЙО"] = "ぴょ"

        // Small ょ using ъ alternative (')
        newMapping["'Ё"] = "ょ"
        newMapping["'ЙО"] = "ょ"

        // Separator alternatives using ' for ъ with йо for ё
        newMapping["Н'ЙО"] = "んよ"

        // ============================================================
        // Alternative mappings for は行「ふ」
        // ============================================================
        // Ху as alternative for Фу (ふ) - more intuitive on Russian keyboard
        newMapping["ХУ"] = "ふ"

        // ============================================================
        // Language-specific character mappings
        // ============================================================

        // Macedonian specific characters
        if currentProfile == .macedonian {
            // Ѓ (Gje) - palatal g, use for ぎゃ行 sounds
            newMapping["Ѓ"] = "ぎ"
            newMapping["ЃА"] = "ぎゃ"
            newMapping["ЃУ"] = "ぎゅ"
            newMapping["ЃО"] = "ぎょ"
            // Ќ (Kje) - palatal k, use for きゃ行 sounds
            newMapping["Ќ"] = "き"
            newMapping["ЌА"] = "きゃ"
            newMapping["ЌУ"] = "きゅ"
            newMapping["ЌО"] = "きょ"
            // Ѕ (Dze) - dz sound
            newMapping["Ѕ"] = "づ"
            newMapping["ЅА"] = "ざ"
            newMapping["ЅИ"] = "じ"
            newMapping["ЅУ"] = "ず"
            newMapping["ЅЕ"] = "ぜ"
            newMapping["ЅО"] = "ぞ"
        }

        // Kazakh specific characters
        if currentProfile == .kazakh {
            // Ә (schwa) - use for え sound
            newMapping["Ә"] = "え"
            // Ғ (voiced h/g) - use for が行
            newMapping["Ғ"] = "が"
            newMapping["ҒА"] = "が"
            newMapping["ҒИ"] = "ぎ"
            newMapping["ҒУ"] = "ぐ"
            newMapping["ҒЕ"] = "げ"
            newMapping["ҒО"] = "ご"
            // Қ (voiceless uvular) - use for か行
            newMapping["Қ"] = "か"
            newMapping["ҚА"] = "か"
            newMapping["ҚИ"] = "き"
            newMapping["ҚУ"] = "く"
            newMapping["ҚЕ"] = "け"
            newMapping["ҚО"] = "こ"
            // Ң (ng) - use for ん before が行
            newMapping["Ң"] = "ん"
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ұ (back u) - use for う
            newMapping["Ұ"] = "う"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
            // І (short i) - use for い
            newMapping["І"] = "い"
        }

        // Kyrgyz specific characters (subset of Kazakh)
        if currentProfile == .kyrgyz {
            newMapping["Ң"] = "ん"
            newMapping["Ү"] = "ゆ"
            newMapping["Ө"] = "お"
        }

        // Mongolian specific characters
        if currentProfile == .mongolian {
            newMapping["Ө"] = "お"
            newMapping["Ү"] = "ゆ"
        }

        // Tajik specific characters (Ғ, Ӣ, Қ, Ӯ, Ҳ, Ҷ)
        if currentProfile == .tajik {
            // Ғ (voiced h/g) - use for が行
            newMapping["Ғ"] = "が"
            newMapping["ҒА"] = "が"
            newMapping["ҒИ"] = "ぎ"
            newMapping["ҒУ"] = "ぐ"
            newMapping["ҒЕ"] = "げ"
            newMapping["ҒО"] = "ご"
            // Ӣ (long i) - use for い
            newMapping["Ӣ"] = "い"
            // Қ (voiceless uvular) - use for か行
            newMapping["Қ"] = "か"
            newMapping["ҚА"] = "か"
            newMapping["ҚИ"] = "き"
            newMapping["ҚУ"] = "く"
            newMapping["ҚЕ"] = "け"
            newMapping["ҚО"] = "こ"
            // Ӯ (long u) - use for う
            newMapping["Ӯ"] = "う"
            // Ҳ (voiceless h) - use for は行
            newMapping["Ҳ"] = "は"
            newMapping["ҲА"] = "は"
            newMapping["ҲИ"] = "ひ"
            newMapping["ҲУ"] = "ふ"
            newMapping["ҲЕ"] = "へ"
            newMapping["ҲО"] = "ほ"
            // Ҷ (voiced j) - use for じゃ行
            newMapping["Ҷ"] = "じ"
            newMapping["ҶА"] = "じゃ"
            newMapping["ҶУ"] = "じゅ"
            newMapping["ҶО"] = "じょ"
        }

        // Uzbek specific characters (Ғ, Қ, Ҳ, Ў)
        if currentProfile == .uzbek {
            // Ғ (voiced h/g) - use for が行
            newMapping["Ғ"] = "が"
            newMapping["ҒА"] = "が"
            newMapping["ҒИ"] = "ぎ"
            newMapping["ҒУ"] = "ぐ"
            newMapping["ҒЕ"] = "げ"
            newMapping["ҒО"] = "ご"
            // Қ (voiceless uvular) - use for か行
            newMapping["Қ"] = "か"
            newMapping["ҚА"] = "か"
            newMapping["ҚИ"] = "き"
            newMapping["ҚУ"] = "く"
            newMapping["ҚЕ"] = "け"
            newMapping["ҚО"] = "こ"
            // Ҳ (voiceless h) - use for は行
            newMapping["Ҳ"] = "は"
            newMapping["ҲА"] = "は"
            newMapping["ҲИ"] = "ひ"
            newMapping["ҲУ"] = "ふ"
            newMapping["ҲЕ"] = "へ"
            newMapping["ҲО"] = "ほ"
            // Ў (w sound) - use for わ行 (similar to Belarusian)
            newMapping["Ў"] = "わ"
            newMapping["ЎА"] = "わ"
            newMapping["ЎИ"] = "ゐ"
            newMapping["ЎЭ"] = "ゑ"
        }

        // Tatar specific characters (Ә, Ө, Ү, Җ, Ң, Һ)
        if currentProfile == .tatar {
            // Ә (front a/schwa) - use for え sound
            newMapping["Ә"] = "え"
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
            // Җ (voiced j/dzh) - use for じゃ行
            newMapping["Җ"] = "じ"
            newMapping["ҖА"] = "じゃ"
            newMapping["ҖИ"] = "じ"
            newMapping["ҖУ"] = "じゅ"
            newMapping["ҖЕ"] = "じぇ"
            newMapping["ҖО"] = "じょ"
            // Ң (ng) - use for ん
            newMapping["Ң"] = "ん"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
        }

        // Bashkir specific characters (Ә, Ө, Ү, Ғ, Ҡ, Ң, Ҙ, Ҫ, Һ)
        if currentProfile == .bashkir {
            // Ә (front a/schwa) - use for え sound
            newMapping["Ә"] = "え"
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
            // Ғ (voiced h/g) - use for が行
            newMapping["Ғ"] = "が"
            newMapping["ҒА"] = "が"
            newMapping["ҒИ"] = "ぎ"
            newMapping["ҒУ"] = "ぐ"
            newMapping["ҒЕ"] = "げ"
            newMapping["ҒО"] = "ご"
            // Ҡ (voiceless uvular) - use for か行
            newMapping["Ҡ"] = "か"
            newMapping["ҠА"] = "か"
            newMapping["ҠИ"] = "き"
            newMapping["ҠУ"] = "く"
            newMapping["ҠЕ"] = "け"
            newMapping["ҠО"] = "こ"
            // Ң (ng) - use for ん
            newMapping["Ң"] = "ん"
            // Ҙ (voiced th/dh) - use for ざ行
            newMapping["Ҙ"] = "ざ"
            newMapping["ҘА"] = "ざ"
            newMapping["ҘИ"] = "じ"
            newMapping["ҘУ"] = "ず"
            newMapping["ҘЕ"] = "ぜ"
            newMapping["ҘО"] = "ぞ"
            // Ҫ (voiceless th) - use for さ行
            newMapping["Ҫ"] = "さ"
            newMapping["ҪА"] = "さ"
            newMapping["ҪИ"] = "し"
            newMapping["ҪУ"] = "す"
            newMapping["ҪЕ"] = "せ"
            newMapping["ҪО"] = "そ"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
        }

        // Chuvash specific characters (Ӑ, Ӗ, Ҫ, Ӳ)
        if currentProfile == .chuvash {
            // Ӑ (reduced a) - use for あ
            newMapping["Ӑ"] = "あ"
            // Ӗ (reduced e) - use for え
            newMapping["Ӗ"] = "え"
            // Ҫ (voiceless sh/s) - use for さ行
            newMapping["Ҫ"] = "さ"
            newMapping["ҪА"] = "さ"
            newMapping["ҪИ"] = "し"
            newMapping["ҪУ"] = "す"
            newMapping["ҪЕ"] = "せ"
            newMapping["ҪО"] = "そ"
            // Ӳ (front u) - use for ゆ
            newMapping["Ӳ"] = "ゆ"
        }

        // Sakha/Yakut specific characters (Ҕ, Һ, Ө, Ү, Ҥ)
        if currentProfile == .sakha {
            // Ҕ (voiced h/gh) - use for が行
            newMapping["Ҕ"] = "が"
            newMapping["ҔА"] = "が"
            newMapping["ҔИ"] = "ぎ"
            newMapping["ҔУ"] = "ぐ"
            newMapping["ҔЕ"] = "げ"
            newMapping["ҔО"] = "ご"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
            // Ҥ (ng) - use for ん
            newMapping["Ҥ"] = "ん"
        }

        // Buryat specific characters (Ө, Ү, Һ)
        if currentProfile == .buryat {
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
        }

        // Kalmyk specific characters (Ә, Һ, Җ, Ң, Ө, Ү)
        if currentProfile == .kalmyk {
            // Ә (front a/schwa) - use for え
            newMapping["Ә"] = "え"
            // Һ (h) - use for は行
            newMapping["Һ"] = "は"
            newMapping["ҺА"] = "は"
            newMapping["ҺИ"] = "ひ"
            newMapping["ҺУ"] = "ふ"
            newMapping["ҺЕ"] = "へ"
            newMapping["ҺО"] = "ほ"
            // Җ (voiced j/dzh) - use for じゃ行
            newMapping["Җ"] = "じ"
            newMapping["ҖА"] = "じゃ"
            newMapping["ҖИ"] = "じ"
            newMapping["ҖУ"] = "じゅ"
            newMapping["ҖЕ"] = "じぇ"
            newMapping["ҖО"] = "じょ"
            // Ң (ng) - use for ん
            newMapping["Ң"] = "ん"
            // Ө (front o) - use for お
            newMapping["Ө"] = "お"
            // Ү (front u) - use for ゆ
            newMapping["Ү"] = "ゆ"
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
