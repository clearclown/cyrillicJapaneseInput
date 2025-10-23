# iOS Implementation

## Project Structure

This directory contains the iOS implementation of the Cyrillic IME for Japanese.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Rust 1.75 or later
- `cargo-lipo` for iOS cross-compilation

## Setup

### 1. Install Rust iOS Targets

```bash
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim
```

### 2. Install cargo-lipo

```bash
cargo install cargo-lipo
```

### 3. Build Rust Core

```bash
cd ../../rust_core
./build_ios.sh
```

### 4. Open Xcode Project

```bash
open CyrillicIME.xcodeproj
```

## Development Workflow

1. Make changes to Swift code in Xcode
2. If Rust Core changes are needed, rebuild with `./build_ios.sh`
3. Test on iOS Simulator or device
4. Commit logical units of work with descriptive messages

## Testing

### Unit Tests
```bash
xcodebuild test -scheme CyrillicIME -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### UI Tests
```bash
xcodebuild test -scheme CyrillicIMEUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Build

### Debug Build
```bash
xcodebuild -scheme CyrillicIME -configuration Debug -sdk iphonesimulator
```

### Release Build
```bash
xcodebuild -scheme CyrillicIME -configuration Release -archivePath build/CyrillicIME.xcarchive archive
```

## Directory Structure (To Be Created)

```
iOS/
├── CyrillicIME/                     # Main app (settings UI)
├── CyrillicKeyboard/                # Keyboard extension
├── CyrillicIMECore/                 # Rust Core library wrapper
├── CyrillicIMETests/                # Unit tests
└── CyrillicIMEUITests/              # UI tests
```

## Next Steps

See `docs/iOS開発計画書.md` for detailed implementation plan.
