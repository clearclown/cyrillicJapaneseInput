# Testing Documentation

## Overview

This document describes the comprehensive test suite for the Cyrillic IME Core engine. The test suite ensures correctness, performance, thread safety, and robust error handling.

## Test Organization

### Test Types

1. **Unit Tests** (`tests/unit_*.rs`)
   - Test individual modules in isolation
   - Fast execution
   - High coverage of edge cases

2. **Integration Tests** (`tests/integration_*.rs`, `tests/engine_tests.rs`)
   - Test multiple components working together
   - Real-world scenarios
   - Uses actual profile data

3. **Concurrency Tests** (`tests/concurrency_tests.rs`)
   - Thread safety verification
   - Race condition detection
   - High contention scenarios

4. **FFI Tests** (`tests/ffi_tests.rs`)
   - C interface validation
   - Memory safety checks
   - iOS integration scenarios

5. **Error Handling Tests** (`tests/error_handling_tests.rs`)
   - Invalid input handling
   - Graceful failure modes
   - Edge case robustness

6. **Benchmarks** (`benches/conversion_benchmark.rs`)
   - Performance measurement
   - Latency tracking
   - Regression detection

## Test Files

### Unit Tests

#### `tests/unit_models.rs`
Tests for data structures and serialization:
- `ConversionResult` creation and serialization
- `Profile` deserialization from JSON
- `Schema` handling
- Unicode character support
- Empty and malformed data

**Coverage**: 18 tests

#### `tests/unit_engine.rs`
Tests for core engine logic:
- Engine initialization
- Schema loading
- Key processing with various buffer states
- Invalid profile/schema handling
- Prefix matching algorithm
- Buffer management

**Coverage**: 23 tests

### Integration Tests

#### `tests/engine_tests.rs`
End-to-end conversion scenarios:
- Russian alphabet conversion (А→あ, КА→か, КЯ→きゃ)
- Serbian special characters (Ћ→ち, Љ→りゃ, Њ→にゃ)
- Multi-character sequences
- Profile switching (КЯ vs КЈА→きゃ)
- Invalid sequence handling
- Composing state preservation

**Coverage**: 8 tests

#### `tests/integration_real_data.rs`
Tests using actual profile data from `../profiles/`:
- Loading real `profiles.json`
- Loading all schema files (Russian, Serbian, Ukrainian, Analytical)
- Complete word conversion (かさや)
- Profile switching consistency
- All schemas loadable

**Coverage**: 10 tests
**Note**: These tests skip gracefully if profile files are not found

### Concurrency Tests

#### `tests/concurrency_tests.rs`
Thread safety and concurrency:
- Concurrent reads (10 threads × 100 iterations)
- Concurrent schema loading
- Mixed operations (read/write/load)
- High contention (50 threads × 1000 iterations)
- Deadlock prevention
- Stress testing (100 threads × 100 operations)

**Coverage**: 10 tests
**Purpose**: Verify RwLock-based architecture is deadlock-free and race-condition-free

### FFI Tests

#### `tests/ffi_tests.rs`
C interface robustness:
- Initialization with valid/invalid data
- Null pointer handling
- Memory management (allocation/deallocation)
- Unicode string handling
- Rapid call testing (1000 calls)
- Large buffer handling (1000 char buffer)

**Coverage**: 16 tests
**Platform**: Primary target for iOS integration

### Error Handling Tests

#### `tests/error_handling_tests.rs`
Robustness and edge cases:
- Malformed JSON handling
- Missing/wrong-typed fields
- Empty inputs
- Invalid Unicode
- Nonexistent profiles/schemas
- Extremely long inputs (100k+ characters)
- Special characters and escaping
- Very large schemas (10k entries)

**Coverage**: 24 tests
**Purpose**: Ensure graceful degradation under all error conditions

### Benchmarks

#### `benches/conversion_benchmark.rs`
Performance measurements:
- Single character conversion
- Two/three character conversions
- Composing state handling
- Invalid sequence processing
- Schema loading speed
- Repeated conversions
- Buffer size impact
- Realistic typing sequences
- Worst-case prefix matching

**Metrics**:
- Latency (mean, median, std dev)
- Throughput (ops/sec)
- Memory allocation patterns

## Running Tests

### Run All Tests
```bash
cargo test
```

### Run Specific Test Suite
```bash
# Unit tests only
cargo test --test unit_models
cargo test --test unit_engine

# Integration tests
cargo test --test engine_tests
cargo test --test integration_real_data

# Concurrency tests
cargo test --test concurrency_tests

# FFI tests
cargo test --test ffi_tests

# Error handling tests
cargo test --test error_handling_tests
```

### Run Tests with Output
```bash
cargo test -- --nocapture
```

### Run Tests in Parallel (default)
```bash
cargo test -- --test-threads=4
```

### Run Tests Sequentially (for debugging)
```bash
cargo test -- --test-threads=1
```

### Run Benchmarks
```bash
cargo bench
```

### Run Benchmarks with Specific Pattern
```bash
cargo bench -- single_char
```

## Test Results

### Expected Performance

Based on benchmark results:
- Single character conversion: **~100-500ns**
- Two character conversion: **~200-800ns**
- Three character conversion: **~300-1000ns**
- Schema loading: **~1-10μs** (depending on schema size)
- Get profiles: **~50-200ns** (read-only operation)

### Coverage Goals

- **Unit Tests**: 90%+ code coverage
- **Integration Tests**: All critical user flows
- **Concurrency Tests**: No deadlocks, no race conditions
- **Error Tests**: All error paths covered

## Continuous Integration

### Pre-commit Checks
```bash
#!/bin/bash
cargo test --all
cargo clippy -- -D warnings
cargo fmt -- --check
```

### CI Pipeline (GitHub Actions)
```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: cargo test --all
      - run: cargo bench --no-run  # Ensure benchmarks compile
```

## Test Data

### Minimal Test Data (Embedded in Tests)
Used by most tests for fast execution:
- 1-2 profiles
- Small kana engine (3-10 entries)
- Minimal schema (3-10 mappings)

### Real Profile Data (External Files)
Used by `integration_real_data.rs`:
- `../profiles/profiles.json` (4 profiles)
- `../profiles/japaneseKanaEngine.json` (~80 entries)
- `../profiles/schemas/schema_*.json` (30-100 mappings each)

## Debugging Tests

### Run Single Test
```bash
cargo test test_russian_hiragana_conversion_real_data
```

### Debug with Print Statements
```rust
#[test]
fn test_debug_example() {
    println!("Debug info: {:?}", some_value);
    cargo test test_debug_example -- --nocapture
}
```

### Use Rust Backtrace
```bash
RUST_BACKTRACE=1 cargo test
```

### Use Debugger (lldb/gdb)
```bash
rust-lldb target/debug/deps/cyrillic_ime_core-<hash>
(lldb) b rust_core::engine::IMEEngine::process_key
(lldb) r
```

## Common Issues

### Test Fails: "Engine already initialized"
**Cause**: Global singleton can only be initialized once per process
**Solution**: Tests are designed to handle this gracefully. The engine persists across tests.

### Integration Test Skips: "required files not found"
**Cause**: Real profile data not available
**Solution**: Ensure `../profiles/` directory exists with JSON files

### Concurrency Test Intermittent Failures
**Cause**: True race condition or deadlock
**Solution**: Investigate with `--test-threads=1` and logging

### Benchmark Results Vary
**Cause**: System load, CPU frequency scaling
**Solution**: Run benchmarks on idle system, use `criterion`'s statistical analysis

## Test Maintenance

### Adding New Tests

1. Choose appropriate test file based on test type
2. Follow naming convention: `test_<feature>_<scenario>`
3. Use descriptive assertion messages
4. Clean up resources (though Rust handles this automatically)

Example:
```rust
#[test]
fn test_new_feature_basic_case() {
    // Arrange
    let input = setup_test_data();

    // Act
    let result = function_under_test(input);

    // Assert
    assert_eq!(result, expected, "Detailed failure message");
}
```

### Updating Test Data

When adding new profiles or schemas:
1. Update embedded test data in test files
2. Update real profile files in `../profiles/`
3. Add integration tests for new profile
4. Verify all tests still pass

## Performance Regression Detection

### Baseline Benchmarks
Run benchmarks and save results:
```bash
cargo bench -- --save-baseline master
```

### Compare Against Baseline
```bash
cargo bench -- --baseline master
```

### Performance Budgets
- Conversion operations: <1μs
- Schema loading: <10μs
- Memory usage: <1MB per loaded schema

## Code Coverage

### Generate Coverage Report
```bash
# Install tarpaulin
cargo install cargo-tarpaulin

# Generate HTML report
cargo tarpaulin --out Html --output-dir coverage/
```

### View Coverage
```bash
open coverage/index.html
```

## Testing Best Practices

1. **Test One Thing**: Each test should verify a single behavior
2. **Descriptive Names**: Test names should describe what they test
3. **Arrange-Act-Assert**: Structure tests clearly
4. **No Test Interdependence**: Tests should not depend on each other
5. **Fast Tests**: Unit tests should run in milliseconds
6. **Deterministic**: Tests should produce same result every time
7. **Maintainable**: Tests should be easy to understand and modify

## Future Test Additions

- [ ] Property-based testing (using `proptest`)
- [ ] Fuzz testing (using `cargo-fuzz`)
- [ ] Memory leak detection (using `valgrind`)
- [ ] Android JNI integration tests
- [ ] iOS XCUITest integration
- [ ] Performance regression tracking (CI integration)
