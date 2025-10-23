# Cyrillic IME Core (Rust)

Core conversion engine for the Cyrillic IME project, written in Rust for maximum performance and cross-platform compatibility.

## Architecture

This library implements the two-stage normalized mapping system:

```
Cyrillic Input → Phonetic Key → Hiragana Output
     (Schema)      (KanaEngine)
```

### Key Components

- **`engine.rs`**: Core IME engine with schema management and conversion logic
- **`models.rs`**: Data structures (Profile, Schema, ConversionResult)
- **`ffi.rs`**: C-compatible FFI interface for iOS (Swift)
- **`jni.rs`**: JNI interface for Android (Kotlin)

## Building

### For iOS

```bash
./build_ios.sh           # Debug build
./build_ios.sh --release # Release build
```

Output: `../mobile/iOS/CyrillicIMECore/libcyrillic_ime_core.a`

### For Android

```bash
./build_android.sh           # Debug build
./build_android.sh --release # Release build
```

Output: `../mobile/android/core/src/main/jniLibs/{arch}/libcyrillic_ime_core.so`

### Testing

```bash
cargo test
```

## API Documentation

### Initialization

```c
// iOS (C/Swift)
uint8_t rust_init_engine(const char* profiles_json, const char* kana_engine_json);
```

```kotlin
// Android (Kotlin/JNI)
NativeLib.initEngine(profilesJson: String, kanaEngineJson: String): Boolean
```

### Schema Loading

```c
// iOS
uint8_t rust_load_schema(const char* schema_json, const char* schema_id);
```

```kotlin
// Android
NativeLib.loadSchema(schemaJson: String, schemaId: String): Boolean
```

### Key Processing

```c
// iOS
char* rust_process_key(const char* key, const char* buffer, const char* profile_id);
// Returns JSON: {"output": "きゃ", "buffer": "", "action": "commit"}
// Must free with rust_free_string()
```

```kotlin
// Android
NativeLib.processKey(key: String, buffer: String, profileId: String): String?
// Returns JSON: {"output": "きゃ", "buffer": "", "action": "commit"}
```

## Conversion Logic

### State Machine

1. **User presses key**: e.g., `К`
2. **Buffer updated**: `buffer = "К"`
3. **Schema lookup**: Check if `"К"` matches
   - No exact match found
   - Has prefix match → return `composing("К")`
4. **User presses next key**: e.g., `Я`
5. **Buffer updated**: `buffer = "КЯ"`
6. **Schema lookup**: Check if `"КЯ"` matches
   - Exact match found → `kana_key = "kya"`
7. **Kana engine lookup**: `"kya"` → `"きゃ"`
8. **Return**: `commit("きゃ")`

### Actions

- **`commit`**: Output is ready, insert into text field, clear buffer
- **composing**: Building a sequence, keep buffer for next key
- **`clear`**: Invalid sequence, clear buffer

## Performance Characteristics

- **Latency**: O(1) HashMap lookups (constant time)
- **Memory**: All schemas loaded at initialization (~10KB per profile)
- **Binary Size**:
  - iOS (arm64): ~400KB (stripped)
  - Android (arm64-v8a): ~350KB (stripped)

## Design Philosophy

The two-stage mapping system provides:

1. **Maintainability**: Changing output format (hiragana → katakana) only requires editing `japaneseKanaEngine.json`
2. **Extensibility**: Adding new language profiles only requires creating a new schema JSON file
3. **Consistency**: Same phonetic keys across all profiles ensure output consistency

## Thread Safety

The engine uses `OnceCell` for lazy initialization and immutable data structures after initialization, making it safe for concurrent access from multiple threads.

## Error Handling

All FFI/JNI functions use `panic::catch_unwind()` to prevent Rust panics from unwinding into foreign code, ensuring stability of the host application.

## Dependencies

- `serde` + `serde_json`: JSON parsing
- `once_cell`: Lazy static initialization
- `jni` (Android only): JNI bindings

## License

MIT
