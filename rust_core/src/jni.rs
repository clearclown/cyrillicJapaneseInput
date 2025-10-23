use crate::engine::IMEEngine;
use jni::objects::{JClass, JString};
use jni::sys::{jboolean, jstring, JNI_FALSE, JNI_TRUE};
use jni::JNIEnv;
use std::panic;

/// Initialize the IME engine with profiles and kana engine JSON
#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_initEngine(
    mut env: JNIEnv,
    _class: JClass,
    profiles_json: JString,
    kana_engine_json: JString,
) -> jboolean {
    let result = panic::catch_unwind(|| {
        let profiles_str: String = match env.get_string(&profiles_json) {
            Ok(s) => s.into(),
            Err(_) => return JNI_FALSE,
        };

        let kana_engine_str: String = match env.get_string(&kana_engine_json) {
            Ok(s) => s.into(),
            Err(_) => return JNI_FALSE,
        };

        match IMEEngine::init(&profiles_str, &kana_engine_str) {
            Ok(_) => JNI_TRUE,
            Err(_) => JNI_FALSE,
        }
    });

    result.unwrap_or(JNI_FALSE)
}

/// Load a schema into the engine
#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_loadSchema(
    mut env: JNIEnv,
    _class: JClass,
    schema_json: JString,
    schema_id: JString,
) -> jboolean {
    let result = panic::catch_unwind(|| {
        let schema_str: String = match env.get_string(&schema_json) {
            Ok(s) => s.into(),
            Err(_) => return JNI_FALSE,
        };

        let schema_id_str: String = match env.get_string(&schema_id) {
            Ok(s) => s.into(),
            Err(_) => return JNI_FALSE,
        };

        match IMEEngine::load_schema(&schema_str, &schema_id_str) {
            Ok(_) => JNI_TRUE,
            Err(_) => JNI_FALSE,
        }
    });

    result.unwrap_or(JNI_FALSE)
}

/// Process a key press and return conversion result as JSON
#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_processKey(
    mut env: JNIEnv,
    _class: JClass,
    key: JString,
    buffer: JString,
    profile_id: JString,
) -> jstring {
    let result = panic::catch_unwind(|| {
        let key_str: String = match env.get_string(&key) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };

        let buffer_str: String = match env.get_string(&buffer) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };

        let profile_id_str: String = match env.get_string(&profile_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };

        let conversion_result = match IMEEngine::process_key(&key_str, &buffer_str, &profile_id_str) {
            Ok(r) => r,
            Err(_) => return std::ptr::null_mut(),
        };

        let json = match serde_json::to_string(&conversion_result) {
            Ok(j) => j,
            Err(_) => return std::ptr::null_mut(),
        };

        match env.new_string(json) {
            Ok(jstr) => jstr.into_raw(),
            Err(_) => std::ptr::null_mut(),
        }
    });

    result.unwrap_or(std::ptr::null_mut())
}

/// Get the Rust Core version
#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_getVersion(
    mut env: JNIEnv,
    _class: JClass,
) -> jstring {
    match env.new_string("0.1.0") {
        Ok(s) => s.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}
