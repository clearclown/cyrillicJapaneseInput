#ifndef CYRILLIC_IME_CORE_H
#define CYRILLIC_IME_CORE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize the IME engine with profiles and kana engine JSON.
 * Returns NULL on success, error message C string on failure.
 * Error message must be freed with rust_free_string() if not NULL.
 */
char* rust_init_engine(const char* profiles_json, const char* kana_engine_json);

/**
 * Load a schema into the engine.
 * Returns NULL on success, error message C string on failure.
 * Error message must be freed with rust_free_string() if not NULL.
 */
char* rust_load_schema(const char* schema_json, const char* schema_id);

/**
 * Process a key press and return conversion result as JSON string.
 * The returned string must be freed with rust_free_string().
 * Returns NULL on failure.
 */
char* rust_process_key(const char* key, const char* buffer, const char* profile_id);

/**
 * Free a string allocated by Rust.
 */
void rust_free_string(char* ptr);

/**
 * Get the Rust Core version.
 * Returns a static string (no need to free).
 */
const char* rust_get_version(void);

#ifdef __cplusplus
}
#endif

#endif // CYRILLIC_IME_CORE_H
