//
//  CyrillicIntegrationTests.swift
//  PismoTests
//
//  Created by Pismo on 2025/11/23.
//

import XCTest
@testable import AzooKeyUtils

// Note: Since we cannot easily instantiate `InputManager` here due to dependencies (Keyboard target),
// we simulate the InputManager's cyrillic interception logic in this integration test.
// This ensures the logic flow works as expected when integrated.

final class CyrillicIntegrationTests: XCTestCase {

    var converter: CyrillicKanaConverter!
    var composingText: String = ""

    override func setUp() {
        super.setUp()
        converter = CyrillicKanaConverter()
        composingText = ""
        print("[\(self.classForCoder)] Integration Test Setup")
    }

    // MARK: - InputManager Simulation

    /// InputManager.input(text: ...) のキリル文字インターセプト部分のロジックを模倣
    func input(_ text: String) {
        print("InputManager: Received input '\(text)'")

        // キリル文字が含まれるかチェック (InputManagerの実装準拠)
        if text.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil {
            let operation = converter.process(input: text, composingText: composingText)

            print("  Converter Operation: delete=\(operation.deleteLast), input='\(operation.input)'")

            // 処理結果が入力と同一で削除もない場合は、ループ防止のためそのまま通す
            if operation.deleteLast == 0 && operation.input == text {
                // Fall through to normal insert
                directInsert(text)
            } else {
                // 削除実行
                if operation.deleteLast > 0 {
                    deleteBackward(count: operation.deleteLast)
                }
                // 再帰呼び出し (InputManager.input)
                // ここでは再帰的にチェックするが、Converterが返すのは通常「かな」か「待機中のキリル文字」
                // 「かな」はキリル文字を含まないので、再帰しても directInsert になるはず
                // 「待機中キリル文字」はキリル文字を含むので、再帰すると無限ループの危険があるが、
                // `operation.input == text` チェックでガードされている。
                input(operation.input)
            }
        } else {
            directInsert(text)
        }
    }

    func directInsert(_ text: String) {
        print("  Direct Insert: '\(text)'")
        composingText += text
        print("  Current Buffer: '\(composingText)'")
    }

    func deleteBackward(count: Int) {
        print("  Delete Backward: \(count)")
        if count > composingText.count {
            composingText = ""
        } else {
            composingText.removeLast(count)
        }
        print("  Current Buffer: '\(composingText)'")
    }

    // MARK: - Scenarios

    func testScenario_Greetings() {
        print("\n=== Scenario: Greetings (Konnichiwa) ===")
        converter.setProfile(.standard)

        // K
        input("К")
        XCTAssertEqual(composingText, "К")

        // o -> Ko -> こ
        input("о") // Lowercase
        XCTAssertEqual(composingText, "こ")

        // n -> こn
        input("н")
        XCTAssertEqual(composingText, "こн") // Wait

        // n -> nn -> こん
        input("н")
        // Logic: "н" + "н" -> "ん" + "н" (Wait)? No, my unit test logic says `н`+`н` -> `ん`+`н`?
        // Let's verify `process` for "н" + "н":
        // Suffix "н". Input "н".
        // Special N rule: last is "н". Next is "н".
        // isVowelOrSign("н") is false.
        // Returns (delete 1, "ん" + "н").
        // So delete "н", insert "んн".
        // Buffer: "こ" -> "こんн"
        XCTAssertEqual(composingText, "こんн")

        // i -> ni -> に
        input("и")
        // Suffix "н". Input "и". Mapping "Ни" -> "に".
        // Returns (delete 1, "に").
        // Buffer: "こん" -> "こんに"
        XCTAssertEqual(composingText, "こんに")

        // ch (ч)
        input("ч")
        XCTAssertEqual(composingText, "こんにч")

        // i (и) -> chi -> ち
        input("и")
        XCTAssertEqual(composingText, "こんにち")

        // w (в)
        input("в")
        XCTAssertEqual(composingText, "こんにちв")

        // a (а) -> wa -> わ
        input("а")
        XCTAssertEqual(composingText, "こんにちは")
    }

    func testScenario_DoubleConsonant_Kitte() {
        print("\n=== Scenario: Double Consonant (Kitte) ===")
        converter.setProfile(.standard)

        // K
        input("К")
        XCTAssertEqual(composingText, "К")

        // i -> Ki -> き
        input("и")
        XCTAssertEqual(composingText, "き")

        // t
        input("т")
        XCTAssertEqual(composingText, "きт")

        // t -> tt -> っt
        input("т")
        // Logic: last "т", input "т".
        // Sokuon rule: (delete 1, "っ" + "т")
        // Buffer: "き" -> "きっт"
        XCTAssertEqual(composingText, "きっт")

        // e -> te -> て
        input("э")
        // Suffix "т". Input "э". Mapping "Тэ" -> "て".
        // (delete 1, "て")
        // Buffer: "きっ" -> "きって"
        XCTAssertEqual(composingText, "きって")
    }

    func testScenario_ProfileSwitch_Ukr() {
        print("\n=== Scenario: Profile Switching (UKR) ===")
        converter.setProfile(.ukrainian)

        // K
        input("К")
        XCTAssertEqual(composingText, "К")

        // I (dotted) -> Ki -> き
        input("і")
        XCTAssertEqual(composingText, "き")
    }

    func testScenario_TypingSpeed_Mixed() {
        print("\n=== Scenario: Rapid Typing Simulation ===")
        // Simulating rapid typing where multiple chars might be buffered if logic was async (it's sync here)
        // Just checking consistent state

        let chars = ["К", "а", "Р", "а"] // KaRa -> から
        for c in chars {
            input(c)
        }
        XCTAssertEqual(composingText, "から")
    }

    // MARK: - New Language Profile Tests

    func testScenario_BelarusianProfile() {
        print("\n=== Scenario: Belarusian Profile ===")
        converter.setProfile(.belarusian)

        // Test basic input - Belarusian uses Ў for わ行
        input("К")
        XCTAssertEqual(composingText, "К")

        input("а")
        XCTAssertEqual(composingText, "か")

        // Reset for next test
        composingText = ""

        // Test vowels
        input("А")
        XCTAssertEqual(composingText, "あ")
    }

    func testScenario_MacedonianProfile() {
        print("\n=== Scenario: Macedonian Profile ===")
        converter.setProfile(.macedonian)

        // Macedonian falls back to Serbian profile
        input("К")
        XCTAssertEqual(composingText, "К")

        input("а")
        XCTAssertEqual(composingText, "か")

        // Reset
        composingText = ""

        // Test basic syllable
        input("С")
        input("а")
        XCTAssertEqual(composingText, "さ")
    }

    func testScenario_KazakhProfile() {
        print("\n=== Scenario: Kazakh Profile ===")
        converter.setProfile(.kazakh)

        // Kazakh falls back to Standard Russian for converter
        input("К")
        XCTAssertEqual(composingText, "К")

        input("а")
        XCTAssertEqual(composingText, "か")

        // Reset
        composingText = ""

        // Test vowel
        input("У")
        XCTAssertEqual(composingText, "う")
    }

    func testScenario_KyrgyzProfile() {
        print("\n=== Scenario: Kyrgyz Profile ===")
        converter.setProfile(.kyrgyz)

        // Kyrgyz falls back to Standard Russian for converter
        input("Н")
        input("А")
        XCTAssertEqual(composingText, "な") // Should be な, NOT んあ

        // Reset
        composingText = ""

        input("Т")
        input("э")
        XCTAssertEqual(composingText, "て")
    }

    func testScenario_MongolianProfile() {
        print("\n=== Scenario: Mongolian Profile ===")
        converter.setProfile(.mongolian)

        // Mongolian falls back to Standard Russian for converter
        input("М")
        input("а")
        XCTAssertEqual(composingText, "ま")

        // Reset
        composingText = ""

        // Test double consonant (sokuon)
        input("К")
        input("и")
        XCTAssertEqual(composingText, "き")

        input("т")
        input("т")
        input("э")
        XCTAssertEqual(composingText, "きって")
    }

    func testScenario_BulgarianProfile() {
        print("\n=== Scenario: Bulgarian Profile ===")
        converter.setProfile(.bulgarian)

        // Bulgarian uses different vowel mappings
        input("К")
        XCTAssertEqual(composingText, "К")

        input("а")
        XCTAssertEqual(composingText, "か")
    }

    func testScenario_SerbianProfile() {
        print("\n=== Scenario: Serbian Profile ===")
        converter.setProfile(.serbian)

        // Serbian uses Ј for Y-sounds
        input("К")
        input("а")
        XCTAssertEqual(composingText, "か")

        // Reset
        composingText = ""

        // Test basic syllable
        input("С")
        input("а")
        XCTAssertEqual(composingText, "さ")
    }
}
