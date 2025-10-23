use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Profile definition matching profiles.json structure
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Profile {
    pub id: String,
    pub name_ja: String,
    pub name_en: String,
    #[serde(rename = "keyboardLayout")]
    pub keyboard_layout: Vec<String>,
    #[serde(rename = "inputSchemaId")]
    pub input_schema_id: String,
}

/// Schema entry for cyrillic -> kana_key mapping
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SchemaEntry {
    pub kana_key: String,
}

/// Type alias for schema mapping (Cyrillic sequence -> kana key)
pub type Schema = HashMap<String, SchemaEntry>;

/// Type alias for kana engine (kana key -> hiragana)
pub type KanaEngine = HashMap<String, String>;

/// Conversion result returned to native layer
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversionResult {
    /// Output text (hiragana or empty)
    pub output: String,

    /// Updated buffer state
    pub buffer: String,

    /// Action to take: "commit", "composing", "clear"
    pub action: String,
}

impl ConversionResult {
    pub fn commit(output: String) -> Self {
        Self {
            output,
            buffer: String::new(),
            action: "commit".to_string(),
        }
    }

    pub fn composing(buffer: String) -> Self {
        Self {
            output: String::new(),
            buffer,
            action: "composing".to_string(),
        }
    }

    pub fn clear() -> Self {
        Self {
            output: String::new(),
            buffer: String::new(),
            action: "clear".to_string(),
        }
    }
}
