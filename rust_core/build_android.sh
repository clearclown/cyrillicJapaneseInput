#!/bin/bash

set -e

echo "Building Rust Core for Android..."

# Check if cargo-ndk is installed
if ! command -v cargo-ndk &> /dev/null; then
    echo "cargo-ndk not found. Installing..."
    cargo install cargo-ndk
fi

# Check if ANDROID_NDK_HOME is set
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "⚠️  ANDROID_NDK_HOME not set. Trying to find NDK..."

    # Try common NDK locations
    if [ -d "$HOME/Android/Sdk/ndk" ]; then
        # Find the latest NDK version
        NDK_VERSION=$(ls -1 "$HOME/Android/Sdk/ndk" | sort -V | tail -n 1)
        export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/$NDK_VERSION"
        echo "Found NDK: $ANDROID_NDK_HOME"
    else
        echo "❌ ANDROID_NDK_HOME not found. Please set it manually:"
        echo "   export ANDROID_NDK_HOME=/path/to/android-ndk"
        exit 1
    fi
fi

# Ensure Android targets are installed
echo "Adding Android targets..."
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add i686-linux-android
rustup target add x86_64-linux-android

# Determine build type
if [ "$1" == "--release" ]; then
    echo "Building release version..."
    BUILD_FLAG="--release"
    BUILD_TYPE="release"
else
    echo "Building debug version..."
    BUILD_FLAG=""
    BUILD_TYPE="debug"
fi

# Build for all Android architectures
echo "Building for arm64-v8a..."
cargo ndk --target aarch64-linux-android --platform 29 build $BUILD_FLAG

echo "Building for armeabi-v7a..."
cargo ndk --target armv7-linux-androideabi --platform 29 build $BUILD_FLAG

echo "Building for x86..."
cargo ndk --target i686-linux-android --platform 29 build $BUILD_FLAG

echo "Building for x86_64..."
cargo ndk --target x86_64-linux-android --platform 29 build $BUILD_FLAG

# Create jniLibs directory structure
JNI_LIBS_DIR="../mobile/android/core/src/main/jniLibs"
mkdir -p "$JNI_LIBS_DIR"/{arm64-v8a,armeabi-v7a,x86,x86_64}

# Copy .so files to jniLibs
echo "Copying libraries to jniLibs..."
cp "target/aarch64-linux-android/$BUILD_TYPE/libcyrillic_ime_core.so" "$JNI_LIBS_DIR/arm64-v8a/"
cp "target/armv7-linux-androideabi/$BUILD_TYPE/libcyrillic_ime_core.so" "$JNI_LIBS_DIR/armeabi-v7a/"
cp "target/i686-linux-android/$BUILD_TYPE/libcyrillic_ime_core.so" "$JNI_LIBS_DIR/x86/"
cp "target/x86_64-linux-android/$BUILD_TYPE/libcyrillic_ime_core.so" "$JNI_LIBS_DIR/x86_64/"

echo "✅ Android build complete!"
echo ""
echo "Libraries copied to:"
echo "  - $JNI_LIBS_DIR/arm64-v8a/libcyrillic_ime_core.so"
echo "  - $JNI_LIBS_DIR/armeabi-v7a/libcyrillic_ime_core.so"
echo "  - $JNI_LIBS_DIR/x86/libcyrillic_ime_core.so"
echo "  - $JNI_LIBS_DIR/x86_64/libcyrillic_ime_core.so"
echo ""

# Display library sizes
echo "📊 Library sizes:"
du -h "$JNI_LIBS_DIR"/*/libcyrillic_ime_core.so

# Instructions for Android Studio integration
cat << 'EOF'

🤖 Android Studio Integration:
1. The .so files are now in core/src/main/jniLibs/
2. Create NativeLib.kt in the core module:

   package com.yourcompany.cyrillicime.core

   object NativeLib {
       init {
           System.loadLibrary("cyrillic_ime_core")
       }

       @JvmStatic
       external fun initEngine(profilesJson: String, kanaEngineJson: String): Boolean

       @JvmStatic
       external fun loadSchema(schemaJson: String, schemaId: String): Boolean

       @JvmStatic
       external fun processKey(key: String, buffer: String, profileId: String): String?

       @JvmStatic
       external fun getVersion(): String
   }

3. Sync Gradle and the libraries will be automatically included in your APK

EOF
