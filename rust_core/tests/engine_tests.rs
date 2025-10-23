use cyrillic_ime_core::IMEEngine;
extern crate cyrillic_ime_core;

/// Test data: minimal profiles.json
const TEST_PROFILES: &str = r#"[
    {
        "id": "rus_standard",
        "name_ja": "ロシア語 (標準)",
        "name_en": "Russian (Standard)",
        "keyboardLayout": ["А", "И", "У", "К", "Я"],
        "inputSchemaId": "schema_rus_v1"
    },
    {
        "id": "srb_cyrillic",
        "name_ja": "セルビア語",
        "name_en": "Serbian",
        "keyboardLayout": ["А", "И", "У", "К", "Ј", "Ћ"],
        "inputSchemaId": "schema_srb_v1"
    }
]"#;

/// Test data: minimal kana engine
const TEST_KANA_ENGINE: &str = r#"{
    "a": "あ",
    "i": "い",
    "u": "う",
    "ka": "か",
    "ki": "き",
    "kya": "きゃ",
    "chi": "ち"
}"#;

/// Test data: Russian schema (minimal)
const TEST_SCHEMA_RUS: &str = r#"{
    "А": { "kana_key": "a" },
    "И": { "kana_key": "i" },
    "У": { "kana_key": "u" },
    "КА": { "kana_key": "ka" },
    "КИ": { "kana_key": "ki" },
    "КЯ": { "kana_key": "kya" }
}"#;

/// Test data: Serbian schema (minimal)
const TEST_SCHEMA_SRB: &str = r#"{
    "А": { "kana_key": "a" },
    "И": { "kana_key": "i" },
    "У": { "kana_key": "u" },
    "КА": { "kana_key": "ka" },
    "КИ": { "kana_key": "ki" },
    "КЈА": { "kana_key": "kya" },
    "Ћ": { "kana_key": "chi" }
}"#;

#[test]
fn test_engine_initialization() {
    let result = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    assert!(result.is_ok(), "Engine initialization should succeed");

    let profiles = IMEEngine::get_profiles();
    assert!(profiles.is_ok(), "Should be able to get profiles");

    let profiles = profiles.unwrap();
    assert_eq!(profiles.len(), 2, "Should have 2 profiles");
    assert_eq!(profiles[0].id, "rus_standard");
    assert_eq!(profiles[1].id, "srb_cyrillic");
}

#[test]
fn test_schema_loading() {
    // Initialize engine first
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    // Load Russian schema
    let result = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_v1");
    assert!(result.is_ok(), "Russian schema loading should succeed");

    // Load Serbian schema
    let result = IMEEngine::load_schema(TEST_SCHEMA_SRB, "schema_srb_v1");
    assert!(result.is_ok(), "Serbian schema loading should succeed");
}

#[test]
fn test_single_character_conversion_russian() {
    // Initialize and load schema
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_v1");

    // Test: А -> あ
    let result = IMEEngine::process_key("А", "", "rus_standard");
    assert!(result.is_ok());

    let conv_result = result.unwrap();
    assert_eq!(conv_result.output, "あ");
    assert_eq!(conv_result.buffer, "");
    assert_eq!(conv_result.action, "commit");
}

#[test]
fn test_multi_character_conversion_russian() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_v1");

    // Test: К (composing)
    let result = IMEEngine::process_key("К", "", "rus_standard");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    assert_eq!(conv_result.action, "composing");
    assert_eq!(conv_result.buffer, "К");

    // Test: К + Я -> きゃ
    let result = IMEEngine::process_key("Я", "К", "rus_standard");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    assert_eq!(conv_result.output, "きゃ");
    assert_eq!(conv_result.buffer, "");
    assert_eq!(conv_result.action, "commit");
}

#[test]
fn test_serbian_single_key_ligature() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_SRB, "schema_srb_v1");

    

    // Test: Ћ -> ち (Serbian single character for "chi")
    let result = IMEEngine::process_key("Ћ", "", "srb_cyrillic");
    assert!(result.is_ok());

    let conv_result = result.unwrap();
    assert_eq!(conv_result.output, "ち");
    assert_eq!(conv_result.buffer, "");
    assert_eq!(conv_result.action, "commit");
}

#[test]
fn test_serbian_multi_character_conversion() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_SRB, "schema_srb_v1");

    

    // Test: К (composing)
    let result = IMEEngine::process_key("К", "", "srb_cyrillic");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    assert_eq!(conv_result.action, "composing");
    assert_eq!(conv_result.buffer, "К");

    // Test: К + Ј (composing)
    let result = IMEEngine::process_key("Ј", "К", "srb_cyrillic");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    assert_eq!(conv_result.action, "composing");
    assert_eq!(conv_result.buffer, "КЈ");

    // Test: К + Ј + А -> きゃ
    let result = IMEEngine::process_key("А", "КЈ", "srb_cyrillic");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    assert_eq!(conv_result.output, "きゃ");
    assert_eq!(conv_result.buffer, "");
    assert_eq!(conv_result.action, "commit");
}

#[test]
fn test_invalid_sequence() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_v1");

    

    // Test: Invalid sequence -> clear
    let result = IMEEngine::process_key("Б", "К", "rus_standard");
    assert!(result.is_ok());
    let conv_result = result.unwrap();
    // Should clear buffer since КБ is not a valid sequence
    assert_eq!(conv_result.action, "clear");
}

#[test]
fn test_profile_switching() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_v1");
    let _ = IMEEngine::load_schema(TEST_SCHEMA_SRB, "schema_srb_v1");

    

    // Same phonetic key "kya" but different input sequences

    // Russian: КЯ -> きゃ
    let result = IMEEngine::process_key("Я", "К", "rus_standard");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "きゃ");

    // Serbian: КЈА -> きゃ
    let result = IMEEngine::process_key("А", "КЈ", "srb_cyrillic");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "きゃ");
}
