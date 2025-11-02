# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a cross-platform IME (Input Method Editor) that allows users to input Japanese hiragana using Cyrillic keyboard layouts. The project demonstrates linguistic diversity by supporting multiple Cyrillic variants (Russian, Serbian, Ukrainian) where the same Japanese sound may require different keystrokes depending on the selected profile.

**Current Status**: Design phase. Core architecture documents and JSON schemas are complete. Implementation code (Rust/Swift/Kotlin) does not yet exist.

## Architecture Philosophy

### Two-Stage Normalized Mapping
The conversion follows: `Cyrillic Character → Phonetic Key → Hiragana`
- Example: `И` → `"i"` (phonetic key) → `い` (hiragana)
- This indirection separates "how to type" (schema-specific) from "what it means" (universal), enabling schema changes without touching the kana engine.

### Hybrid-Native Architecture
- **Core Engine** (Rust): Conversion logic, state machine, buffer management. Shared across platforms via FFI/JNI.
- **UI Shell** (Swift for iOS, Kotlin for Android): Platform-specific keyboard rendering and OS integration.
- **Data**: All conversion schemas are bundled as JSON files. No network required.

## Key Files and Their Roles

### Configuration Files
- `profiles/profiles.json`: Defines available keyboard profiles (id, display names, keyboard layout, schema reference)
- `profiles/japaneseKanaEngine.json`: Universal phonetic key → hiragana mappings (e.g., `"kya": "きゃ"`)
- `profiles/schemas/schema_*.json`: Profile-specific Cyrillic → phonetic key mappings

### Documentation
- `docs/要件定義書.md`: Requirements specification (functional/non-functional requirements)
- `docs/アプリ設計書.md`: Design document (architecture, component design, data flow)
- `README.md`: Project philosophy and technical overview

### Schema Structure
Each schema maps Cyrillic sequences to phonetic keys:
```json
{
  "КЯ": { "kana_key": "kya" },  // Russian: КЯ → "kya" → "きゃ"
  "КЈА": { "kana_key": "kya" }  // Serbian: КЈА → "kya" → "きゃ"
}
```

## Profile System

Profiles define how users input the same Japanese sounds using different Cyrillic layouts:
- **Russian Standard** (`rus_standard`): Uses `ЧИ` for "chi", `Я`/`Ю`/`Ё` for ya/yu/yo
- **Serbian** (`srb_cyrillic`): Uses `Ћ` for "chi", `Ј` + vowel for ya/yu/yo, special ligatures `Њ`/`Љ`/`Ђ`/`Џ`
- **Ukrainian** (`ukr_cyrillic`): Uses Ukrainian-specific letters `Ґ`/`Є`/`І`/`Ї`
- **Russian Analytical** (`rus_analytical`): Debug mode showing phonetic decomposition

## Data Flow

1. User taps Cyrillic key → Native UI captures keystroke
2. Native UI calls Rust Core's `process_key(key, buffer, profile_id)`
3. Rust Core:
   - Updates buffer (e.g., `"К"` → `"КЯ"`)
   - Looks up in profile schema: `"КЯ"` → `kana_key: "kya"`
   - Looks up in kana engine: `"kya"` → `"きゃ"`
   - Returns hiragana and buffer clear instruction
4. Native UI inserts hiragana via OS text input APIs

## Development Commands

**Note**: Implementation has not yet begun. When development starts:

### Planned Rust Core
- Build: `cargo build --release`
- Test: `cargo test`
- iOS cross-compile: `cargo lipo --release` (requires `cargo-lipo`)
- Android cross-compile: `cargo ndk --target <arch> build --release` (requires `cargo-ndk`)

### Planned iOS (Swift)
- Open: `open ios/CyrillicIME.xcodeproj`
- Build: Xcode Build (⌘B)
- Test: Xcode Test (⌘U)

### Planned Android (Kotlin)
- Open: Android Studio → `android/` directory
- Build: `./gradlew assembleDebug`
- Test: `./gradlew test`

## Design Constraints

### Non-Functional Requirements
- **Low Latency**: Keystroke → output must match native IME performance (no perceptible lag)
- **Offline-First**: All functionality works without network after installation
- **Maintainability**: Schema changes should not require code changes. Adding a new language profile only requires creating `schema_<lang>_v1.json`

### Scope Boundaries
- **In Scope**: Hiragana input via Cyrillic layouts, profile switching, basic special characters (促音 `っ`, 撥音 `ん`)
- **Out of Scope**: Kanji conversion (delegated to OS), katakana output, over-the-air schema updates in v1.0

## Adding a New Profile

1. Create `profiles/schemas/schema_<language>_v1.json` mapping Cyrillic sequences to phonetic keys
2. Add profile entry to `profiles/profiles.json`:
   ```json
   {
     "id": "bul_cyrillic",
     "name_ja": "ブルガリア語",
     "name_en": "Bulgarian",
     "keyboardLayout": ["А", "Б", ...],
     "inputSchemaId": "schema_bul_v1"
   }
   ```
3. **Do not modify** `japaneseKanaEngine.json` - it's language-agnostic

## Critical Implementation Notes

When implementing the Rust Core:
- Use `HashMap` for O(1) schema lookups
- Implement stateful buffer management for multi-character sequences (e.g., `КЯ`)
- Handle edge cases:
  - Double consonants → 促音 (`っ`): e.g., `КК` → `っk` buffer
  - `Н` alone → 撥音 (`ん`)
  - `Н` + vowel → `んあ`, `んい`, etc.

When implementing Native UI:
- Store `currentProfileId` in persistent storage (`UserDefaults`/`SharedPreferences`)
- On profile switch: update keyboard layout UI + notify Rust Core of new schema
- Pass all keystrokes through Rust Core - do not implement parallel conversion logic in native code
