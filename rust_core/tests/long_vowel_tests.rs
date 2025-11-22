/// Tests for consecutive long vowel detection (Phase 3: Bug Fixes)
/// Test case: ТОКЁОО → とーきょーー
use cyrillic_ime_core::IMEEngine;

const TEST_PROFILES: &str = r#"[{
    "id": "rus_test",
    "name_ja": "テスト",
    "name_en": "Test",
    "keyboardLayout": ["Т", "О", "К", "Я"],
    "inputSchemaId": "schema_rus_test"
}]"#;

const TEST_KANA_ENGINE: &str = r#"{
    "to": "と",
    "kyo": "きょ",
    "sokuon": "っ"
}"#;

const TEST_SCHEMA_RUS: &str = r#"{
    "Т": {"kana_key": "to"},
    "ТО": {"kana_key": "to"},
    "КЯ": {"kana_key": "kya"},
    "КЁ": {"kana_key": "kyo"},
    "О": {"kana_key": "o"}
}"#;

#[test]
fn test_single_long_vowel() {
    // Initialize engine
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // First: Т → と (last_output="と", last_vowel_type="o")
    let result1 = IMEEngine::process_key("Т", "", "rus_test", "", &None);
    assert!(result1.is_ok());
    let conv1 = result1.unwrap();
    assert_eq!(conv1.output, "と");
    assert_eq!(conv1.last_vowel_type, Some("o".to_string()));

    // Second: О → ー (extends previous "と")
    let result2 = IMEEngine::process_key("О", "", "rus_test", "と", &Some("o".to_string()));
    assert!(result2.is_ok());
    let conv2 = result2.unwrap();
    assert_eq!(conv2.output, "ー");
    assert_eq!(conv2.last_vowel_type, Some("o".to_string()), "Long vowel should preserve vowel type");
}

#[test]
fn test_consecutive_long_vowels() {
    // Test case: ТОКЁОО → とーきょーー
    // This is the main bug we're fixing
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Simulate the sequence: Т-О-К-Ё-О-О

    // Step 1: Т → と
    let r1 = IMEEngine::process_key("Т", "", "rus_test", "", &None).unwrap();
    assert_eq!(r1.output, "と");
    let last_output_1 = r1.last_output.clone();
    let last_vowel_1 = r1.last_vowel_type.clone();

    // Step 2: О → ー (first long vowel)
    let r2 = IMEEngine::process_key("О", "", "rus_test", &last_output_1, &last_vowel_1).unwrap();
    assert_eq!(r2.output, "ー");
    assert_eq!(r2.last_vowel_type, Some("o".to_string()));
    let last_output_2 = r2.last_output.clone();
    let last_vowel_2 = r2.last_vowel_type.clone();

    // Step 3: К (composing)
    let r3 = IMEEngine::process_key("К", "", "rus_test", &last_output_2, &last_vowel_2).unwrap();
    // К should be composing (waiting for next character)
    assert_eq!(r3.action, "composing");
    assert_eq!(r3.buffer, "К");

    // Step 4: КЁ → きょ
    let r4 = IMEEngine::process_key("Ё", "К", "rus_test", &last_output_2, &last_vowel_2).unwrap();
    assert_eq!(r4.output, "きょ");
    assert_eq!(r4.last_vowel_type, Some("o".to_string()));
    let last_output_4 = r4.last_output.clone();
    let last_vowel_4 = r4.last_vowel_type.clone();

    // Step 5: О → ー (second long vowel)
    let r5 = IMEEngine::process_key("О", "", "rus_test", &last_output_4, &last_vowel_4).unwrap();
    assert_eq!(r5.output, "ー");
    assert_eq!(r5.last_vowel_type, Some("o".to_string()));
    let last_output_5 = r5.last_output.clone();
    let last_vowel_5 = r5.last_vowel_type.clone();

    // Step 6: О → ー (third long vowel - THE BUG FIX!)
    // This is the case that was failing before: "ー" + О
    // The bug was that last_vowel_type was not preserved through "ー"
    let r6 = IMEEngine::process_key("О", "", "rus_test", &last_output_5, &last_vowel_5).unwrap();
    assert_eq!(r6.output, "ー", "Consecutive long vowel after ー should work!");
    assert_eq!(r6.last_vowel_type, Some("o".to_string()));
}

#[test]
fn test_long_vowel_type_preservation_through_chouon() {
    // Verify that vowel type is correctly preserved through multiple ー characters
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Start with と (vowel type: "o")
    let r1 = IMEEngine::process_key("Т", "", "rus_test", "", &None).unwrap();
    assert_eq!(r1.last_vowel_type, Some("o".to_string()));

    // First ー should inherit "o"
    let r2 = IMEEngine::process_key("О", "", "rus_test", &r1.last_output, &r1.last_vowel_type).unwrap();
    assert_eq!(r2.output, "ー");
    assert_eq!(r2.last_output, "ー");
    assert_eq!(r2.last_vowel_type, Some("o".to_string()), "First ー should have vowel type 'o'");

    // Second ー should also inherit "o" from the first ー
    let r3 = IMEEngine::process_key("О", "", "rus_test", &r2.last_output, &r2.last_vowel_type).unwrap();
    assert_eq!(r3.output, "ー");
    assert_eq!(r3.last_output, "ー");
    assert_eq!(r3.last_vowel_type, Some("o".to_string()), "Second ー should also have vowel type 'o'");

    // Third ー should continue to work
    let r4 = IMEEngine::process_key("О", "", "rus_test", &r3.last_output, &r3.last_vowel_type).unwrap();
    assert_eq!(r4.output, "ー");
    assert_eq!(r4.last_vowel_type, Some("o".to_string()), "Third ー should also have vowel type 'o'");
}
