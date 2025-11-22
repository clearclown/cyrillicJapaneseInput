use crate::models::{ConversionResult, KanaEngine, Profile, Schema};
use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::sync::RwLock;

/// Global IME engine instance with thread-safe schema storage
static ENGINE: Lazy<RwLock<Option<IMEEngine>>> = Lazy::new(|| RwLock::new(None));

/// Main IME engine managing schemas and conversion logic
pub struct IMEEngine {
    /// All available profiles
    profiles: Vec<Profile>,

    /// Schema cache: profile_id -> Schema (Cyrillic -> kana_key)
    schemas: HashMap<String, Schema>,

    /// Kana engine: kana_key -> hiragana
    kana_engine: KanaEngine,
}

impl IMEEngine {
    /// Initialize the global engine instance
    pub fn init(profiles_json: &str, kana_engine_json: &str) -> Result<(), String> {
        let profiles: Vec<Profile> = serde_json::from_str(profiles_json)
            .map_err(|e| format!("Failed to parse profiles.json: {}", e))?;

        let kana_engine: KanaEngine = serde_json::from_str(kana_engine_json)
            .map_err(|e| format!("Failed to parse japaneseKanaEngine.json: {}", e))?;

        let engine = IMEEngine {
            profiles,
            schemas: HashMap::new(),
            kana_engine,
        };

        let mut engine_lock = ENGINE
            .write()
            .map_err(|_| "Failed to acquire write lock".to_string())?;

        if engine_lock.is_some() {
            return Err("Engine already initialized".to_string());
        }

        *engine_lock = Some(engine);
        Ok(())
    }

    /// Load a schema by ID (lazy loading)
    pub fn load_schema(schema_json: &str, schema_id: &str) -> Result<(), String> {
        let schema: Schema = serde_json::from_str(schema_json)
            .map_err(|e| format!("Failed to parse schema {}: {}", schema_id, e))?;

        let mut engine_lock = ENGINE
            .write()
            .map_err(|_| "Failed to acquire write lock".to_string())?;

        let engine = engine_lock
            .as_mut()
            .ok_or("Engine not initialized".to_string())?;

        engine.schemas.insert(schema_id.to_string(), schema);
        Ok(())
    }

    /// Check if a Cyrillic character is a vowel
    fn is_vowel(ch: &str) -> bool {
        matches!(ch, "А" | "И" | "У" | "Э" | "О" | "І" | "Е" | "Ы" | "Я" | "Ю" | "Ё")
    }

    /// Check if a character can create sokuon (促音) when doubled
    /// Н cannot create sokuon - it represents the special ん mora
    fn can_create_sokuon(ch: &str) -> bool {
        ch != "Н" && !Self::is_vowel(ch)
    }

    /// Get the vowel sound from a hiragana character
    fn get_vowel_type(hiragana: &str) -> Option<&'static str> {
        match hiragana {
            // A-row (あ段)
            "あ" | "か" | "が" | "さ" | "ざ" | "た" | "だ" | "な" | "は" | "ば" | "ぱ" | "ま" | "や" | "ら" | "わ" => Some("a"),
            "きゃ" | "ぎゃ" | "しゃ" | "じゃ" | "ちゃ" | "にゃ" | "ひゃ" | "びゃ" | "ぴゃ" | "みゃ" | "りゃ" => Some("a"),

            // I-row (い段)
            "い" | "き" | "ぎ" | "し" | "じ" | "ち" | "に" | "ひ" | "び" | "ぴ" | "み" | "り" => Some("i"),

            // U-row (う段)
            "う" | "く" | "ぐ" | "す" | "ず" | "つ" | "づ" | "ぬ" | "ふ" | "ぶ" | "ぷ" | "む" | "ゆ" | "る" => Some("u"),
            "きゅ" | "ぎゅ" | "しゅ" | "じゅ" | "ちゅ" | "にゅ" | "ひゅ" | "びゅ" | "ぴゅ" | "みゅ" | "りゅ" => Some("u"),

            // E-row (え段)
            "え" | "け" | "げ" | "せ" | "ぜ" | "て" | "で" | "ね" | "へ" | "べ" | "ぺ" | "め" | "れ" => Some("e"),

            // O-row (お段)
            "お" | "こ" | "ご" | "そ" | "ぞ" | "と" | "ど" | "の" | "ほ" | "ぼ" | "ぽ" | "も" | "よ" | "ろ" | "を" => Some("o"),
            "きょ" | "ぎょ" | "しょ" | "じょ" | "ちょ" | "にょ" | "ひょ" | "びょ" | "ぴょ" | "みょ" | "りょ" => Some("o"),

            _ => None,
        }
    }

    /// Check if a vowel matches the last output's vowel type
    /// Supports consecutive long vowels by using last_vowel_type when last_output is "ー"
    fn is_long_vowel(
        last_output: &str,
        last_vowel_type: &Option<String>,
        current_vowel_key: &str,
    ) -> bool {
        if last_output.is_empty() {
            return false;
        }

        // For consecutive long vowels: if last_output is "ー", use last_vowel_type
        let vowel_type_to_check = if last_output == "ー" {
            last_vowel_type.as_deref()
        } else {
            Self::get_vowel_type(last_output)
        };

        // Check if current input is a vowel that extends the previous sound
        match (vowel_type_to_check, current_vowel_key) {
            (Some("a"), "a") => true,
            (Some("i"), "i") => true,
            (Some("u"), "u") => true,
            (Some("e"), "e") | (Some("e"), "i") => true,  // え + い = えい or えー
            (Some("o"), "o") | (Some("o"), "u") => true,  // お + う = おう or おー
            _ => false,
        }
    }

    /// Process a key press
    pub fn process_key(
        key: &str,
        buffer: &str,
        profile_id: &str,
        last_output: &str,
        last_vowel_type: &Option<String>,
    ) -> Result<ConversionResult, String> {
        let engine_lock = ENGINE
            .read()
            .map_err(|_| "Failed to acquire read lock".to_string())?;

        let engine = engine_lock
            .as_ref()
            .ok_or("Engine not initialized".to_string())?;

        // Find the profile
        let profile = engine
            .profiles
            .iter()
            .find(|p| p.id == profile_id)
            .ok_or_else(|| format!("Profile not found: {}", profile_id))?;

        // Get the schema
        let schema = engine
            .schemas
            .get(&profile.input_schema_id)
            .ok_or_else(|| format!("Schema not loaded: {}", profile.input_schema_id))?;

        // Check for sokuon (促音): double consonant
        // If buffer contains a single character and new key is the same consonant,
        // output っ (sokuon) and reset buffer to that consonant
        // NOTE: Н is excluded because it's the special ん mora and cannot be doubled
        if !buffer.is_empty() && buffer == key && Self::can_create_sokuon(key) {
            if let Some(sokuon) = engine.kana_engine.get("sokuon") {
                // っ has no vowel type (it's a consonant placeholder)
                return Ok(ConversionResult {
                    output: sokuon.clone(),
                    buffer: key.to_string(),
                    action: "commit".to_string(),
                    last_output: sokuon.clone(),
                    last_vowel_type: None,
                });
            }
        }

        // Update buffer with new key
        let new_buffer = format!("{}{}", buffer, key);

        // Check for long vowel (chōonpu)
        // If the new input is a vowel that extends the previous mora, output ー
        if let Some(entry) = schema.get(&new_buffer) {
            if buffer.is_empty() && Self::is_long_vowel(last_output, last_vowel_type, &entry.kana_key) {
                // Preserve the vowel type through the long vowel mark
                // If last_output was "ー", inherit its vowel type; otherwise get from last_output
                let preserved_vowel_type = if last_output == "ー" {
                    last_vowel_type.clone()
                } else {
                    Self::get_vowel_type(last_output).map(|s| s.to_string())
                };

                return Ok(ConversionResult {
                    output: "ー".to_string(),
                    buffer: String::new(),
                    action: "commit".to_string(),
                    last_output: "ー".to_string(),
                    last_vowel_type: preserved_vowel_type,
                });
            }
        }

        // Try to match the new buffer
        if let Some(entry) = schema.get(&new_buffer) {
            // Found an exact match, but for Н (which can be both a complete mora
            // and a prefix), we need to check if it could be the start of a longer
            // sequence before committing
            let should_buffer = new_buffer == "Н" &&
                schema.keys().any(|k| k.starts_with("Н") && k.len() > 1);

            if should_buffer {
                // Keep Н in buffer as it might combine with the next character
                return Ok(ConversionResult::composing(new_buffer));
            }

            // Commit the match
            if let Some(hiragana) = engine.kana_engine.get(&entry.kana_key) {
                // Track the vowel type for this hiragana
                let vowel_type = Self::get_vowel_type(&hiragana).map(|s| s.to_string());
                return Ok(ConversionResult {
                    output: hiragana.clone(),
                    buffer: String::new(),
                    action: "commit".to_string(),
                    last_output: hiragana.clone(),
                    last_vowel_type: vowel_type,
                });
            } else {
                // Kana key not found in engine (should not happen with valid data)
                let vowel_type = Self::get_vowel_type(&entry.kana_key).map(|s| s.to_string());
                return Ok(ConversionResult {
                    output: entry.kana_key.clone(),
                    buffer: String::new(),
                    action: "commit".to_string(),
                    last_output: entry.kana_key.clone(),
                    last_vowel_type: vowel_type,
                });
            }
        }

        // No exact match, check if this could be a prefix
        let has_prefix = schema.keys().any(|k| k.starts_with(&new_buffer));

        if has_prefix {
            // This could be the start of a longer sequence
            Ok(ConversionResult::composing(new_buffer))
        } else {
            // No possible match, check if single key matches
            if let Some(entry) = schema.get(key) {
                if let Some(hiragana) = engine.kana_engine.get(&entry.kana_key) {
                    // Commit the single key, keep old buffer
                    let vowel_type = Self::get_vowel_type(&hiragana).map(|s| s.to_string());
                    return Ok(ConversionResult {
                        output: hiragana.clone(),
                        buffer: buffer.to_string(),
                        action: "commit".to_string(),
                        last_output: hiragana.clone(),
                        last_vowel_type: vowel_type,
                    });
                }
            }

            // Nothing matches, clear buffer
            Ok(ConversionResult::clear())
        }
    }

    /// Get all profiles
    pub fn get_profiles() -> Result<Vec<Profile>, String> {
        let engine_lock = ENGINE
            .read()
            .map_err(|_| "Failed to acquire read lock".to_string())?;

        let engine = engine_lock
            .as_ref()
            .ok_or("Engine not initialized".to_string())?;

        Ok(engine.profiles.clone())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_engine_initialization() {
        let profiles = r#"[
            {
                "id": "test_profile",
                "name_ja": "テスト",
                "name_en": "Test",
                "keyboardLayout": ["А", "И"],
                "inputSchemaId": "test_schema"
            }
        ]"#;

        let kana_engine = r#"{
            "a": "あ",
            "i": "い"
        }"#;

        // Note: This will fail if run multiple times in same process
        // For proper testing, use integration tests
        let _ = IMEEngine::init(profiles, kana_engine);
    }
}
