//
//  TestCaseProvider.swift
//  CyrillicIMETests
//
//  Phase 4: Test Infrastructure
//  Provides automated test cases for 560 conversion patterns across all profiles
//

import Foundation

/// Represents a single conversion test case
struct ConversionTestCase: Codable {
    let id: String              // e.g., "RUS-BASIC-001"
    let profileId: String        // e.g., "rus_standard"
    let input: [String]         // Cyrillic key sequence, e.g., ["К", "А"]
    let expected: String        // Expected hiragana output, e.g., "か"
    let category: String        // e.g., "vowel", "consonant", "yoon", "special"
    let description: String     // Human-readable description

    enum CodingKeys: String, CodingKey {
        case id, profileId = "profile_id", input, expected, category, description
    }
}

/// Provides test cases for automated conversion testing
class TestCaseProvider {

    static let shared = TestCaseProvider()

    private var testCases: [ConversionTestCase] = []
    private var testCasesByProfile: [String: [ConversionTestCase]] = [:]

    private init() {
        loadTestCases()
    }

    /// Load test cases from JSON file or generate programmatically
    private func loadTestCases() {
        // Try to load from JSON first
        if let jsonCases = loadFromJSON() {
            testCases = jsonCases
        } else {
            // Generate test cases programmatically
            testCases = generateTestCases()
        }

        // Index by profile
        for testCase in testCases {
            if testCasesByProfile[testCase.profileId] == nil {
                testCasesByProfile[testCase.profileId] = []
            }
            testCasesByProfile[testCase.profileId]?.append(testCase)
        }

        print("[TestCaseProvider] Loaded \(testCases.count) test cases")
        for (profileId, cases) in testCasesByProfile {
            print("  - \(profileId): \(cases.count) test cases")
        }
    }

    /// Load test cases from JSON file
    private func loadFromJSON() -> [ConversionTestCase]? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "test_cases", withExtension: "json") else {
            print("[TestCaseProvider] test_cases.json not found, will generate programmatically")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let cases = try decoder.decode([ConversionTestCase].self, from: data)
            return cases
        } catch {
            print("[TestCaseProvider] Failed to load test_cases.json: \(error)")
            return nil
        }
    }

    /// Generate test cases programmatically based on テスト仕様書.md
    private func generateTestCases() -> [ConversionTestCase] {
        var cases: [ConversionTestCase] = []

        // Russian Standard Profile
        cases.append(contentsOf: generateRussianStandardCases())

        // Other profiles (to be implemented in Phase 1)
        // cases.append(contentsOf: generateSerbianCases())
        // cases.append(contentsOf: generateUkrainianCases())
        // cases.append(contentsOf: generateBulgarianCases())
        // cases.append(contentsOf: generateRussianAnalyticalCases())

        return cases
    }

    /// Generate Russian Standard test cases (112 cases)
    private func generateRussianStandardCases() -> [ConversionTestCase] {
        var cases: [ConversionTestCase] = []

        // 2.1.1 清音（50音）- RUS-BASIC-001 to RUS-BASIC-043
        cases.append(contentsOf: generateRussianBasicCases())

        // 2.1.2 濁音・半濁音 - RUS-VOICE-001 to RUS-SEMI-005
        cases.append(contentsOf: generateRussianVoicedCases())

        // 2.1.3 拗音 - RUS-YO-001 to RUS-YO-033
        cases.append(contentsOf: generateRussianYoonCases())

        // 2.1.4 特殊ケース - RUS-SPEC-001 to RUS-SPEC-010
        cases.append(contentsOf: generateRussianSpecialCases())

        return cases
    }

    /// Generate basic syllable cases (RUS-BASIC-001 to RUS-BASIC-043)
    private func generateRussianBasicCases() -> [ConversionTestCase] {
        return [
            // Vowels
            ConversionTestCase(id: "RUS-BASIC-001", profileId: "rus_standard", input: ["А"], expected: "あ", category: "vowel", description: "А → あ (vowel a)"),
            ConversionTestCase(id: "RUS-BASIC-002", profileId: "rus_standard", input: ["И"], expected: "い", category: "vowel", description: "И → い (vowel i)"),
            ConversionTestCase(id: "RUS-BASIC-003", profileId: "rus_standard", input: ["У"], expected: "う", category: "vowel", description: "У → う (vowel u)"),
            ConversionTestCase(id: "RUS-BASIC-004", profileId: "rus_standard", input: ["Э"], expected: "え", category: "vowel", description: "Э → え (vowel e)"),
            ConversionTestCase(id: "RUS-BASIC-005", profileId: "rus_standard", input: ["О"], expected: "お", category: "vowel", description: "О → お (vowel o)"),

            // K row
            ConversionTestCase(id: "RUS-BASIC-006", profileId: "rus_standard", input: ["К", "А"], expected: "か", category: "consonant", description: "КА → か (ka)"),
            ConversionTestCase(id: "RUS-BASIC-007", profileId: "rus_standard", input: ["К", "И"], expected: "き", category: "consonant", description: "КИ → き (ki)"),
            ConversionTestCase(id: "RUS-BASIC-008", profileId: "rus_standard", input: ["К", "У"], expected: "く", category: "consonant", description: "КУ → く (ku)"),
            ConversionTestCase(id: "RUS-BASIC-009", profileId: "rus_standard", input: ["К", "Э"], expected: "け", category: "consonant", description: "КЭ → け (ke)"),
            ConversionTestCase(id: "RUS-BASIC-010", profileId: "rus_standard", input: ["К", "О"], expected: "こ", category: "consonant", description: "КО → こ (ko)"),

            // S row
            ConversionTestCase(id: "RUS-BASIC-011", profileId: "rus_standard", input: ["С", "А"], expected: "さ", category: "consonant", description: "СА → さ (sa)"),
            ConversionTestCase(id: "RUS-BASIC-012", profileId: "rus_standard", input: ["С", "И"], expected: "し", category: "consonant", description: "СИ → し (shi)"),
            ConversionTestCase(id: "RUS-BASIC-013", profileId: "rus_standard", input: ["С", "У"], expected: "す", category: "consonant", description: "СУ → す (su)"),
            ConversionTestCase(id: "RUS-BASIC-014", profileId: "rus_standard", input: ["С", "Э"], expected: "せ", category: "consonant", description: "СЭ → せ (se)"),
            ConversionTestCase(id: "RUS-BASIC-015", profileId: "rus_standard", input: ["С", "О"], expected: "そ", category: "consonant", description: "СО → そ (so)"),

            // T row
            ConversionTestCase(id: "RUS-BASIC-016", profileId: "rus_standard", input: ["Т", "А"], expected: "た", category: "consonant", description: "ТА → た (ta)"),
            ConversionTestCase(id: "RUS-BASIC-017", profileId: "rus_standard", input: ["Ч", "И"], expected: "ち", category: "consonant", description: "ЧИ → ち (chi)"),
            ConversionTestCase(id: "RUS-BASIC-018", profileId: "rus_standard", input: ["Ц", "У"], expected: "つ", category: "consonant", description: "ЦУ → つ (tsu)"),
            ConversionTestCase(id: "RUS-BASIC-019", profileId: "rus_standard", input: ["Т", "Э"], expected: "て", category: "consonant", description: "ТЭ → て (te)"),
            ConversionTestCase(id: "RUS-BASIC-020", profileId: "rus_standard", input: ["Т", "О"], expected: "と", category: "consonant", description: "ТО → と (to)"),

            // N row
            ConversionTestCase(id: "RUS-BASIC-021", profileId: "rus_standard", input: ["Н", "А"], expected: "な", category: "consonant", description: "НА → な (na)"),
            ConversionTestCase(id: "RUS-BASIC-022", profileId: "rus_standard", input: ["Н", "И"], expected: "に", category: "consonant", description: "НИ → に (ni)"),
            ConversionTestCase(id: "RUS-BASIC-023", profileId: "rus_standard", input: ["Н", "У"], expected: "ぬ", category: "consonant", description: "НУ → ぬ (nu)"),
            ConversionTestCase(id: "RUS-BASIC-024", profileId: "rus_standard", input: ["Н", "Э"], expected: "ね", category: "consonant", description: "НЭ → ね (ne)"),
            ConversionTestCase(id: "RUS-BASIC-025", profileId: "rus_standard", input: ["Н", "О"], expected: "の", category: "consonant", description: "НО → の (no)"),

            // H row
            ConversionTestCase(id: "RUS-BASIC-026", profileId: "rus_standard", input: ["Х", "А"], expected: "は", category: "consonant", description: "ХА → は (ha)"),
            ConversionTestCase(id: "RUS-BASIC-027", profileId: "rus_standard", input: ["Х", "И"], expected: "ひ", category: "consonant", description: "ХИ → ひ (hi)"),
            ConversionTestCase(id: "RUS-BASIC-028", profileId: "rus_standard", input: ["Ф", "У"], expected: "ふ", category: "consonant", description: "ФУ → ふ (fu)"),
            ConversionTestCase(id: "RUS-BASIC-029", profileId: "rus_standard", input: ["Х", "Э"], expected: "へ", category: "consonant", description: "ХЭ → へ (he)"),
            ConversionTestCase(id: "RUS-BASIC-030", profileId: "rus_standard", input: ["Х", "О"], expected: "ほ", category: "consonant", description: "ХО → ほ (ho)"),

            // M row
            ConversionTestCase(id: "RUS-BASIC-031", profileId: "rus_standard", input: ["М", "А"], expected: "ま", category: "consonant", description: "МА → ま (ma)"),
            ConversionTestCase(id: "RUS-BASIC-032", profileId: "rus_standard", input: ["М", "И"], expected: "み", category: "consonant", description: "МИ → み (mi)"),
            ConversionTestCase(id: "RUS-BASIC-033", profileId: "rus_standard", input: ["М", "У"], expected: "む", category: "consonant", description: "МУ → む (mu)"),
            ConversionTestCase(id: "RUS-BASIC-034", profileId: "rus_standard", input: ["М", "Э"], expected: "め", category: "consonant", description: "МЭ → め (me)"),
            ConversionTestCase(id: "RUS-BASIC-035", profileId: "rus_standard", input: ["М", "О"], expected: "も", category: "consonant", description: "МО → も (mo)"),

            // R row
            ConversionTestCase(id: "RUS-BASIC-036", profileId: "rus_standard", input: ["Р", "А"], expected: "ら", category: "consonant", description: "РА → ら (ra)"),
            ConversionTestCase(id: "RUS-BASIC-037", profileId: "rus_standard", input: ["Р", "И"], expected: "り", category: "consonant", description: "РИ → り (ri)"),
            ConversionTestCase(id: "RUS-BASIC-038", profileId: "rus_standard", input: ["Р", "У"], expected: "る", category: "consonant", description: "РУ → る (ru)"),
            ConversionTestCase(id: "RUS-BASIC-039", profileId: "rus_standard", input: ["Р", "Э"], expected: "れ", category: "consonant", description: "РЭ → れ (re)"),
            ConversionTestCase(id: "RUS-BASIC-040", profileId: "rus_standard", input: ["Р", "О"], expected: "ろ", category: "consonant", description: "РО → ろ (ro)"),

            // W row and N
            ConversionTestCase(id: "RUS-BASIC-041", profileId: "rus_standard", input: ["В", "А"], expected: "わ", category: "consonant", description: "ВА → わ (wa)"),
            ConversionTestCase(id: "RUS-BASIC-042", profileId: "rus_standard", input: ["В", "О"], expected: "を", category: "consonant", description: "ВО → を (wo)"),
            ConversionTestCase(id: "RUS-BASIC-043", profileId: "rus_standard", input: ["Н"], expected: "ん", category: "special", description: "Н → ん (standalone n)"),
        ]
    }

    /// Generate voiced consonant cases (RUS-VOICE-001 to RUS-SEMI-005)
    private func generateRussianVoicedCases() -> [ConversionTestCase] {
        return [
            // G row (voiced K)
            ConversionTestCase(id: "RUS-VOICE-001", profileId: "rus_standard", input: ["Г", "А"], expected: "が", category: "voiced", description: "ГА → が (ga)"),
            ConversionTestCase(id: "RUS-VOICE-002", profileId: "rus_standard", input: ["Г", "И"], expected: "ぎ", category: "voiced", description: "ГИ → ぎ (gi)"),
            ConversionTestCase(id: "RUS-VOICE-003", profileId: "rus_standard", input: ["Г", "У"], expected: "ぐ", category: "voiced", description: "ГУ → ぐ (gu)"),
            ConversionTestCase(id: "RUS-VOICE-004", profileId: "rus_standard", input: ["Г", "Э"], expected: "げ", category: "voiced", description: "ГЭ → げ (ge)"),
            ConversionTestCase(id: "RUS-VOICE-005", profileId: "rus_standard", input: ["Г", "О"], expected: "ご", category: "voiced", description: "ГО → ご (go)"),

            // Z row (voiced S)
            ConversionTestCase(id: "RUS-VOICE-006", profileId: "rus_standard", input: ["З", "А"], expected: "ざ", category: "voiced", description: "ЗА → ざ (za)"),
            ConversionTestCase(id: "RUS-VOICE-007", profileId: "rus_standard", input: ["З", "И"], expected: "じ", category: "voiced", description: "ЗИ → じ (ji)"),
            ConversionTestCase(id: "RUS-VOICE-008", profileId: "rus_standard", input: ["З", "У"], expected: "ず", category: "voiced", description: "ЗУ → ず (zu)"),
            ConversionTestCase(id: "RUS-VOICE-009", profileId: "rus_standard", input: ["З", "Э"], expected: "ぜ", category: "voiced", description: "ЗЭ → ぜ (ze)"),
            ConversionTestCase(id: "RUS-VOICE-010", profileId: "rus_standard", input: ["З", "О"], expected: "ぞ", category: "voiced", description: "ЗО → ぞ (zo)"),

            // D row (voiced T)
            ConversionTestCase(id: "RUS-VOICE-011", profileId: "rus_standard", input: ["Д", "А"], expected: "だ", category: "voiced", description: "ДА → だ (da)"),
            ConversionTestCase(id: "RUS-VOICE-012", profileId: "rus_standard", input: ["Д", "И"], expected: "ぢ", category: "voiced", description: "ДИ → ぢ (di/ji)"),
            ConversionTestCase(id: "RUS-VOICE-013", profileId: "rus_standard", input: ["Д", "У"], expected: "づ", category: "voiced", description: "ДУ → づ (du/zu)"),
            ConversionTestCase(id: "RUS-VOICE-014", profileId: "rus_standard", input: ["Д", "Э"], expected: "で", category: "voiced", description: "ДЭ → で (de)"),
            ConversionTestCase(id: "RUS-VOICE-015", profileId: "rus_standard", input: ["Д", "О"], expected: "ど", category: "voiced", description: "ДО → ど (do)"),

            // B row (voiced H)
            ConversionTestCase(id: "RUS-VOICE-016", profileId: "rus_standard", input: ["Б", "А"], expected: "ば", category: "voiced", description: "БА → ば (ba)"),
            ConversionTestCase(id: "RUS-VOICE-017", profileId: "rus_standard", input: ["Б", "И"], expected: "び", category: "voiced", description: "БИ → び (bi)"),
            ConversionTestCase(id: "RUS-VOICE-018", profileId: "rus_standard", input: ["Б", "У"], expected: "ぶ", category: "voiced", description: "БУ → ぶ (bu)"),
            ConversionTestCase(id: "RUS-VOICE-019", profileId: "rus_standard", input: ["Б", "Э"], expected: "べ", category: "voiced", description: "БЭ → べ (be)"),
            ConversionTestCase(id: "RUS-VOICE-020", profileId: "rus_standard", input: ["Б", "О"], expected: "ぼ", category: "voiced", description: "БО → ぼ (bo)"),

            // P row (semi-voiced H)
            ConversionTestCase(id: "RUS-SEMI-001", profileId: "rus_standard", input: ["П", "А"], expected: "ぱ", category: "semi-voiced", description: "ПА → ぱ (pa)"),
            ConversionTestCase(id: "RUS-SEMI-002", profileId: "rus_standard", input: ["П", "И"], expected: "ぴ", category: "semi-voiced", description: "ПИ → ぴ (pi)"),
            ConversionTestCase(id: "RUS-SEMI-003", profileId: "rus_standard", input: ["П", "У"], expected: "ぷ", category: "semi-voiced", description: "ПУ → ぷ (pu)"),
            ConversionTestCase(id: "RUS-SEMI-004", profileId: "rus_standard", input: ["П", "Э"], expected: "ぺ", category: "semi-voiced", description: "ПЭ → ぺ (pe)"),
            ConversionTestCase(id: "RUS-SEMI-005", profileId: "rus_standard", input: ["П", "О"], expected: "ぽ", category: "semi-voiced", description: "ПО → ぽ (po)"),
        ]
    }

    /// Generate yoon cases (RUS-YO-001 to RUS-YO-033)
    private func generateRussianYoonCases() -> [ConversionTestCase] {
        return [
            // K row yoon
            ConversionTestCase(id: "RUS-YO-001", profileId: "rus_standard", input: ["К", "Я"], expected: "きゃ", category: "yoon", description: "КЯ → きゃ (kya)"),
            ConversionTestCase(id: "RUS-YO-002", profileId: "rus_standard", input: ["К", "Ю"], expected: "きゅ", category: "yoon", description: "КЮ → きゅ (kyu)"),
            ConversionTestCase(id: "RUS-YO-003", profileId: "rus_standard", input: ["К", "Ё"], expected: "きょ", category: "yoon", description: "КЁ → きょ (kyo)"),

            // S row yoon
            ConversionTestCase(id: "RUS-YO-004", profileId: "rus_standard", input: ["С", "Я"], expected: "しゃ", category: "yoon", description: "СЯ → しゃ (sha)"),
            ConversionTestCase(id: "RUS-YO-005", profileId: "rus_standard", input: ["С", "Ю"], expected: "しゅ", category: "yoon", description: "СЮ → しゅ (shu)"),
            ConversionTestCase(id: "RUS-YO-006", profileId: "rus_standard", input: ["С", "Ё"], expected: "しょ", category: "yoon", description: "СЁ → しょ (sho)"),

            // Ch row yoon
            ConversionTestCase(id: "RUS-YO-007", profileId: "rus_standard", input: ["Ч", "Я"], expected: "ちゃ", category: "yoon", description: "ЧЯ → ちゃ (cha)"),
            ConversionTestCase(id: "RUS-YO-008", profileId: "rus_standard", input: ["Ч", "Ю"], expected: "ちゅ", category: "yoon", description: "ЧЮ → ちゅ (chu)"),
            ConversionTestCase(id: "RUS-YO-009", profileId: "rus_standard", input: ["Ч", "Ё"], expected: "ちょ", category: "yoon", description: "ЧЁ → ちょ (cho)"),

            // N row yoon
            ConversionTestCase(id: "RUS-YO-010", profileId: "rus_standard", input: ["Н", "Я"], expected: "にゃ", category: "yoon", description: "НЯ → にゃ (nya)"),
            ConversionTestCase(id: "RUS-YO-011", profileId: "rus_standard", input: ["Н", "Ю"], expected: "にゅ", category: "yoon", description: "НЮ → にゅ (nyu)"),
            ConversionTestCase(id: "RUS-YO-012", profileId: "rus_standard", input: ["Н", "Ё"], expected: "にょ", category: "yoon", description: "НЁ → にょ (nyo)"),

            // H row yoon
            ConversionTestCase(id: "RUS-YO-013", profileId: "rus_standard", input: ["Х", "Я"], expected: "ひゃ", category: "yoon", description: "ХЯ → ひゃ (hya)"),
            ConversionTestCase(id: "RUS-YO-014", profileId: "rus_standard", input: ["Х", "Ю"], expected: "ひゅ", category: "yoon", description: "ХЮ → ひゅ (hyu)"),
            ConversionTestCase(id: "RUS-YO-015", profileId: "rus_standard", input: ["Х", "Ё"], expected: "ひょ", category: "yoon", description: "ХЁ → ひょ (hyo)"),

            // M row yoon
            ConversionTestCase(id: "RUS-YO-016", profileId: "rus_standard", input: ["М", "Я"], expected: "みゃ", category: "yoon", description: "МЯ → みゃ (mya)"),
            ConversionTestCase(id: "RUS-YO-017", profileId: "rus_standard", input: ["М", "Ю"], expected: "みゅ", category: "yoon", description: "МЮ → みゅ (myu)"),
            ConversionTestCase(id: "RUS-YO-018", profileId: "rus_standard", input: ["М", "Ё"], expected: "みょ", category: "yoon", description: "МЁ → みょ (myo)"),

            // R row yoon
            ConversionTestCase(id: "RUS-YO-019", profileId: "rus_standard", input: ["Р", "Я"], expected: "りゃ", category: "yoon", description: "РЯ → りゃ (rya)"),
            ConversionTestCase(id: "RUS-YO-020", profileId: "rus_standard", input: ["Р", "Ю"], expected: "りゅ", category: "yoon", description: "РЮ → りゅ (ryu)"),
            ConversionTestCase(id: "RUS-YO-021", profileId: "rus_standard", input: ["Р", "Ё"], expected: "りょ", category: "yoon", description: "РЁ → りょ (ryo)"),

            // G row yoon (voiced)
            ConversionTestCase(id: "RUS-YO-022", profileId: "rus_standard", input: ["Г", "Я"], expected: "ぎゃ", category: "yoon", description: "ГЯ → ぎゃ (gya)"),
            ConversionTestCase(id: "RUS-YO-023", profileId: "rus_standard", input: ["Г", "Ю"], expected: "ぎゅ", category: "yoon", description: "ГЮ → ぎゅ (gyu)"),
            ConversionTestCase(id: "RUS-YO-024", profileId: "rus_standard", input: ["Г", "Ё"], expected: "ぎょ", category: "yoon", description: "ГЁ → ぎょ (gyo)"),

            // Z row yoon (voiced)
            ConversionTestCase(id: "RUS-YO-025", profileId: "rus_standard", input: ["З", "Я"], expected: "じゃ", category: "yoon", description: "ЗЯ → じゃ (ja)"),
            ConversionTestCase(id: "RUS-YO-026", profileId: "rus_standard", input: ["З", "Ю"], expected: "じゅ", category: "yoon", description: "ЗЮ → じゅ (ju)"),
            ConversionTestCase(id: "RUS-YO-027", profileId: "rus_standard", input: ["З", "Ё"], expected: "じょ", category: "yoon", description: "ЗЁ → じょ (jo)"),

            // B row yoon (voiced)
            ConversionTestCase(id: "RUS-YO-028", profileId: "rus_standard", input: ["Б", "Я"], expected: "びゃ", category: "yoon", description: "БЯ → びゃ (bya)"),
            ConversionTestCase(id: "RUS-YO-029", profileId: "rus_standard", input: ["Б", "Ю"], expected: "びゅ", category: "yoon", description: "БЮ → びゅ (byu)"),
            ConversionTestCase(id: "RUS-YO-030", profileId: "rus_standard", input: ["Б", "Ё"], expected: "びょ", category: "yoon", description: "БЁ → びょ (byo)"),

            // P row yoon (semi-voiced)
            ConversionTestCase(id: "RUS-YO-031", profileId: "rus_standard", input: ["П", "Я"], expected: "ぴゃ", category: "yoon", description: "ПЯ → ぴゃ (pya)"),
            ConversionTestCase(id: "RUS-YO-032", profileId: "rus_standard", input: ["П", "Ю"], expected: "ぴゅ", category: "yoon", description: "ПЮ → ぴゅ (pyu)"),
            ConversionTestCase(id: "RUS-YO-033", profileId: "rus_standard", input: ["П", "Ё"], expected: "ぴょ", category: "yoon", description: "ПЁ → ぴょ (pyo)"),
        ]
    }

    /// Generate special cases (RUS-SPEC-001 to RUS-SPEC-010)
    private func generateRussianSpecialCases() -> [ConversionTestCase] {
        return [
            // Sokuon (促音) - doubled consonants
            ConversionTestCase(id: "RUS-SPEC-001", profileId: "rus_standard", input: ["К", "К", "А"], expected: "っか", category: "sokuon", description: "ККА → っか (sokuon + ka)"),
            ConversionTestCase(id: "RUS-SPEC-002", profileId: "rus_standard", input: ["С", "С", "И"], expected: "っし", category: "sokuon", description: "ССИ → っし (sokuon + shi)"),
            ConversionTestCase(id: "RUS-SPEC-003", profileId: "rus_standard", input: ["Ц", "Ц", "У"], expected: "っつ", category: "sokuon", description: "ЦЦУ → っつ (sokuon + tsu)"),

            // Long vowels (長音)
            ConversionTestCase(id: "RUS-SPEC-004", profileId: "rus_standard", input: ["Т", "О", "О", "К", "Я", "О", "О"], expected: "とーきょー", category: "long-vowel", description: "ТООKЯОО → とーきょー (Tokyo)"),
            ConversionTestCase(id: "RUS-SPEC-005", profileId: "rus_standard", input: ["О", "О", "С", "А", "К", "А"], expected: "おおさか", category: "long-vowel", description: "ООCАKА → おおさか (Osaka)"),

            // Syllable separation (音節分離)
            ConversionTestCase(id: "RUS-SPEC-006", profileId: "rus_standard", input: ["Н", "'", "А"], expected: "んあ", category: "separation", description: "Н'А → んあ (n + a with separator)"),
            ConversionTestCase(id: "RUS-SPEC-007", profileId: "rus_standard", input: ["Н", "Ъ", "А"], expected: "んあ", category: "separation", description: "НЪА → んあ (n + a with hard sign)"),
            ConversionTestCase(id: "RUS-SPEC-008", profileId: "rus_standard", input: ["С", "А", "Н", "'", "И", "Н"], expected: "さんいん", category: "separation", description: "САН'ИН → さんいん (san'in region)"),

            // N combinations
            ConversionTestCase(id: "RUS-SPEC-009", profileId: "rus_standard", input: ["К", "А", "Н", "Д", "А", "Н"], expected: "かんだん", category: "n-combinations", description: "КАНДАН → かんだん (n + d)"),
            ConversionTestCase(id: "RUS-SPEC-010", profileId: "rus_standard", input: ["Н"], expected: "ん", category: "standalone-n", description: "Н → ん (standalone)"),
        ]
    }

    // MARK: - Public API

    /// Get all test cases
    func getAllTestCases() -> [ConversionTestCase] {
        return testCases
    }

    /// Get test cases for a specific profile
    func getTestCases(for profileId: String) -> [ConversionTestCase] {
        return testCasesByProfile[profileId] ?? []
    }

    /// Get test cases by category
    func getTestCases(for profileId: String, category: String) -> [ConversionTestCase] {
        return getTestCases(for: profileId).filter { $0.category == category }
    }

    /// Get available profile IDs
    func getAvailableProfiles() -> [String] {
        return Array(testCasesByProfile.keys).sorted()
    }
}
