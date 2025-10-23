# Android Implementation

## Project Structure

This directory contains the Android implementation of the Cyrillic IME for Japanese.

## Prerequisites

- JDK 17 or later
- Android Studio Hedgehog (2023.1.1) or later
- Android SDK 34
- Rust 1.75 or later
- `cargo-ndk` for Android cross-compilation
- Android NDK 26.0 or later

## Setup

### 1. Install Rust Android Targets

```bash
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add i686-linux-android
rustup target add x86_64-linux-android
```

### 2. Install cargo-ndk

```bash
cargo install cargo-ndk
```

### 3. Configure Android NDK Path

Add to `~/.cargo/config.toml`:

```toml
[target.aarch64-linux-android]
ar = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang"

[target.armv7-linux-androideabi]
ar = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang"

[target.i686-linux-android]
ar = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android29-clang"

[target.x86_64-linux-android]
ar = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang"
```

### 4. Build Rust Core

```bash
cd ../../rust_core
./build_android.sh
```

### 5. Open Android Studio Project

```bash
cd ../mobile/android
# Open this directory in Android Studio
```

## Development Workflow

1. Make changes to Kotlin code in Android Studio
2. If Rust Core changes are needed, rebuild with `./build_android.sh`
3. Test on Android Emulator or device
4. Commit logical units of work with descriptive messages

## Testing

### Unit Tests
```bash
./gradlew test
```

### Instrumented Tests (requires emulator/device)
```bash
./gradlew connectedAndroidTest
```

### Specific Test Class
```bash
./gradlew connectedAndroidTest --tests com.yourcompany.cyrillicime.ime.RustCoreJNITest
```

## Build

### Debug Build
```bash
./gradlew assembleDebug
```

### Release Build (AAB for Google Play)
```bash
./gradlew bundleRelease
```

### Release Build (APK)
```bash
./gradlew assembleRelease
```

### Install on Device
```bash
./gradlew installDebug
# or
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Directory Structure (To Be Created)

```
android/
├── app/                             # Main app (settings UI)
├── ime/                             # IME service module
├── core/                            # Rust Core JNI wrapper
├── build.gradle.kts                 # Root build configuration
├── settings.gradle.kts              # Module configuration
└── gradle.properties                # Gradle properties
```

## Debugging

### Enable IME in Android Settings
1. Settings → System → Languages & input → On-screen keyboard → Manage on-screen keyboards
2. Enable "Cyrillic IME"
3. In any text field, long-press the keyboard switcher icon
4. Select "Cyrillic IME"

### View Logs
```bash
adb logcat | grep CyrillicIME
```

### Attach Debugger
1. Run app in debug mode from Android Studio
2. IME service will automatically attach when activated

## Next Steps

See `docs/Android開発計画書.md` for detailed implementation plan.
