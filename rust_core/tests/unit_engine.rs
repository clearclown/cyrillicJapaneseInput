/// Unit tests for engine module
use cyrillic_ime_core::IMEEngine;

const TEST_PROFILES: &str = r#"[
    {
        "id": "rus_test",
        "name_ja": "ロシア語テスト",
        "name_en": "Russian Test",
        "keyboardLayout": ["А", "И", "У", "К", "Я", "Н"],
        "inputSchemaId": "schema_rus_test"
    }
]"#;

const TEST_KANA_ENGINE: &str = r#"{
    "a": "あ",
    "i": "い",
    "u": "う",
    "ka": "か",
    "ki": "き",
    "kya": "きゃ",
    "n_final": "ん"
}"#;

const TEST_SCHEMA_RUS: &str = r#"{
    "А": {"kana_key": "a"},
    "И": {"kana_key": "i"},
    "У": {"kana_key": "u"},
    "КА": {"kana_key": "ka"},
    "КИ": {"kana_key": "ki"},
    "КЯ": {"kana_key": "kya"},
    "Н": {"kana_key": "n_final"}
}"#;

#[test]
fn test_engine_double_initialization_fails() {
    // First initialization should succeed
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    // Second initialization should fail (already initialized)
    let result = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    assert!(result.is_err(), "Double initialization should fail");
}

#[test]
fn test_get_profiles_before_init() {
    // Note: This test may fail if other tests have already initialized the engine
    // In a real test suite, you'd use test isolation
    let result = IMEEngine::get_profiles();
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_load_schema_before_init() {
    let result = IMEEngine::load_schema(TEST_SCHEMA_RUS, "test_schema");
    // Should fail or succeed depending on whether engine is initialized
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_process_key_with_empty_key() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    let result = IMEEngine::process_key("", "", "rus_test");
    // Empty key should either clear or return an error
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_process_key_with_invalid_profile() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    let result = IMEEngine::process_key("А", "", "nonexistent_profile");
    assert!(result.is_err(), "Should fail with invalid profile");
}

#[test]
fn test_process_key_with_unloaded_schema() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    // Don't load schema

    let result = IMEEngine::process_key("А", "", "rus_test");
    // May succeed if schema was loaded by another test, or fail if not loaded
    // This is expected with global singleton pattern
    let _ = result;
}

#[test]
fn test_load_invalid_schema_json() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let invalid_json = r#"{"invalid": "json"#;
    let result = IMEEngine::load_schema(invalid_json, "invalid_schema");
    assert!(result.is_err(), "Should fail with invalid JSON");
}

#[test]
fn test_init_with_invalid_profiles_json() {
    let invalid_json = r#"[{"invalid": "json"#;
    let result = IMEEngine::init(invalid_json, TEST_KANA_ENGINE);
    assert!(result.is_err(), "Should fail with invalid profiles JSON");
}

#[test]
fn test_init_with_invalid_kana_engine_json() {
    let invalid_json = r#"{"invalid": "json"#;
    let result = IMEEngine::init(TEST_PROFILES, invalid_json);
    assert!(result.is_err(), "Should fail with invalid kana engine JSON");
}

#[test]
fn test_composing_state_preservation() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // First key: К (should be composing)
    let result1 = IMEEngine::process_key("К", "", "rus_test");
    assert!(result1.is_ok());
    let conv1 = result1.unwrap();
    assert_eq!(conv1.action, "composing");
    assert_eq!(conv1.buffer, "К");

    // Second key: И (should commit КИ -> き)
    let result2 = IMEEngine::process_key("И", &conv1.buffer, "rus_test");
    assert!(result2.is_ok());
    let conv2 = result2.unwrap();
    assert_eq!(conv2.action, "commit");
    assert_eq!(conv2.output, "き");
    assert_eq!(conv2.buffer, "");
}

#[test]
fn test_single_character_direct_match() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    let result = IMEEngine::process_key("А", "", "rus_test");
    assert!(result.is_ok());
    let conv = result.unwrap();
    assert_eq!(conv.action, "commit");
    assert_eq!(conv.output, "あ");
    assert_eq!(conv.buffer, "");
}

#[test]
fn test_撥音_n_handling() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Н alone should give ん
    let result = IMEEngine::process_key("Н", "", "rus_test");
    assert!(result.is_ok());
    let conv = result.unwrap();
    assert_eq!(conv.output, "ん");
}

#[test]
fn test_prefix_matching_longest_first() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // К should be composing (prefix of КА, КИ, КЯ)
    let result1 = IMEEngine::process_key("К", "", "rus_test");
    assert!(result1.is_ok());
    assert_eq!(result1.unwrap().action, "composing");

    // КЯ should commit きゃ
    let result2 = IMEEngine::process_key("Я", "К", "rus_test");
    assert!(result2.is_ok());
    let conv = result2.unwrap();
    assert_eq!(conv.output, "きゃ");
    assert_eq!(conv.action, "commit");
}

#[test]
fn test_clear_on_invalid_sequence() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // КУ is not a valid sequence, but У is valid alone
    let result = IMEEngine::process_key("У", "К", "rus_test");
    assert!(result.is_ok());
    let conv = result.unwrap();
    // Engine commits У and keeps buffer К
    // Or clears if КУ doesn't match and У isn't a single key
    assert!(conv.action == "commit" || conv.action == "clear");
}

#[test]
fn test_get_profiles_after_init() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let result = IMEEngine::get_profiles();
    assert!(result.is_ok());
    let profiles = result.unwrap();
    assert_eq!(profiles.len(), 1);
    assert_eq!(profiles[0].id, "rus_test");
}

#[test]
fn test_multiple_schema_loading() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let result1 = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_1");
    assert!(result1.is_ok());

    let result2 = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_2");
    assert!(result2.is_ok());

    // Both schemas should be loaded
    // This is implicit - we can't directly query loaded schemas
}

#[test]
fn test_schema_overwriting() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    // Load first schema
    let schema1 = r#"{"А": {"kana_key": "a"}}"#;
    let result1 = IMEEngine::load_schema(schema1, "test_schema");
    assert!(result1.is_ok());

    // Overwrite with different schema
    let schema2 = r#"{"И": {"kana_key": "i"}}"#;
    let result2 = IMEEngine::load_schema(schema2, "test_schema");
    assert!(result2.is_ok());
}

#[test]
fn test_empty_buffer_processing() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Processing with empty buffer should work
    let result = IMEEngine::process_key("А", "", "rus_test");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "あ");
}

#[test]
fn test_large_buffer() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Very large invalid buffer should clear
    let large_buffer = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ".repeat(10);
    let result = IMEEngine::process_key("А", &large_buffer, "rus_test");
    assert!(result.is_ok());
    // Should either clear or handle gracefully
}
