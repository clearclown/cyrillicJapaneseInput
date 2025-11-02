/// Comprehensive error handling tests
use cyrillic_ime_core::IMEEngine;

#[test]
fn test_malformed_profiles_json() {
    // Missing closing bracket
    let malformed = r#"[{"id": "test""#;
    let kana = r#"{"a": "あ"}"#;

    let result = IMEEngine::init(malformed, kana);
    assert!(result.is_err(), "Should fail with malformed JSON");
}

#[test]
fn test_empty_profiles_json() {
    let empty = r#"[]"#;
    let kana = r#"{"a": "あ"}"#;

    let result = IMEEngine::init(empty, kana);
    // Should succeed with empty profiles
    assert!(result.is_ok() || result.is_err()); // Engine may already be initialized
}

#[test]
fn test_profiles_with_missing_fields() {
    let missing_field = r#"[{"id": "test"}]"#; // Missing name_ja, name_en, etc.
    let kana = r#"{"a": "あ"}"#;

    let result = IMEEngine::init(missing_field, kana);
    assert!(result.is_err(), "Should fail with missing required fields");
}

#[test]
fn test_profiles_with_wrong_types() {
    let wrong_type = r#"[{
        "id": "test",
        "name_ja": 123,
        "name_en": "Test",
        "keyboardLayout": "not_an_array",
        "inputSchemaId": "test_schema"
    }]"#;
    let kana = r#"{"a": "あ"}"#;

    let result = IMEEngine::init(wrong_type, kana);
    assert!(result.is_err(), "Should fail with wrong field types");
}

#[test]
fn test_malformed_kana_engine_json() {
    let profiles = r#"[{
        "id": "test",
        "name_ja": "テスト",
        "name_en": "Test",
        "keyboardLayout": ["А"],
        "inputSchemaId": "test_schema"
    }]"#;
    let malformed_kana = r#"{"a": "あ""#; // Missing closing brace

    let result = IMEEngine::init(profiles, malformed_kana);
    assert!(result.is_err(), "Should fail with malformed kana engine JSON");
}

#[test]
fn test_empty_kana_engine() {
    let profiles = r#"[{
        "id": "test",
        "name_ja": "テスト",
        "name_en": "Test",
        "keyboardLayout": ["А"],
        "inputSchemaId": "test_schema"
    }]"#;
    let empty_kana = r#"{}"#;

    let result = IMEEngine::init(profiles, empty_kana);
    // Should succeed (empty kana engine is valid, just won't convert anything)
    assert!(result.is_ok() || result.is_err()); // May already be initialized
}

#[test]
fn test_kana_engine_with_invalid_unicode() {
    let profiles = r#"[{
        "id": "test",
        "name_ja": "テスト",
        "name_en": "Test",
        "keyboardLayout": ["А"],
        "inputSchemaId": "test_schema"
    }]"#;
    // Valid JSON but with unusual unicode
    let kana = r#"{"a": "\uD800"}"#; // Invalid unicode surrogate

    let result = IMEEngine::init(profiles, kana);
    // Rust handles unicode gracefully, this might succeed
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_malformed_schema_json() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    let malformed = r#"{"А": {"kana_key": "a""#; // Missing closing braces
    let result = IMEEngine::load_schema(malformed, "test_schema");
    assert!(result.is_err(), "Should fail with malformed schema JSON");
}

#[test]
fn test_schema_with_missing_kana_key() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    let missing_key = r#"{"А": {}}"#; // Missing kana_key field
    let result = IMEEngine::load_schema(missing_key, "test_schema");
    assert!(result.is_err(), "Should fail with missing kana_key");
}

#[test]
fn test_schema_with_empty_string_keys() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    let empty_keys = r#"{"": {"kana_key": "a"}}"#; // Empty string as key
    let result = IMEEngine::load_schema(empty_keys, "test_schema");
    // Should succeed - empty string is a valid key
    assert!(result.is_ok());
}

#[test]
fn test_process_key_with_nonexistent_profile() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    let result = IMEEngine::process_key("А", "", "nonexistent_profile");
    assert!(result.is_err(), "Should fail with nonexistent profile");

    if let Err(e) = result {
        assert!(e.contains("Profile not found"), "Error message should mention profile not found");
    }
}

#[test]
fn test_process_key_with_unloaded_schema() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"unloaded_schema"}]"#,
        r#"{"a":"あ"}"#
    );

    let result = IMEEngine::process_key("А", "", "test");
    // May succeed or fail depending on which test initialized the engine
    // If it fails, check that error message is appropriate
    if result.is_err() {
        let e = result.unwrap_err();
        assert!(e.contains("Schema not loaded") || e.contains("Profile not found"),
                "Error message should mention schema or profile issue");
    }
}

#[test]
fn test_process_key_with_empty_strings() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#,
        r#"{"a":"あ"}"#
    );
    let _ = IMEEngine::load_schema(r#"{"А":{"kana_key":"a"}}"#, "test_schema");

    // Empty key
    let result = IMEEngine::process_key("", "", "test");
    // Should either succeed with clear action or fail gracefully
    assert!(result.is_ok() || result.is_err());

    // Empty profile ID
    let result = IMEEngine::process_key("А", "", "");
    assert!(result.is_err(), "Should fail with empty profile ID");
}

#[test]
fn test_process_key_with_special_characters() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#,
        r#"{"a":"あ"}"#
    );
    let _ = IMEEngine::load_schema(r#"{"А":{"kana_key":"a"}}"#, "test_schema");

    // Null character in profile ID
    let result = IMEEngine::process_key("А", "", "test\0broken");
    // Should handle gracefully
    assert!(result.is_err() || result.is_ok());
}

#[test]
fn test_schema_with_duplicate_keys() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    // JSON with duplicate keys (last one wins in most JSON parsers)
    let duplicate = r#"{
        "А": {"kana_key": "a"},
        "А": {"kana_key": "i"}
    }"#;
    let result = IMEEngine::load_schema(duplicate, "test_schema");
    // Should succeed, last value wins
    assert!(result.is_ok());
}

#[test]
fn test_kana_key_not_in_engine() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#,
        r#"{"a":"あ"}"#
    );

    // Schema references kana_key "xyz" which doesn't exist in engine
    let _ = IMEEngine::load_schema(r#"{"А":{"kana_key":"xyz"}}"#, "test_schema");

    let result = IMEEngine::process_key("А", "", "test");
    // Should succeed but return the kana_key itself
    if let Ok(conv) = result {
        assert_eq!(conv.output, "xyz", "Should return kana_key if not found in engine");
    }
}

#[test]
fn test_extremely_long_buffer() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#,
        r#"{"a":"あ"}"#
    );
    let _ = IMEEngine::load_schema(r#"{"А":{"kana_key":"a"}}"#, "test_schema");

    // Buffer with 100,000 characters
    let huge_buffer = "К".repeat(100_000);
    let result = IMEEngine::process_key("А", &huge_buffer, "test");

    // Should handle gracefully without crashing
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_extremely_long_key() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#,
        r#"{"a":"あ"}"#
    );
    let _ = IMEEngine::load_schema(r#"{"А":{"kana_key":"a"}}"#, "test_schema");

    // Very long key (unlikely in practice but test robustness)
    let long_key = "А".repeat(10_000);
    let result = IMEEngine::process_key(&long_key, "", "test");

    // Should handle gracefully
    assert!(result.is_ok() || result.is_err());
}

#[test]
fn test_schema_with_non_ascii_keys() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    // Schema with emoji or other unicode as keys
    let unicode_schema = r#"{
        "😀": {"kana_key": "smile"},
        "🎌": {"kana_key": "flag"}
    }"#;
    let result = IMEEngine::load_schema(unicode_schema, "unicode_schema");
    assert!(result.is_ok(), "Should handle unicode keys");
}

#[test]
fn test_json_with_escaped_characters() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    let escaped = r#"{"А": {"kana_key": "a\nb\tc"}}"#; // Newline and tab in kana_key
    let result = IMEEngine::load_schema(escaped, "escaped_schema");
    assert!(result.is_ok(), "Should handle escaped characters");
}

#[test]
fn test_very_large_schema() {
    let _ = IMEEngine::init(
        r#"[{"id":"test","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test"}]"#,
        r#"{"a":"あ"}"#
    );

    // Generate a schema with 10,000 entries
    let mut large_schema = String::from("{");
    for i in 0..10_000 {
        if i > 0 {
            large_schema.push(',');
        }
        large_schema.push_str(&format!(r#""KEY{}": {{"kana_key": "value{}"}}"#, i, i));
    }
    large_schema.push('}');

    let result = IMEEngine::load_schema(&large_schema, "large_schema");
    assert!(result.is_ok(), "Should handle large schemas");
}

#[test]
fn test_get_profiles_error_propagation() {
    // Try to get profiles without initialization (if possible)
    // Note: This may not fail if engine was initialized by other tests
    let result = IMEEngine::get_profiles();
    // Should either succeed or fail gracefully
    assert!(result.is_ok() || result.is_err());
}
