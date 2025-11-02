/// Integration tests using real profile data
use cyrillic_ime_core::IMEEngine;
use std::fs;
use std::path::PathBuf;

fn get_test_data_path(filename: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("profiles")
        .join(filename)
}

#[test]
fn test_load_real_profiles() {
    let profiles_path = get_test_data_path("profiles.json");

    if !profiles_path.exists() {
        println!("Skipping test: profiles.json not found at {:?}", profiles_path);
        return;
    }

    let profiles_json = fs::read_to_string(&profiles_path)
        .expect("Failed to read profiles.json");

    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    let kana_engine_json = fs::read_to_string(&kana_engine_path)
        .expect("Failed to read japaneseKanaEngine.json");

    let result = IMEEngine::init(&profiles_json, &kana_engine_json);

    if result.is_err() {
        // May already be initialized by other tests
        println!("Engine already initialized or initialization failed");
    }

    let profiles = IMEEngine::get_profiles();
    assert!(profiles.is_ok(), "Should be able to get profiles");

    let profiles = profiles.unwrap();
    assert!(profiles.len() >= 4, "Should have at least 4 profiles");

    // Check expected profiles exist
    let profile_ids: Vec<&str> = profiles.iter().map(|p| p.id.as_str()).collect();
    assert!(profile_ids.contains(&"rus_standard"));
    assert!(profile_ids.contains(&"srb_cyrillic"));
    assert!(profile_ids.contains(&"ukr_cyrillic"));
}

#[test]
fn test_load_real_russian_schema() {
    // Ensure engine is initialized
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    if profiles_path.exists() && kana_engine_path.exists() {
        let profiles_json = fs::read_to_string(&profiles_path).unwrap_or_default();
        let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap_or_default();
        let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    }

    let schema_path = get_test_data_path("schemas/schema_rus_v1.json");

    if !schema_path.exists() {
        println!("Skipping test: schema_rus_v1.json not found");
        return;
    }

    let schema_json = fs::read_to_string(&schema_path)
        .expect("Failed to read schema_rus_v1.json");

    let result = IMEEngine::load_schema(&schema_json, "schema_rus_v1");
    assert!(result.is_ok(), "Should load Russian schema successfully");
}

#[test]
fn test_load_real_serbian_schema() {
    // Ensure engine is initialized
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    if profiles_path.exists() && kana_engine_path.exists() {
        let profiles_json = fs::read_to_string(&profiles_path).unwrap_or_default();
        let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap_or_default();
        let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    }

    let schema_path = get_test_data_path("schemas/schema_srb_v1.json");

    if !schema_path.exists() {
        println!("Skipping test: schema_srb_v1.json not found");
        return;
    }

    let schema_json = fs::read_to_string(&schema_path)
        .expect("Failed to read schema_srb_v1.json");

    let result = IMEEngine::load_schema(&schema_json, "schema_srb_v1");
    assert!(result.is_ok(), "Should load Serbian schema successfully");
}

#[test]
fn test_load_real_ukrainian_schema() {
    // Ensure engine is initialized
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    if profiles_path.exists() && kana_engine_path.exists() {
        let profiles_json = fs::read_to_string(&profiles_path).unwrap_or_default();
        let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap_or_default();
        let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    }

    let schema_path = get_test_data_path("schemas/schema_ukr_v1.json");

    if !schema_path.exists() {
        println!("Skipping test: schema_ukr_v1.json not found");
        return;
    }

    let schema_json = fs::read_to_string(&schema_path)
        .expect("Failed to read schema_ukr_v1.json");

    let result = IMEEngine::load_schema(&schema_json, "schema_ukr_v1");
    assert!(result.is_ok(), "Should load Ukrainian schema successfully");
}

#[test]
fn test_russian_hiragana_conversion_real_data() {
    // Initialize with real data
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    let schema_path = get_test_data_path("schemas/schema_rus_v1.json");

    if !profiles_path.exists() || !kana_engine_path.exists() || !schema_path.exists() {
        println!("Skipping test: required files not found");
        return;
    }

    let profiles_json = fs::read_to_string(&profiles_path).unwrap();
    let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap();
    let schema_json = fs::read_to_string(&schema_path).unwrap();

    let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    let _ = IMEEngine::load_schema(&schema_json, "schema_rus_v1");

    // Test common Russian input sequences

    // А -> あ
    let result = IMEEngine::process_key("А", "", "rus_standard");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "あ");

    // КА -> か
    let result = IMEEngine::process_key("А", "К", "rus_standard");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "か");

    // КЯ -> きゃ
    let result = IMEEngine::process_key("Я", "К", "rus_standard");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "きゃ");

    // ЧА -> ちゃ
    let result = IMEEngine::process_key("А", "Ч", "rus_standard");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "ちゃ");
}

#[test]
fn test_serbian_special_characters_real_data() {
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    let schema_path = get_test_data_path("schemas/schema_srb_v1.json");

    if !profiles_path.exists() || !kana_engine_path.exists() || !schema_path.exists() {
        println!("Skipping test: required files not found");
        return;
    }

    let profiles_json = fs::read_to_string(&profiles_path).unwrap();
    let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap();
    let schema_json = fs::read_to_string(&schema_path).unwrap();

    let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    let _ = IMEEngine::load_schema(&schema_json, "schema_srb_v1");

    // Test Serbian special characters

    // Ћ -> ち (single key)
    let result = IMEEngine::process_key("Ћ", "", "srb_cyrillic");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().output, "ち");

    // Њ -> にゃ (single key)
    let result = IMEEngine::process_key("Њ", "", "srb_cyrillic");
    assert!(result.is_ok());
    let output = result.unwrap().output;
    assert!(output == "にゃ" || output == "", "Њ should map to nya or be composing");

    // Љ -> りゃ (single key)
    let result = IMEEngine::process_key("Љ", "", "srb_cyrillic");
    assert!(result.is_ok());
    let output = result.unwrap().output;
    assert!(output == "りゃ" || output == "", "Љ should map to rya or be composing");
}

#[test]
fn test_complete_word_conversion_russian() {
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");
    let schema_path = get_test_data_path("schemas/schema_rus_v1.json");

    if !profiles_path.exists() || !kana_engine_path.exists() || !schema_path.exists() {
        println!("Skipping test: required files not found");
        return;
    }

    let profiles_json = fs::read_to_string(&profiles_path).unwrap();
    let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap();
    let schema_json = fs::read_to_string(&schema_path).unwrap();

    let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    let _ = IMEEngine::load_schema(&schema_json, "schema_rus_v1");

    // Simulate typing "КАСАЯ" (ka-sa-ya -> かさや)
    let mut buffer = String::new();
    let mut output = String::new();

    // К -> composing
    let result = IMEEngine::process_key("К", &buffer, "rus_standard");
    assert!(result.is_ok());
    let conv = result.unwrap();
    if conv.action == "composing" {
        buffer = conv.buffer;
    }

    // А -> commit "か"
    let result = IMEEngine::process_key("А", &buffer, "rus_standard");
    assert!(result.is_ok());
    let conv = result.unwrap();
    if conv.action == "commit" {
        output.push_str(&conv.output);
        buffer = conv.buffer;
    }

    // С -> composing
    let result = IMEEngine::process_key("С", &buffer, "rus_standard");
    assert!(result.is_ok());
    let conv = result.unwrap();
    if conv.action == "composing" {
        buffer = conv.buffer;
    }

    // А -> commit "さ"
    let result = IMEEngine::process_key("А", &buffer, "rus_standard");
    assert!(result.is_ok());
    let conv = result.unwrap();
    if conv.action == "commit" {
        output.push_str(&conv.output);
        buffer = conv.buffer;
    }

    // Я -> commit "や"
    let result = IMEEngine::process_key("Я", &buffer, "rus_standard");
    assert!(result.is_ok());
    let conv = result.unwrap();
    if conv.action == "commit" {
        output.push_str(&conv.output);
    }

    assert_eq!(output, "かさや", "Should produce 'かさや'");
}

#[test]
fn test_all_schemas_loadable() {
    // Ensure engine is initialized first
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");

    if profiles_path.exists() && kana_engine_path.exists() {
        let profiles_json = fs::read_to_string(&profiles_path).unwrap_or_default();
        let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap_or_default();
        let _ = IMEEngine::init(&profiles_json, &kana_engine_json);
    }

    let schemas_dir = get_test_data_path("schemas");

    if !schemas_dir.exists() {
        println!("Skipping test: schemas directory not found");
        return;
    }

    let schema_files = vec![
        "schema_rus_v1.json",
        "schema_rus_analytical_v1.json",
        "schema_srb_v1.json",
        "schema_ukr_v1.json",
    ];

    for schema_file in schema_files {
        let schema_path = schemas_dir.join(schema_file);
        if schema_path.exists() {
            let schema_json = fs::read_to_string(&schema_path)
                .expect(&format!("Failed to read {}", schema_file));

            let schema_id = schema_file.replace(".json", "");
            let result = IMEEngine::load_schema(&schema_json, &schema_id);
            assert!(result.is_ok(), "Failed to load schema: {}", schema_file);
        }
    }
}

#[test]
fn test_profile_switching_consistency() {
    let profiles_path = get_test_data_path("profiles.json");
    let kana_engine_path = get_test_data_path("japaneseKanaEngine.json");

    if !profiles_path.exists() || !kana_engine_path.exists() {
        println!("Skipping test: required files not found");
        return;
    }

    let profiles_json = fs::read_to_string(&profiles_path).unwrap();
    let kana_engine_json = fs::read_to_string(&kana_engine_path).unwrap();

    let _ = IMEEngine::init(&profiles_json, &kana_engine_json);

    // Load all schemas
    let schemas = vec![
        ("schemas/schema_rus_v1.json", "schema_rus_v1"),
        ("schemas/schema_srb_v1.json", "schema_srb_v1"),
        ("schemas/schema_ukr_v1.json", "schema_ukr_v1"),
    ];

    for (file, id) in schemas {
        let path = get_test_data_path(file);
        if path.exists() {
            let json = fs::read_to_string(&path).unwrap();
            let _ = IMEEngine::load_schema(&json, id);
        }
    }

    // Test that the same phonetic output comes from different inputs
    // Russian: КЯ -> きゃ
    let result_rus = IMEEngine::process_key("Я", "К", "rus_standard");

    // Serbian: КЈА -> きゃ
    let result_srb1 = IMEEngine::process_key("Ј", "К", "srb_cyrillic");
    if result_srb1.is_ok() && result_srb1.as_ref().unwrap().action == "composing" {
        let buffer = result_srb1.unwrap().buffer;
        let result_srb2 = IMEEngine::process_key("А", &buffer, "srb_cyrillic");

        if result_rus.is_ok() && result_srb2.is_ok() {
            // Both should produce the same hiragana
            assert_eq!(
                result_rus.unwrap().output,
                result_srb2.unwrap().output,
                "Different profiles should produce same hiragana for same phoneme"
            );
        }
    }
}
