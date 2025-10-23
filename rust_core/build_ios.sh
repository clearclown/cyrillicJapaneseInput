#!/bin/bash

set -e

echo "Building Rust Core for iOS..."

# Check if cargo-lipo is installed
if ! command -v cargo-lipo &> /dev/null; then
    echo "cargo-lipo not found. Installing..."
    cargo install cargo-lipo
fi

# Ensure iOS targets are installed
echo "Adding iOS targets..."
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim

# Build for iOS (universal binary)
if [ "$1" == "--release" ]; then
    echo "Building release version..."
    cargo lipo --release
    BUILD_TYPE="release"
else
    echo "Building debug version..."
    cargo lipo
    BUILD_TYPE="debug"
fi

# Create XCFramework directory structure
FRAMEWORK_DIR="../mobile/iOS/CyrillicIMECore"
mkdir -p "$FRAMEWORK_DIR"

# Create include directory for headers
mkdir -p "$FRAMEWORK_DIR/include"

# Generate C header file
cat > "$FRAMEWORK_DIR/include/cyrillic_ime_core.h" << 'EOF'
#ifndef CYRILLIC_IME_CORE_H
#define CYRILLIC_IME_CORE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize the IME engine with profiles and kana engine JSON.
 * Returns 1 on success, 0 on failure.
 */
uint8_t rust_init_engine(const char* profiles_json, const char* kana_engine_json);

/**
 * Load a schema into the engine.
 * Returns 1 on success, 0 on failure.
 */
uint8_t rust_load_schema(const char* schema_json, const char* schema_id);

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
EOF

# Copy the static library
LIB_PATH="target/universal/$BUILD_TYPE/libcyrillic_ime_core.a"
if [ -f "$LIB_PATH" ]; then
    cp "$LIB_PATH" "$FRAMEWORK_DIR/"
    echo "✅ iOS build complete!"
    echo "Library: $FRAMEWORK_DIR/libcyrillic_ime_core.a"
    echo "Headers: $FRAMEWORK_DIR/include/cyrillic_ime_core.h"
else
    echo "❌ Build failed: $LIB_PATH not found"
    exit 1
fi

# Instructions for Xcode integration
cat << 'EOF'

📱 Xcode Integration Instructions:
1. Add libcyrillic_ime_core.a to your Xcode project
2. Add include/ directory to Header Search Paths
3. Link against libresolv.tbd (required by Rust)
4. Import the header in your bridging header:
   #import "cyrillic_ime_core.h"

EOF
