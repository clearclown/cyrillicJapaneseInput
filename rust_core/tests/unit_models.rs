/// Unit tests for models module
use cyrillic_ime_core::models::{ConversionResult, Profile, Schema, SchemaEntry};
use serde_json;

#[test]
fn test_conversion_result_commit() {
    let result = ConversionResult::commit("あ".to_string());

    assert_eq!(result.output, "あ");
    assert_eq!(result.buffer, "");
    assert_eq!(result.action, "commit");
}

#[test]
fn test_conversion_result_composing() {
    let result = ConversionResult::composing("К".to_string());

    assert_eq!(result.output, "");
    assert_eq!(result.buffer, "К");
    assert_eq!(result.action, "composing");
}

#[test]
fn test_conversion_result_clear() {
    let result = ConversionResult::clear();

    assert_eq!(result.output, "");
    assert_eq!(result.buffer, "");
    assert_eq!(result.action, "clear");
}

#[test]
fn test_conversion_result_serialization() {
    let result = ConversionResult::commit("きゃ".to_string());
    let json = serde_json::to_string(&result).unwrap();

    assert!(json.contains(r#""output":"きゃ""#));
    assert!(json.contains(r#""buffer":"""#));
    assert!(json.contains(r#""action":"commit""#));
}

#[test]
fn test_conversion_result_deserialization() {
    let json = r#"{"output":"きゃ","buffer":"","action":"commit","lastOutput":"きゃ","lastVowelType":"a"}"#;
    let result: ConversionResult = serde_json::from_str(json).unwrap();

    assert_eq!(result.output, "きゃ");
    assert_eq!(result.buffer, "");
    assert_eq!(result.action, "commit");
    assert_eq!(result.last_output, "きゃ");
    assert_eq!(result.last_vowel_type, Some("a".to_string()));
}

#[test]
fn test_profile_deserialization() {
    let json = r#"{
        "id": "rus_standard",
        "name_ja": "ロシア語 (標準)",
        "name_en": "Russian (Standard)",
        "keyboardLayout": ["А", "Б", "В"],
        "inputSchemaId": "schema_rus_v1"
    }"#;

    let profile: Profile = serde_json::from_str(json).unwrap();

    assert_eq!(profile.id, "rus_standard");
    assert_eq!(profile.name_ja, "ロシア語 (標準)");
    assert_eq!(profile.name_en, "Russian (Standard)");
    assert_eq!(profile.keyboard_layout.len(), 3);
    assert_eq!(profile.keyboard_layout[0], "А");
    assert_eq!(profile.input_schema_id, "schema_rus_v1");
}

#[test]
fn test_profile_serialization() {
    let profile = Profile {
        id: "test_profile".to_string(),
        name_ja: "テスト".to_string(),
        name_en: "Test".to_string(),
        keyboard_layout: vec!["А".to_string(), "Б".to_string()],
        input_schema_id: "test_schema".to_string(),
    };

    let json = serde_json::to_string(&profile).unwrap();
    let deserialized: Profile = serde_json::from_str(&json).unwrap();

    assert_eq!(deserialized.id, profile.id);
    assert_eq!(deserialized.name_ja, profile.name_ja);
    assert_eq!(deserialized.keyboard_layout, profile.keyboard_layout);
}

#[test]
fn test_schema_entry_deserialization() {
    let json = r#"{"kana_key": "kya"}"#;
    let entry: SchemaEntry = serde_json::from_str(json).unwrap();

    assert_eq!(entry.kana_key, "kya");
}

#[test]
fn test_schema_deserialization() {
    let json = r#"{
        "А": {"kana_key": "a"},
        "КЯ": {"kana_key": "kya"}
    }"#;

    let schema: Schema = serde_json::from_str(json).unwrap();

    assert_eq!(schema.len(), 2);
    assert_eq!(schema.get("А").unwrap().kana_key, "a");
    assert_eq!(schema.get("КЯ").unwrap().kana_key, "kya");
}

#[test]
fn test_schema_empty() {
    let json = r#"{}"#;
    let schema: Schema = serde_json::from_str(json).unwrap();

    assert_eq!(schema.len(), 0);
}

#[test]
fn test_profile_with_large_keyboard_layout() {
    let mut layout = Vec::new();
    for i in 0..100 {
        layout.push(format!("Key{}", i));
    }

    let profile = Profile {
        id: "large_profile".to_string(),
        name_ja: "大きいプロファイル".to_string(),
        name_en: "Large Profile".to_string(),
        keyboard_layout: layout.clone(),
        input_schema_id: "large_schema".to_string(),
    };

    assert_eq!(profile.keyboard_layout.len(), 100);
    assert_eq!(profile.keyboard_layout[0], "Key0");
    assert_eq!(profile.keyboard_layout[99], "Key99");
}

#[test]
fn test_conversion_result_with_empty_strings() {
    let result = ConversionResult {
        output: "".to_string(),
        buffer: "".to_string(),
        action: "clear".to_string(),
        last_output: "".to_string(),
        last_vowel_type: None,
    };

    let json = serde_json::to_string(&result).unwrap();
    let deserialized: ConversionResult = serde_json::from_str(&json).unwrap();

    assert_eq!(deserialized.output, "");
    assert_eq!(deserialized.buffer, "");
    assert_eq!(deserialized.action, "clear");
}

#[test]
fn test_profile_with_unicode_characters() {
    let profile = Profile {
        id: "unicode_profile".to_string(),
        name_ja: "日本語テスト🎌".to_string(),
        name_en: "Unicode Test 🇷🇺".to_string(),
        keyboard_layout: vec!["А".to_string(), "🔤".to_string()],
        input_schema_id: "unicode_schema".to_string(),
    };

    let json = serde_json::to_string(&profile).unwrap();
    let deserialized: Profile = serde_json::from_str(&json).unwrap();

    assert_eq!(deserialized.name_ja, profile.name_ja);
    assert_eq!(deserialized.name_en, profile.name_en);
}

#[test]
fn test_schema_with_complex_keys() {
    let json = r#"{
        "ДЖЬЯ": {"kana_key": "ja"},
        "ЩЬЮЁ": {"kana_key": "complex"}
    }"#;

    let schema: Schema = serde_json::from_str(json).unwrap();

    assert!(schema.contains_key("ДЖЬЯ"));
    assert!(schema.contains_key("ЩЬЮЁ"));
    assert_eq!(schema.get("ДЖЬЯ").unwrap().kana_key, "ja");
}
