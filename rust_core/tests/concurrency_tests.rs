/// Concurrency and thread safety tests
use cyrillic_ime_core::IMEEngine;
use std::sync::Arc;
use std::thread;

const TEST_PROFILES: &str = r#"[
    {
        "id": "test_concurrent",
        "name_ja": "並行テスト",
        "name_en": "Concurrent Test",
        "keyboardLayout": ["А", "К", "Я"],
        "inputSchemaId": "schema_concurrent"
    }
]"#;

const TEST_KANA_ENGINE: &str = r#"{
    "a": "あ",
    "ka": "か",
    "kya": "きゃ"
}"#;

const TEST_SCHEMA: &str = r#"{
    "А": {"kana_key": "a"},
    "КА": {"kana_key": "ka"},
    "КЯ": {"kana_key": "kya"}
}"#;

#[test]
fn test_concurrent_reads() {
    // Initialize engine
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_concurrent");

    let mut handles = vec![];

    // Spawn 10 threads that all read concurrently
    for i in 0..10 {
        let handle = thread::spawn(move || {
            for _ in 0..100 {
                let result = IMEEngine::process_key("А", "", "test_concurrent");
                assert!(result.is_ok(), "Thread {} failed to process key", i);
                if let Ok(conv) = result {
                    assert_eq!(conv.output, "あ");
                }
            }
        });
        handles.push(handle);
    }

    // Wait for all threads to complete
    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_concurrent_schema_loading() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let mut handles = vec![];

    // Spawn 5 threads that load schemas concurrently
    for i in 0..5 {
        let schema = TEST_SCHEMA.to_string();
        let schema_id = format!("schema_concurrent_{}", i);

        let handle = thread::spawn(move || {
            let result = IMEEngine::load_schema(&schema, &schema_id);
            assert!(result.is_ok(), "Failed to load schema in thread {}", i);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_concurrent_mixed_operations() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_concurrent");

    let mut handles = vec![];

    // Spawn threads doing different operations
    for i in 0..20 {
        let handle = thread::spawn(move || {
            match i % 3 {
                0 => {
                    // Read operations
                    for _ in 0..50 {
                        let _ = IMEEngine::process_key("А", "", "test_concurrent");
                    }
                }
                1 => {
                    // Get profiles
                    for _ in 0..50 {
                        let _ = IMEEngine::get_profiles();
                    }
                }
                2 => {
                    // Load schemas
                    for j in 0..10 {
                        let schema_id = format!("schema_mixed_{}_{}", i, j);
                        let _ = IMEEngine::load_schema(TEST_SCHEMA, &schema_id);
                    }
                }
                _ => unreachable!(),
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_concurrent_processing_different_profiles() {
    let multi_profiles = r#"[
        {
            "id": "profile_1",
            "name_ja": "プロファイル1",
            "name_en": "Profile 1",
            "keyboardLayout": ["А"],
            "inputSchemaId": "schema_1"
        },
        {
            "id": "profile_2",
            "name_ja": "プロファイル2",
            "name_en": "Profile 2",
            "keyboardLayout": ["А"],
            "inputSchemaId": "schema_2"
        }
    ]"#;

    let _ = IMEEngine::init(multi_profiles, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_1");
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_2");

    let mut handles = vec![];

    for i in 0..10 {
        let handle = thread::spawn(move || {
            let profile_id = if i % 2 == 0 { "profile_1" } else { "profile_2" };

            for _ in 0..100 {
                let result = IMEEngine::process_key("А", "", profile_id);
                // May fail if profiles not found (engine initialized by other test)
                let _ = result;
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_high_contention_reads() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_concurrent");

    let mut handles = vec![];

    // Create high contention with 50 threads
    for i in 0..50 {
        let handle = thread::spawn(move || {
            for _ in 0..1000 {
                let result = IMEEngine::process_key("КЯ", "К", "test_concurrent");
                assert!(result.is_ok(), "Thread {} failed", i);
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_arc_wrapped_concurrent_access() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_concurrent");

    // Test that Arc wrapping works (engine is already behind a static)
    let counter = Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            for _ in 0..100 {
                let result = IMEEngine::process_key("А", "", "test_concurrent");
                if result.is_ok() {
                    counter.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
                }
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }

    let count = counter.load(std::sync::atomic::Ordering::SeqCst);
    assert_eq!(count, 1000, "All operations should have succeeded");
}

#[test]
fn test_no_deadlocks_with_rapid_schema_loading() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let mut handles = vec![];

    for i in 0..20 {
        let handle = thread::spawn(move || {
            for j in 0..50 {
                let schema_id = format!("rapid_schema_{}_{}", i, j);
                let _ = IMEEngine::load_schema(TEST_SCHEMA, &schema_id);
                // Immediately try to use it (may fail if not yet visible, that's ok)
                let _ = IMEEngine::process_key("А", "", "test_concurrent");
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked (possible deadlock)");
    }
}

#[test]
fn test_concurrent_get_profiles() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);

    let mut handles = vec![];

    for i in 0..20 {
        let handle = thread::spawn(move || {
            for _ in 0..100 {
                let result = IMEEngine::get_profiles();
                assert!(result.is_ok(), "Thread {} failed to get profiles", i);
                if let Ok(profiles) = result {
                    assert!(!profiles.is_empty());
                }
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }
}

#[test]
fn test_stress_test_all_operations() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "schema_concurrent");

    let mut handles = vec![];

    // Stress test with 100 threads doing random operations
    for i in 0..100 {
        let handle = thread::spawn(move || {
            for j in 0..100 {
                match (i + j) % 4 {
                    0 => {
                        let _ = IMEEngine::process_key("А", "", "test_concurrent");
                    }
                    1 => {
                        let _ = IMEEngine::process_key("КЯ", "К", "test_concurrent");
                    }
                    2 => {
                        let _ = IMEEngine::get_profiles();
                    }
                    3 => {
                        let schema_id = format!("stress_{}_{}", i, j);
                        let _ = IMEEngine::load_schema(TEST_SCHEMA, &schema_id);
                    }
                    _ => unreachable!(),
                }
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().expect("Thread panicked during stress test");
    }
}
