use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use cyrillic_ime_core::IMEEngine;

const TEST_PROFILES: &str = r#"[
    {
        "id": "bench_profile",
        "name_ja": "ベンチマーク",
        "name_en": "Benchmark",
        "keyboardLayout": ["А", "К", "Я"],
        "inputSchemaId": "bench_schema"
    }
]"#;

const TEST_KANA_ENGINE: &str = r#"{
    "a": "あ",
    "i": "い",
    "u": "う",
    "ka": "か",
    "ki": "き",
    "ku": "く",
    "kya": "きゃ",
    "kyu": "きゅ",
    "kyo": "きょ"
}"#;

const TEST_SCHEMA: &str = r#"{
    "А": {"kana_key": "a"},
    "И": {"kana_key": "i"},
    "У": {"kana_key": "u"},
    "КА": {"kana_key": "ka"},
    "КИ": {"kana_key": "ki"},
    "КУ": {"kana_key": "ku"},
    "КЯ": {"kana_key": "kya"},
    "КЮ": {"kana_key": "kyu"},
    "КЁ": {"kana_key": "kyo"}
}"#;

fn setup_engine() {
    let _ = IMEEngine::init(TEST_PROFILES, TEST_KANA_ENGINE);
    let _ = IMEEngine::load_schema(TEST_SCHEMA, "bench_schema");
}

fn bench_single_character_conversion(c: &mut Criterion) {
    setup_engine();

    c.bench_function("single_char_conversion", |b| {
        b.iter(|| {
            IMEEngine::process_key(
                black_box("А"),
                black_box(""),
                black_box("bench_profile")
            )
        })
    });
}

fn bench_two_character_conversion(c: &mut Criterion) {
    setup_engine();

    c.bench_function("two_char_conversion", |b| {
        b.iter(|| {
            IMEEngine::process_key(
                black_box("А"),
                black_box("К"),
                black_box("bench_profile")
            )
        })
    });
}

fn bench_three_character_conversion(c: &mut Criterion) {
    setup_engine();

    c.bench_function("three_char_conversion", |b| {
        b.iter(|| {
            IMEEngine::process_key(
                black_box("Я"),
                black_box("К"),
                black_box("bench_profile")
            )
        })
    });
}

fn bench_composing_state(c: &mut Criterion) {
    setup_engine();

    c.bench_function("composing_state", |b| {
        b.iter(|| {
            IMEEngine::process_key(
                black_box("К"),
                black_box(""),
                black_box("bench_profile")
            )
        })
    });
}

fn bench_invalid_sequence(c: &mut Criterion) {
    setup_engine();

    c.bench_function("invalid_sequence", |b| {
        b.iter(|| {
            IMEEngine::process_key(
                black_box("У"),
                black_box("К"),
                black_box("bench_profile")
            )
        })
    });
}

fn bench_get_profiles(c: &mut Criterion) {
    setup_engine();

    c.bench_function("get_profiles", |b| {
        b.iter(|| {
            IMEEngine::get_profiles()
        })
    });
}

fn bench_schema_loading(c: &mut Criterion) {
    setup_engine();

    let mut counter = 0;
    c.bench_function("schema_loading", |b| {
        b.iter(|| {
            counter += 1;
            IMEEngine::load_schema(
                black_box(TEST_SCHEMA),
                black_box(&format!("bench_schema_{}", counter))
            )
        })
    });
}

fn bench_repeated_conversions(c: &mut Criterion) {
    setup_engine();

    c.bench_function("repeated_10_conversions", |b| {
        b.iter(|| {
            for _ in 0..10 {
                let _ = IMEEngine::process_key("А", "", "bench_profile");
            }
        })
    });
}

fn bench_buffer_sizes(c: &mut Criterion) {
    setup_engine();

    let mut group = c.benchmark_group("buffer_sizes");

    for size in [0, 1, 5, 10, 50].iter() {
        let buffer = "К".repeat(*size);
        group.bench_with_input(BenchmarkId::from_parameter(size), size, |b, _| {
            b.iter(|| {
                IMEEngine::process_key(
                    black_box("А"),
                    black_box(&buffer),
                    black_box("bench_profile")
                )
            })
        });
    }

    group.finish();
}

fn bench_realistic_typing_sequence(c: &mut Criterion) {
    setup_engine();

    c.bench_function("realistic_word_typing", |b| {
        b.iter(|| {
            // Simulate typing "かきくけこ" (KA-KI-KU-KE-KO)
            let _ = IMEEngine::process_key("К", "", "bench_profile");
            let _ = IMEEngine::process_key("А", "К", "bench_profile");

            let _ = IMEEngine::process_key("К", "", "bench_profile");
            let _ = IMEEngine::process_key("И", "К", "bench_profile");

            let _ = IMEEngine::process_key("К", "", "bench_profile");
            let _ = IMEEngine::process_key("У", "К", "bench_profile");
        })
    });
}

fn bench_worst_case_prefix_matching(c: &mut Criterion) {
    setup_engine();

    c.bench_function("worst_case_prefix_matching", |b| {
        b.iter(|| {
            // Test case where we have to check many prefixes
            // К has prefixes: КА, КИ, КУ, КЯ, КЮ, КЁ
            IMEEngine::process_key(
                black_box("К"),
                black_box(""),
                black_box("bench_profile")
            )
        })
    });
}

criterion_group!(
    benches,
    bench_single_character_conversion,
    bench_two_character_conversion,
    bench_three_character_conversion,
    bench_composing_state,
    bench_invalid_sequence,
    bench_get_profiles,
    bench_schema_loading,
    bench_repeated_conversions,
    bench_buffer_sizes,
    bench_realistic_typing_sequence,
    bench_worst_case_prefix_matching,
);

criterion_main!(benches);
