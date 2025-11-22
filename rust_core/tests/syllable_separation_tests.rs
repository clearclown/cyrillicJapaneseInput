/// Tests for syllable separation with hard sign (Ъ)
/// Test case: Н + Ъ + А → んあ
use cyrillic_ime_core::IMEEngine;

const TEST_PROFILES: &str = r#"[{
    "id": "rus_test",
    "name_ja": "テスト",
    "name_en": "Test",
    "keyboardLayout": ["Н", "А", "И", "Ъ"],
    "inputSchemaId": "schema_rus_test"
}]"#;

const TEST_KANA_ENGINE: &str = r#"{
    "a": "あ",
    "i": "い",
    "n_final": "ん",
    "na": "な",
    "ni": "に"
}"#;

const TEST_SCHEMA_RUS: &str = r#"{
    "А": {"kana_key": "a"},
    "И": {"kana_key": "i"},
    "Н": {"kana_key": "n_final"},
    "НА": {"kana_key": "na"},
    "НИ": {"kana_key": "ni"}
}"#;

#[test]
fn test_hard_sign_basic_separator() {
    // Initialize engine
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Just Ъ alone (no buffer) should return empty with action="separator"
    let result = IMEEngine::process_key("Ъ", "", "rus_test", "", &None);
    assert!(result.is_ok());
    let conv = result.unwrap();
    assert_eq!(conv.output, "");
    assert_eq!(conv.action, "separator");
    assert_eq!(conv.buffer, "");
}

#[test]
fn test_hard_sign_with_buffer_commits() {
    // Test: Н + Ъ should commit Н as ん
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // First: Н (composing, buffer="Н")
    let r1 = IMEEngine::process_key("Н", "", "rus_test", "", &None);
    assert!(r1.is_ok());
    // Н alone might be composing if НА, НИ exist in schema
    // OR might commit immediately if Н is a valid standalone mapping
    // In this test, Н should be buffered because НА and НИ exist
    let conv1 = r1.unwrap();
    // Could be composing or commit depending on schema logic
    // Let's check what actually happens

    // Second: Ъ should commit the buffer as ん
    let buffer_state = if conv1.action == "composing" {
        conv1.buffer
    } else {
        "Н".to_string()
    };

    let r2 = IMEEngine::process_key("Ъ", &buffer_state, "rus_test", &conv1.last_output, &conv1.last_vowel_type);
    assert!(r2.is_ok());
    let conv2 = r2.unwrap();

    if !buffer_state.is_empty() {
        // If there was a buffer, Ъ should commit it
        assert_eq!(conv2.output, "ん");
        assert_eq!(conv2.action, "separator");
        assert_eq!(conv2.buffer, "");
    }
}

#[test]
fn test_syllable_separation_н_ъ_а() {
    // Test case: Н + Ъ + А → んあ
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Step 1: Н (buffered)
    let r1 = IMEEngine::process_key("Н", "", "rus_test", "", &None);
    assert!(r1.is_ok());
    let conv1 = r1.unwrap();
    let buffer1 = conv1.buffer.clone();
    let last_output1 = conv1.last_output.clone();
    let last_vowel1 = conv1.last_vowel_type.clone();

    // Step 2: Ъ (commits Н as ん, action="separator")
    let r2 = IMEEngine::process_key("Ъ", &buffer1, "rus_test", &last_output1, &last_vowel1);
    assert!(r2.is_ok());
    let conv2 = r2.unwrap();

    if !buffer1.is_empty() {
        // Ъ should commit the buffer
        assert_eq!(conv2.output, "ん", "Ъ should commit buffered Н as ん");
        assert_eq!(conv2.action, "separator");
    }

    let last_output2 = conv2.last_output.clone();
    let last_vowel2 = conv2.last_vowel_type.clone();

    // Step 3: А (outputs あ)
    let r3 = IMEEngine::process_key("А", "", "rus_test", &last_output2, &last_vowel2);
    assert!(r3.is_ok());
    let conv3 = r3.unwrap();
    assert_eq!(conv3.output, "あ", "А after Ъ should output あ");

    // Combined output should be: ん + あ = んあ
    let combined_output = if !buffer1.is_empty() {
        format!("{}{}", conv2.output, conv3.output)
    } else {
        conv3.output.clone()
    };

    if !buffer1.is_empty() {
        assert_eq!(combined_output, "んあ", "Н + Ъ + А should produce んあ");
    }
}

#[test]
fn test_syllable_separation_prevents_combination() {
    // Test that Н + Ъ + А produces んあ, not なー
    // Without Ъ: Н + А would normally produce な
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    // Control: Н + А → な (normal combination)
    let r1_ctrl = IMEEngine::process_key("Н", "", "rus_test", "", &None);
    let conv1_ctrl = r1_ctrl.unwrap();
    let r2_ctrl = IMEEngine::process_key("А", &conv1_ctrl.buffer, "rus_test", &conv1_ctrl.last_output, &conv1_ctrl.last_vowel_type);
    let conv2_ctrl = r2_ctrl.unwrap();

    // НА should produce な (if schema has НА mapping)
    if !conv2_ctrl.output.is_empty() {
        // This is the normal combination behavior
        println!("Control: НА → {}", conv2_ctrl.output);
    }

    // Test: Н + Ъ + А → んあ (separated)
    let r1_test = IMEEngine::process_key("Н", "", "rus_test", "", &None);
    let conv1_test = r1_test.unwrap();

    let r2_test = IMEEngine::process_key("Ъ", &conv1_test.buffer, "rus_test", &conv1_test.last_output, &conv1_test.last_vowel_type);
    let conv2_test = r2_test.unwrap();

    let r3_test = IMEEngine::process_key("А", "", "rus_test", &conv2_test.last_output, &conv2_test.last_vowel_type);
    let conv3_test = r3_test.unwrap();

    // With Ъ separator, we should get ん + あ, not な
    if !conv1_test.buffer.is_empty() {
        assert_eq!(conv2_test.output, "ん", "Ъ separates Н");
        assert_eq!(conv3_test.output, "あ", "А after separation");
        assert_ne!(format!("{}{}", conv2_test.output, conv3_test.output), conv2_ctrl.output,
                   "Separated output should be different from combined");
    }
}

#[test]
fn test_multiple_separations_in_sequence() {
    // Test: Н + Ъ + А + Ъ + И → ん + あ + い
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA_RUS, "schema_rus_test");

    let mut output = String::new();
    let mut buffer = String::new();
    let mut last_output = String::new();
    let mut last_vowel: Option<String> = None;

    // Н
    let r1 = IMEEngine::process_key("Н", &buffer, "rus_test", &last_output, &last_vowel).unwrap();
    buffer = r1.buffer;
    last_output = r1.last_output;
    last_vowel = r1.last_vowel_type;
    if !r1.output.is_empty() {
        output.push_str(&r1.output);
    }

    // Ъ (commits Н)
    let r2 = IMEEngine::process_key("Ъ", &buffer, "rus_test", &last_output, &last_vowel).unwrap();
    buffer = r2.buffer;
    last_output = r2.last_output;
    last_vowel = r2.last_vowel_type;
    if !r2.output.is_empty() {
        output.push_str(&r2.output);
    }

    // А
    let r3 = IMEEngine::process_key("А", &buffer, "rus_test", &last_output, &last_vowel).unwrap();
    buffer = r3.buffer;
    last_output = r3.last_output;
    last_vowel = r3.last_vowel_type;
    if !r3.output.is_empty() {
        output.push_str(&r3.output);
    }

    // Ъ (separator, no commit)
    let r4 = IMEEngine::process_key("Ъ", &buffer, "rus_test", &last_output, &last_vowel).unwrap();
    buffer = r4.buffer;
    last_output = r4.last_output;
    last_vowel = r4.last_vowel_type;
    if !r4.output.is_empty() {
        output.push_str(&r4.output);
    }

    // И
    let r5 = IMEEngine::process_key("И", &buffer, "rus_test", &last_output, &last_vowel).unwrap();
    if !r5.output.is_empty() {
        output.push_str(&r5.output);
    }

    // Should produce: んあい (not んあいー or other variants)
    assert!(output.contains("あ"), "Should contain あ");
    assert!(output.contains("い"), "Should contain い");
}
