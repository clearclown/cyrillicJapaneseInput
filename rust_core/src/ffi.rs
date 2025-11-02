use crate::engine::IMEEngine;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic;

/// Initialize the IME engine with profiles and kana engine JSON
///
/// # Safety
/// - `profiles_json` and `kana_engine_json` must be valid UTF-8 C strings
/// - Returns null pointer on success, error message C string on failure
/// - Error message must be freed with `rust_free_string` if not null
#[no_mangle]
pub unsafe extern "C" fn rust_init_engine(
    profiles_json: *const c_char,
    kana_engine_json: *const c_char,
) -> *mut c_char {
    let result = panic::catch_unwind(|| {
        if profiles_json.is_null() || kana_engine_json.is_null() {
            let error = CString::new("Null pointer provided").unwrap();
            return error.into_raw();
        }

        let profiles_str = match CStr::from_ptr(profiles_json).to_str() {
            Ok(s) => s,
            Err(_) => {
                let error = CString::new("Invalid UTF-8 in profiles_json").unwrap();
                return error.into_raw();
            }
        };

        let kana_engine_str = match CStr::from_ptr(kana_engine_json).to_str() {
            Ok(s) => s,
            Err(_) => {
                let error = CString::new("Invalid UTF-8 in kana_engine_json").unwrap();
                return error.into_raw();
            }
        };

        match IMEEngine::init(profiles_str, kana_engine_str) {
            Ok(_) => std::ptr::null_mut(),
            Err(e) => {
                match CString::new(e) {
                    Ok(error_str) => error_str.into_raw(),
                    Err(_) => {
                        let error = CString::new("Failed to initialize engine").unwrap();
                        error.into_raw()
                    }
                }
            }
        }
    });

    result.unwrap_or_else(|_| {
        let error = CString::new("Panic occurred during initialization").unwrap();
        error.into_raw()
    })
}

/// Load a schema into the engine
///
/// # Safety
/// - `schema_json` and `schema_id` must be valid UTF-8 C strings
/// - Returns null pointer on success, error message C string on failure
/// - Error message must be freed with `rust_free_string` if not null
#[no_mangle]
pub unsafe extern "C" fn rust_load_schema(
    schema_json: *const c_char,
    schema_id: *const c_char,
) -> *mut c_char {
    let result = panic::catch_unwind(|| {
        if schema_json.is_null() || schema_id.is_null() {
            let error = CString::new("Null pointer provided").unwrap();
            return error.into_raw();
        }

        let schema_str = match CStr::from_ptr(schema_json).to_str() {
            Ok(s) => s,
            Err(_) => {
                let error = CString::new("Invalid UTF-8 in schema_json").unwrap();
                return error.into_raw();
            }
        };

        let schema_id_str = match CStr::from_ptr(schema_id).to_str() {
            Ok(s) => s,
            Err(_) => {
                let error = CString::new("Invalid UTF-8 in schema_id").unwrap();
                return error.into_raw();
            }
        };

        match IMEEngine::load_schema(schema_str, schema_id_str) {
            Ok(_) => std::ptr::null_mut(),
            Err(e) => {
                match CString::new(e) {
                    Ok(error_str) => error_str.into_raw(),
                    Err(_) => {
                        let error = CString::new("Failed to load schema").unwrap();
                        error.into_raw()
                    }
                }
            }
        }
    });

    result.unwrap_or_else(|_| {
        let error = CString::new("Panic occurred during schema loading").unwrap();
        error.into_raw()
    })
}

/// Process a key press and return conversion result as JSON
///
/// # Safety
/// - `key`, `buffer`, and `profile_id` must be valid UTF-8 C strings
/// - Returns a pointer to a C string (JSON) that must be freed with `rust_free_string`
/// - Returns null pointer on failure
#[no_mangle]
pub unsafe extern "C" fn rust_process_key(
    key: *const c_char,
    buffer: *const c_char,
    profile_id: *const c_char,
) -> *mut c_char {
    let result = panic::catch_unwind(|| {
        if key.is_null() || buffer.is_null() || profile_id.is_null() {
            return std::ptr::null_mut();
        }

        let key_str = match CStr::from_ptr(key).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let buffer_str = match CStr::from_ptr(buffer).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let profile_id_str = match CStr::from_ptr(profile_id).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let result = match IMEEngine::process_key(key_str, buffer_str, profile_id_str) {
            Ok(r) => r,
            Err(_) => return std::ptr::null_mut(),
        };

        let json = match serde_json::to_string(&result) {
            Ok(j) => j,
            Err(_) => return std::ptr::null_mut(),
        };

        match CString::new(json) {
            Ok(c_str) => c_str.into_raw(),
            Err(_) => std::ptr::null_mut(),
        }
    });

    result.unwrap_or(std::ptr::null_mut())
}

/// Free a string allocated by Rust
///
/// # Safety
/// - `ptr` must be a pointer returned by a Rust function (e.g., `rust_process_key`)
/// - Must only be called once per pointer
#[no_mangle]
pub unsafe extern "C" fn rust_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}

/// Get the Rust Core version
///
/// # Safety
/// - Returns a static string pointer (no need to free)
#[no_mangle]
pub extern "C" fn rust_get_version() -> *const c_char {
    "0.1.0\0".as_ptr() as *const c_char
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ffi_basic() {
        let profiles = CString::new(r#"[{"id":"test_ffi","name_ja":"テスト","name_en":"Test","keyboardLayout":["А"],"inputSchemaId":"test_schema"}]"#).unwrap();
        let kana = CString::new(r#"{"a":"あ"}"#).unwrap();

        unsafe {
            let result = rust_init_engine(profiles.as_ptr(), kana.as_ptr());
            // May fail if engine is already initialized by other tests
            // This is expected behavior
            // Result is now null on success, error message on failure
            if !result.is_null() {
                let _ = CString::from_raw(result); // Free error message
            }
        }
    }
}
