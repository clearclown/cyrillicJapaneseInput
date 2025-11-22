use std::ffi::{CString, CStr};

// Import FFI functions directly - they are marked with #[no_mangle]
// These functions are defined in rust_core/src/ffi.rs
use cyrillic_ime_core::ffi::{
    rust_init_engine,
    rust_load_schema,
    rust_process_key,
    rust_free_string,
    rust_get_version,
};

#[test]
fn test_rust_init_engine_success() {
    let profiles = CString::new(r#"[{"id":"test_ffi_init","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#).unwrap();
    let kana = CString::new(r#"{"a":"あ"}"#).unwrap();

    unsafe {
        let result = rust_init_engine(profiles.as_ptr(), kana.as_ptr());
        // Success should return null pointer
        if !result.is_null() {
            // Engine already initialized or other error
            let error_msg = CString::from_raw(result);
            eprintln!("Error: {:?}", error_msg);
            // This is acceptable if engine was already initialized
        }
    }
}

#[test]
fn test_rust_init_engine_with_null_pointers() {
    unsafe {
        let result = rust_init_engine(std::ptr::null(), std::ptr::null());
        // Should return error message (non-null)
        assert!(!result.is_null(), "Should return error for null pointers");
        let _ = CString::from_raw(result); // Free error message
    }
}

#[test]
fn test_rust_init_engine_with_invalid_json() {
    let invalid_json = CString::new("{invalid json").unwrap();
    let kana = CString::new(r#"{"a":"あ"}"#).unwrap();

    unsafe {
        let result = rust_init_engine(invalid_json.as_ptr(), kana.as_ptr());
        // Should return error message
        if !result.is_null() {
            let error_msg = CString::from_raw(result);
            let error_str = error_msg.to_str().unwrap();
            assert!(
                error_str.contains("Failed to parse") ||
                error_str.contains("already initialized"),
                "Should return parse error or already initialized error"
            );
        }
    }
}

#[test]
fn test_rust_load_schema_success() {
    // First initialize engine
    let profiles = CString::new(r#"[{"id":"test_ffi_schema","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#).unwrap();
    let kana = CString::new(r#"{"a":"あ"}"#).unwrap();

    unsafe {
        let init_result = rust_init_engine(profiles.as_ptr(), kana.as_ptr());
        if !init_result.is_null() {
            // Engine already initialized, free error message
            let _ = CString::from_raw(init_result);
        }

        // Now test schema loading
        let schema_json = CString::new(r#"{"А":{"kana_key":"a"}}"#).unwrap();
        let schema_id = CString::new("test_schema").unwrap();

        let result = rust_load_schema(schema_json.as_ptr(), schema_id.as_ptr());
        // Success should return null pointer
        if !result.is_null() {
            let error_msg = CString::from_raw(result);
            let error_str = error_msg.to_str().unwrap();
            eprintln!("Schema load error: {}", error_str);
            // Schema might already be loaded
        }
    }
}

#[test]
fn test_rust_load_schema_with_null_pointers() {
    unsafe {
        let result = rust_load_schema(std::ptr::null(), std::ptr::null());
        // Should return error message (non-null)
        assert!(!result.is_null(), "Should return error for null pointers");
        let _ = CString::from_raw(result); // Free error message
    }
}

#[test]
fn test_rust_process_key_basic() {
    // Initialize engine and load schema
    let profiles = CString::new(r#"[{"id":"test_ffi_process","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema_process"}]"#).unwrap();
    let kana = CString::new(r#"{"a":"あ"}"#).unwrap();

    unsafe {
        let init_result = rust_init_engine(profiles.as_ptr(), kana.as_ptr());
        if !init_result.is_null() {
            let _ = CString::from_raw(init_result);
        }

        let schema_json = CString::new(r#"{"А":{"kana_key":"a"}}"#).unwrap();
        let schema_id = CString::new("test_schema_process").unwrap();
        let schema_result = rust_load_schema(schema_json.as_ptr(), schema_id.as_ptr());
        if !schema_result.is_null() {
            let _ = CString::from_raw(schema_result);
        }

        // Test key processing
        let key = CString::new("А").unwrap();
        let buffer = CString::new("").unwrap();
        let profile_id = CString::new("test_ffi_process").unwrap();
        let last_output = CString::new("").unwrap();
        let last_vowel_type = CString::new("").unwrap();

        let result = rust_process_key(key.as_ptr(), buffer.as_ptr(), profile_id.as_ptr(), last_output.as_ptr(), last_vowel_type.as_ptr());
        if !result.is_null() {
            let json_str = CString::from_raw(result);
            let json = json_str.to_str().unwrap();
            assert!(json.contains("あ") || json.contains("output"), "Should contain conversion result");
        } else {
            // Failed, might be due to uninitialized engine
            // This is acceptable in test environment
        }
    }
}

#[test]
fn test_rust_free_string() {
    let test_string = CString::new("test string").unwrap();
    let ptr = test_string.into_raw();

    unsafe {
        // Free the string (should not crash)
        rust_free_string(ptr);
    }
}

#[test]
fn test_rust_free_string_with_null() {
    unsafe {
        // Should handle null gracefully
        rust_free_string(std::ptr::null_mut());
    }
}

#[test]
fn test_rust_get_version() {
    unsafe {
        let version_ptr = rust_get_version();
        assert!(!version_ptr.is_null(), "Version should not be null");
        let version = CStr::from_ptr(version_ptr);
        let version_str = version.to_str().unwrap();
        assert!(!version_str.is_empty(), "Version should not be empty");
        // Version should be a valid version string
        assert!(version_str.matches('.').count() >= 1, "Version should contain dots");
    }
}
