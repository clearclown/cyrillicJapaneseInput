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

    /// Process a key press
    pub fn process_key(
        key: &str,
        buffer: &str,
        profile_id: &str,
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

        // Update buffer with new key
        let new_buffer = format!("{}{}", buffer, key);

        // Try to match the new buffer
        if let Some(entry) = schema.get(&new_buffer) {
            // Found a match, convert to hiragana
            if let Some(hiragana) = engine.kana_engine.get(&entry.kana_key) {
                return Ok(ConversionResult::commit(hiragana.clone()));
            } else {
                // Kana key not found in engine (should not happen with valid data)
                return Ok(ConversionResult::commit(entry.kana_key.clone()));
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
                    return Ok(ConversionResult {
                        output: hiragana.clone(),
                        buffer: buffer.to_string(),
                        action: "commit".to_string(),
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
