# CLAUDE.md - Development Guidelines for Pismo IME

This file provides guidance to Claude Code (claude.ai/code) and developers when working with code in this repository.

---

## Project Identity

**Name**: Pismo (Письмо - Russian for "writing/letter")
**Purpose**: Cross-platform IME enabling Japanese hiragana input using Cyrillic keyboard layouts
**Core Philosophy**: "Simply replace the romaji part of Japanese romaji keyboard with Cyrillic characters"

**Current Status**: Production v1.0.0
- Requirements defined (`docs/要件定義書.md`)
- Test specifications completed (`docs/テスト仕様書.md`)
- iOS implementation Phase 2 completed (manual conversion)
- 5 language profiles with standard keyboard layouts
- Mock dictionary with 130+ entries

---

## Architectural Philosophy

### Two-Stage Normalized Mapping

**Input Flow**:
```
Cyrillic Character → Phonetic Key → Hiragana → Kanji
К + А → "ka" → "か" → "家" / "可愛い"
```

**Key Principle**: This indirection separates "how to type" (schema-specific) from "what it means" (universal phonetic mapping).

**Example**:
```
Russian:  КЯ  → "kya" → "きゃ"
Serbian:  КЈА → "kya" → "きゃ"
Analytical: Кьа → "kya" → "きゃ"
```

All three inputs produce the same hiragana because they map to the same phonetic key `"kya"`.

### Hybrid-Native Architecture

```
┌─────────────────────────────────────┐
│         Native UI Layer             │
│   (Swift iOS / Kotlin Android)      │
│  - Keyboard rendering               │
│  - Touch handling                   │
│  - OS integration                   │
└─────────────┬───────────────────────┘
              │ FFI/JNI
┌─────────────▼───────────────────────┐
│         Rust Core Engine            │
│  - Cyrillic → Phonetic conversion   │
│  - State machine                    │
│  - Buffer management                │
└─────────────┬───────────────────────┘
              │ JSON Data
┌─────────────▼───────────────────────┐
│         Configuration Files          │
│  - profiles.json                    │
│  - japaneseKanaEngine.json          │
│  - schema_*.json (5 languages)      │
└─────────────────────────────────────┘
```

**Design Decision**: Rust Core is shared across platforms via FFI (iOS) and JNI (Android), ensuring conversion logic consistency.

---

## Critical File Structure

### Configuration Files (profiles/)

#### `profiles.json`
**Purpose**: Defines available keyboard profiles with metadata and layout.

**Structure**:
```json
{
  "profiles": [
    {
      "id": "rus_standard",
      "name_ja": "ロシア語（標準）",
      "name_en": "Russian (Standard)",
      "keyboardLayout": {
        "row1": ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х", "Ъ"],
        "row2": ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
        "row3": ["Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю", "Ё"]
      },
      "inputSchemaId": "schema_rus_v1",
      "description": "Standard Russian JCUKEN (ЙЦУКЕН) keyboard layout"
    }
  ]
}
```

**Critical**: `inputSchemaId` MUST match a schema file in `profiles/schemas/`.

#### `japaneseKanaEngine.json`
**Purpose**: Universal phonetic key → hiragana mappings (language-agnostic).

**Structure**:
```json
{
  "kana_mappings": {
    "a": "あ",
    "ka": "か",
    "kya": "きゃ",
    "chi": "ち",
    "tsu": "つ",
    "n": "ん"
  }
}
```

**Rule**: NEVER modify this file when adding a new language profile. This is the universal phonetic mapping.

#### `profiles/schemas/schema_<language>_v1.json`
**Purpose**: Language-specific Cyrillic → phonetic key mappings.

**Example** (`schema_rus_v1.json`):
```json
{
  "version": "1.0.0",
  "language": "Russian",
  "mappings": {
    "А": {
      "kana_key": "a",
      "hintLabel": "@"
    },
    "КА": {
      "kana_key": "ka",
      "hintLabel": "か"
    },
    "КЯ": {
      "kana_key": "kya",
      "hintLabel": "きゃ"
    },
    "ЧИ": {
      "kana_key": "chi",
      "hintLabel": "ち"
    }
  }
}
```

**Key Points**:
- Multi-character sequences (КА, КЯ) are 2-key input patterns
- `hintLabel` is displayed on keys for user guidance
- All `kana_key` values MUST exist in `japaneseKanaEngine.json`

### Documentation Files (docs/)

#### `要件定義書.md` (Requirements)
**Purpose**: Complete functional and non-functional requirements.

**Critical Sections**:
- 5 language profiles with researched standard layouts
- Input methods (2-key, single-key, special cases)
- Performance targets: < 10ms input latency, < 50ms conversion
- **Testing is highest priority**: 80%+ unit test coverage
- **iOS standard keyboard design compliance**

#### `テスト仕様書.md` (Test Specifications)
**Purpose**: Comprehensive test suite with 560+ conversion test cases.

**Test Coverage**:
- 215 clean syllables (清音)
- 125 voiced consonants (濁音・半濁音)
- 165 contracted sounds (拗音)
- 55 special cases (促音・撥音・長音)
- Performance benchmarks
- iOS standard keyboard compliance tests

#### `cyrillicJapaneseInput.xlsx`
**Purpose**: SOURCE OF TRUTH for conversion specifications.

**Sheets**:
1. **Basic 50-on**: あいうえお rows
2. **Voiced consonants**: がぎぐげご
3. **Contracted sounds**: きゃきゅきょ
4. **Special cases**: ん, っ, ー

**Rule**: Any changes to conversion logic MUST be reflected in this Excel file first.

### iOS Implementation (mobile/iOS/)

#### `CyrillicInputManager.swift`
**Purpose**: Orchestrates entire input flow from keystroke to output.

**Key Responsibilities**:
- Manages composing text state (`CyrillicComposingText`)
- Calls Rust Core for conversion (`RustCoreFFI.processKey()`)
- Handles input modes (directCyrillic, japaneseHiragana, japaneseIME)
- Manages conversion candidates (Phase 2)
- Integrates live conversion (Phase 3)

**Critical Flow** (mobile/iOS/CyrillicKeyboard/Engine/CyrillicInputManager.swift:108-143):
```swift
func processKey(_ key: String) {
    let currentBuffer = composingText.cyrillicBuffer

    // Call Rust Core
    guard let result = rustCore.processKey(
        cyrillicKey: key,
        currentBuffer: currentBuffer,
        profileId: profile.id
    ) else { return }

    // Update composing text
    composingText.append(key: key, result: result)

    // Handle based on mode
    switch currentInputMode {
    case .directCyrillic:
        handleDirectCyrillicMode(result: result)
    case .japaneseHiragana:
        handleHiraganaMode(result: result)
    case .japaneseIME:
        handleIMEMode(result: result)
    }
}
```

#### `CyrillicKeyboardView.swift`
**Purpose**: Main keyboard UI rendering and touch handling.

**Design Requirement**: MUST exactly match iOS standard keyboard appearance.

**Critical Elements**:
- 3-row Cyrillic key layout (ЙЦУКЕН-based)
- Space, Delete, Return, Globe, Shift keys
- Buffer label showing uncommitted text
- Candidate bar for conversion (Phase 2)
- Spring animations on key press
- Haptic feedback

---

## Development Workflow

### Adding a New Language Profile

**Step 1**: Research Standard Keyboard Layout
- Find official keyboard layout specification (e.g., БДС 5237:2006 for Bulgarian)
- Verify with OSS projects (Linux keyboard layouts, Android AOSP)
- Document sources in requirements

**Step 2**: Create Schema File
```bash
# Create profiles/schemas/schema_bul_v1.json
{
  "version": "1.0.0",
  "language": "Bulgarian",
  "mappings": {
    "А": {"kana_key": "a"},
    "КА": {"kana_key": "ka"},
    "КЪ": {"kana_key": "ku"},  // Bulgarian Ъ = u sound
    // ... 560 total mappings
  }
}
```

**Step 3**: Update `profiles.json`
```json
{
  "id": "bul_bds",
  "name_ja": "ブルガリア語",
  "name_en": "Bulgarian",
  "keyboardLayout": {
    "row1": ["У", "Е", "И", "Ш", "Щ", "К", "С", "Д", "З", "Ц"],
    "row2": ["Ь", "Я", "А", "О", "Ж", "Г", "Т", "Н", "В", "М", "Ч"],
    "row3": ["Ю", "Й", "Ъ", "Ы", "Б", "П", "Р", "Л", "Х", "Ф"]
  },
  "inputSchemaId": "schema_bul_v1"
}
```

**Step 4**: Create Test Cases
- Add 111 test cases to `docs/テスト仕様書.md`
- Follow format: BUL-BASIC-001, BUL-VOICE-001, etc.
- Ensure 100% coverage of schema mappings

**Step 5**: Test Implementation
```swift
// In CyrillicInputManagerTests.swift
func testBulgarianProfile() {
    profileManager.currentProfileId = "bul_bds"

    inputManager.processKey("К")
    inputManager.processKey("Ъ")  // Ъ = u in Bulgarian

    XCTAssertEqual(inputManager.currentComposingText, "く")
}
```

**Step 6**: Update Excel Source
- Add new column to `docs/cyrillicJapaneseInput.xlsx`
- Document all Bulgarian-specific mappings
- Verify against schema JSON

### Making Code Changes

**Before Writing Code**:
1. Read requirements (`docs/要件定義書.md`)
2. Check test specifications (`docs/テスト仕様書.md`)
3. Verify current implementation status in README
4. Search for related code with `mcp__serena-mcp-server__find_symbol`

**TDD Workflow**:
```bash
# 1. Write failing test first
xcodebuild test -scheme CyrillicIMETests \
  -only-testing:CyrillicIMETests/ConversionEngineTests/testNewFeature

# 2. Implement feature
# Edit source files

# 3. Run tests again
xcodebuild test -scheme CyrillicIMETests

# 4. Verify coverage
xcov --scheme CyrillicIME --minimum_coverage_percentage 80
```

**Commit Checklist**:
- [ ] Unit tests pass (80%+ coverage)
- [ ] UI tests pass (main flows)
- [ ] Performance benchmarks met
- [ ] No memory leaks (Instruments)
- [ ] Code formatted (SwiftLint)
- [ ] Documentation updated

---

## Testing Requirements

### Highest Priority: Testing

**User Requirement**: "最優先はテストである" (Testing is the highest priority)

### Test Pyramid

```
┌─────────────────┐
│   E2E Tests     │ ← 10% (Main flows)
│   XCUITest      │
├─────────────────┤
│ Integration     │ ← 30% (All profiles × patterns)
│ Tests           │
├─────────────────┤
│  Unit Tests     │ ← 60% (80%+ coverage)
│  XCTest         │
└─────────────────┘
```

### Coverage Targets

| Test Type | Target | Tool |
|-----------|--------|------|
| Unit Tests | 80%+ | XCTest + xcov |
| UI Tests | 100% main flows | XCUITest |
| Integration | All 560 patterns | Manual matrix |
| Performance | All benchmarks | Instruments |

### Running Tests

```bash
# Unit tests
xcodebuild test -scheme CyrillicIME \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme CyrillicIMEUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Coverage report
xcov --scheme CyrillicIME \
  --minimum_coverage_percentage 80 \
  --html_report

# Rust Core tests
cd rust_core
cargo test --all
cargo tarpaulin --out Html
```

### Performance Benchmarks

| Metric | Target | Measurement |
|--------|--------|-------------|
| Input latency | < 10ms | CADisplayLink |
| Conversion speed | < 50ms | Stopwatch |
| Memory usage | < 50MB | Instruments Allocations |
| Battery consumption | ≈ iOS standard IME | Xcode Energy Log |

**Test Example** (from テスト仕様書.md):
```swift
func testKeyPressLatency() {
    let startTime = CACurrentMediaTime()
    inputManager.processKey("К")
    let endTime = CACurrentMediaTime()
    let latency = (endTime - startTime) * 1000 // ms
    XCTAssertLessThan(latency, 10.0, "Key press latency exceeded 10ms")
}
```

---

## iOS Standard Keyboard Compliance

### Design Philosophy

**Critical Requirement**: "デザインも特にiOS標準キーボードをそっくりにして欲しい" (Design must exactly match iOS standard keyboard)

### Visual Design Checklist

- [ ] **Key size**: Match iOS standard (varies by device)
- [ ] **Key spacing**: Match iOS standard gaps
- [ ] **Corner radius**: Use iOS standard rounded corners
- [ ] **Colors**:
  - [ ] Light mode: System background colors
  - [ ] Dark mode: System background colors
  - [ ] Use `UIColor.systemBackground`, `.secondarySystemBackground`
- [ ] **Fonts**: San Francisco with system font sizes
- [ ] **Shadows**: Match iOS key shadows

### Animation Requirements

**Key Press Animation** (CyrillicKeyboardView.swift:457-471):
```swift
private func animateButtonPress(_ button: UIButton) {
    // Scale down
    UIView.animate(withDuration: 0.1, animations: {
        button.transform = CGAffineTransform(scaleX: 0.95, scaleY: 0.95)
    }) { _ in
        // Scale back
        UIView.animate(withDuration: 0.1) {
            button.transform = .identity
        }
    }
}
```

**Haptic Feedback**:
```swift
let impactGenerator = UIImpactFeedbackGenerator(style: .light)
impactGenerator.impactOccurred()  // On key press

let notificationGenerator = UINotificationFeedbackGenerator()
notificationGenerator.notificationOccurred(.success)  // On conversion commit
```

### Accessibility Requirements

- [ ] VoiceOver: All keys have `accessibilityLabel`
- [ ] Dynamic Type: Support large text sizes
- [ ] Contrast: WCAG AA compliant (4.5:1 ratio)
- [ ] Tap targets: Minimum 44×44pt

**Test Cases** (テスト仕様書.md Section 5.3):
- A11Y-VO-001: VoiceOver reads all keys
- A11Y-VO-002: Buffer text is announced
- A11Y-FONT-001: Dynamic Type support
- A11Y-CONTRAST-001: 4.5:1 contrast ratio

---

## Common Patterns and Best Practices

### 1. Always Use Rust Core for Conversion

**❌ WRONG**:
```swift
// Do NOT implement conversion in Swift
func convertToHiragana(_ cyrillic: String) -> String {
    if cyrillic == "КА" { return "か" }  // NO!
    // ...
}
```

**✅ CORRECT**:
```swift
// Always use Rust Core
guard let result = rustCore.processKey(
    cyrillicKey: key,
    currentBuffer: currentBuffer,
    profileId: profile.id
) else { return }
```

**Reason**: Rust Core is the single source of truth, ensuring iOS and Android have identical conversion logic.

### 2. Never Hardcode Layouts

**❌ WRONG**:
```swift
let russianKeys = [["Й", "Ц", "У", ...]]  // NO!
```

**✅ CORRECT**:
```swift
let profile = profileManager.currentProfile
let rows = profile.keyboardLayout.rows  // From profiles.json
```

### 3. Test-First Development

**❌ WRONG**:
```swift
// Write feature, then test later
func newFeature() { ... }
```

**✅ CORRECT**:
```swift
// 1. Write failing test
func testNewFeature() {
    XCTAssertEqual(feature.result, expectedValue)  // Fails
}

// 2. Implement feature
func newFeature() { ... }

// 3. Test passes
```

### 4. Buffer Management

**Key Insight**: Cyrillic input requires buffer because some sounds need 2 characters (КА, КЯ).

**Pattern**:
```swift
// Current buffer: "К"
rustCore.processKey("А", currentBuffer: "К", profileId: "rus_standard")
// Result: { output: "か", buffer: "", action: "commit" }

// Current buffer: "К"
rustCore.processKey("К", currentBuffer: "К", profileId: "rus_standard")
// Result: { output: "っ", buffer: "к", action: "pending" }
```

### 5. State Machine Clarity

**Composing Text States**:
```
[Empty] → [Buffering] → [Converting] → [Committed] → [Empty]
  ↑          │              │              │
  │          └──────────────┘              │
  └────────────────────────────────────────┘
```

---

## Performance Optimization

### 1. Schema Lookups

**Implementation**: Use `HashMap` for O(1) lookups in Rust Core.

```rust
// Rust Core
let mut schema: HashMap<String, KanaMapping> = HashMap::new();
schema.insert("КА".to_string(), KanaMapping { kana_key: "ka" });

// O(1) lookup
if let Some(mapping) = schema.get(&input) {
    return Some(mapping.kana_key.clone());
}
```

### 2. Profile Caching

**Pattern**: Load profiles once at initialization, cache in memory.

```swift
class ProfileManager {
    private var profilesCache: [String: Profile] = [:]

    func loadProfiles() {
        // Load JSON once
        let profiles = parseProfilesJSON()
        profiles.forEach { profilesCache[$0.id] = $0 }
    }

    var currentProfile: Profile? {
        return profilesCache[currentProfileId]  // O(1)
    }
}
```

### 3. UI Rendering

**Avoid**: Re-rendering entire keyboard on every key press.

**Pattern**: Only update buffer label and candidate bar.

```swift
func processKey(_ key: String) {
    // Update only buffer label (not entire keyboard)
    bufferLabel.text = composingText.hiraganaTarget

    // Layout update is minimal
    bufferLabel.setNeedsLayout()
}
```

---

## Common Pitfalls

### 1. Forgetting Profile Context

**Problem**: Conversion depends on current profile.

**Solution**: Always pass `profileId` to Rust Core.

```swift
// ❌ WRONG
rustCore.processKey("К")  // Which profile?

// ✅ CORRECT
rustCore.processKey("К", profileId: profileManager.currentProfile.id)
```

### 2. Mixing Schema and Kana Engine

**Problem**: Adding language-specific mappings to `japaneseKanaEngine.json`.

**Solution**: `japaneseKanaEngine.json` is language-agnostic. Language-specific mappings go in `schema_<lang>_v1.json`.

```json
// ❌ WRONG - japaneseKanaEngine.json
{
  "kana_mappings": {
    "КА": "か"  // NO! This is Cyrillic, not phonetic
  }
}

// ✅ CORRECT - schema_rus_v1.json
{
  "mappings": {
    "КА": {"kana_key": "ka"}  // Cyrillic → phonetic
  }
}

// ✅ CORRECT - japaneseKanaEngine.json
{
  "kana_mappings": {
    "ka": "か"  // phonetic → hiragana
  }
}
```

### 3. Not Testing Edge Cases

**Common Edge Cases**:
- Double consonants: КК → っ
- Standalone ん: Н alone
- Syllable separation: Н + vowel = んあ
- Long vowels: ОО → ー

**Solution**: All edge cases are documented in `テスト仕様書.md` Section 2.1.4. Write tests for all.

### 4. Assuming Single-Key Input

**Problem**: Some hiragana require 2 Cyrillic characters (КА, КЯ).

**Solution**: Always use buffer and state machine.

```swift
// State machine handles multi-character sequences
processKey("К")  // Buffer: "К", Output: ""
processKey("А")  // Buffer: "", Output: "か"
```

---

## Debugging Strategies

### 1. Enable Verbose Logging

```swift
// In CyrillicInputManager.swift
print("[CyrillicInputManager] Key '\(key)' -> buffer: '\(result.buffer)', output: '\(result.output)'")
```

### 2. Use Instruments

```bash
# Profile memory
open -a Instruments
# Select Allocations template
# Record while using keyboard
# Check for memory leaks
```

### 3. Visual Debugging

```swift
// Add debug overlay showing internal state
#if DEBUG
let debugLabel = UILabel()
debugLabel.text = "Buffer: \(composingText.cyrillicBuffer) | Mode: \(currentInputMode)"
addSubview(debugLabel)
#endif
```

### 4. Unit Test Isolation

```swift
// Test conversion in isolation
func testConversionWithMockRustCore() {
    let mockCore = MockRustCoreFFI()
    mockCore.stubbedResult = ConversionResult(
        buffer: "",
        output: "か",
        action: "commit"
    )

    let manager = CyrillicInputManager(rustCore: mockCore)
    manager.processKey("КА")

    XCTAssertEqual(manager.currentComposingText, "か")
}
```

---

## Future Considerations

### Phase 2: Kanji Conversion

**Planned Integration**: azooKey KanaKanjiConverter or custom engine.

**Design Pattern**:
```swift
protocol KanjiConversionEngineProtocol {
    func getCandidates(hiragana: String) -> [String]
    func learn(hiragana: String, selected: String)
}

class AzooKeyConversionEngine: KanjiConversionEngineProtocol {
    func getCandidates(hiragana: String) -> [String] {
        // Call azooKey engine
    }
}
```

### Phase 3: Live Conversion

**Planned Features**:
- Automatic clause segmentation
- Real-time candidate display
- Clause navigation with arrow keys

**Architecture** (mobile/iOS/CyrillicKeyboard/Engine/LiveConversionManager.swift):
- Already implemented in current codebase
- Manages clauses and selected clause index
- Callbacks for UI updates

### Phase 5: Settings UI

**SwiftUI Settings App**:
```swift
struct SettingsView: View {
    @State private var selectedProfile: String = "rus_standard"

    var body: some View {
        Form {
            Picker("Profile", selection: $selectedProfile) {
                ForEach(profiles) { profile in
                    Text(profile.name_ja)
                }
            }
        }
    }
}
```

---

## Resources and References

### Internal Documentation
- `docs/要件定義書.md`: Requirements (functional/non-functional)
- `docs/テスト仕様書.md`: 560+ test cases
- `docs/cyrillicJapaneseInput.xlsx`: Conversion source of truth
- `README.md`: Project overview and philosophy

### External Standards
- **JCUKEN**: Russian keyboard layout (Wikipedia)
- **BDS 5237:2006**: Bulgarian keyboard standard
- **iOS Human Interface Guidelines**: Custom Keyboards section
- **WCAG 2.1**: Web Content Accessibility Guidelines (contrast, touch targets)

### Development Tools
- **XCTest**: Unit testing framework
- **XCUITest**: UI automation testing
- **Instruments**: Performance profiling (Allocations, Time Profiler, Leaks, Energy)
- **xcov**: Code coverage reporting
- **SwiftLint**: Swift style and conventions
- **cargo test**: Rust unit testing
- **cargo tarpaulin**: Rust code coverage

### Libraries and Frameworks
- **UIKit**: iOS keyboard UI (UIInputViewController)
- **SwiftUI**: Settings app UI
- **Natural Language Framework**: Text segmentation (Phase 3)
- **Rust Core**: Custom FFI library for conversion logic

---

## Quick Reference

### File Locations

```
cyrillicJapaneseInput/
├── docs/
│   ├── 要件定義書.md          # Requirements
│   ├── テスト仕様書.md         # Test specifications
│   └── cyrillicJapaneseInput.xlsx  # Conversion source of truth
├── profiles/
│   ├── profiles.json          # Profile definitions
│   ├── japaneseKanaEngine.json  # Universal kana mappings
│   └── schemas/
│       ├── schema_rus_v1.json  # Russian mappings
│       ├── schema_srb_v1.json  # Serbian mappings
│       ├── schema_ukr_v1.json  # Ukrainian mappings
│       ├── schema_bul_v1.json  # Bulgarian mappings
│       └── schema_rus_analytical_v1.json  # Analytical
├── mobile/
│   └── iOS/
│       ├── CyrillicKeyboard/
│       │   ├── Views/
│       │   │   ├── CyrillicKeyboardView.swift  # Main UI
│       │   │   └── CandidateBarView.swift      # Candidate display
│       │   ├── Engine/
│       │   │   ├── CyrillicInputManager.swift  # Input orchestration
│       │   │   ├── DisplayedTextManager.swift  # Text insertion
│       │   │   ├── LiveConversionManager.swift # Live conversion
│       │   │   └── KanjiConversionEngine.swift # Kanji conversion
│       │   ├── Models/
│       │   │   ├── Profile.swift               # Profile model
│       │   │   ├── CyrillicComposingText.swift # State model
│       │   │   └── Clause.swift                # Clause model
│       │   └── FFI/
│       │       └── RustCoreFFI.swift           # Rust bridge
│       └── CyrillicKeyboardTests/              # Unit tests
└── rust_core/                   # Rust conversion engine
    ├── src/
    │   ├── lib.rs               # FFI exports
    │   └── engine.rs            # Core logic
    └── tests/                   # Rust tests
```

### Key Commands

```bash
# iOS Development
xcodebuild test -scheme CyrillicIME -destination 'platform=iOS Simulator,name=iPhone 15'
xcov --scheme CyrillicIME --minimum_coverage_percentage 80
open mobile/iOS/CyrillicIME.xcodeproj

# Rust Development
cd rust_core
cargo test --all
cargo tarpaulin --out Html

# Profiling
instruments -t Allocations -D allocations.trace CyrillicIME.app
instruments -t "Time Profiler" -D profile.trace CyrillicIME.app
```

### Test Command Summary

```bash
# Full test suite
xcodebuild test -scheme CyrillicIME && cd rust_core && cargo test

# Coverage report
xcov --scheme CyrillicIME --html_report
open xcov_report/index.html

# Performance profiling
xcodebuild -scheme CyrillicIME -enableCodeCoverage YES test
```

---

## Contact and Support

For questions about this codebase:
1. Read this CLAUDE.md file first
2. Check `docs/要件定義書.md` for requirements
3. Check `docs/テスト仕様書.md` for test cases
4. Search codebase with `mcp__serena-mcp-server__find_symbol`
5. Consult README.md for project philosophy

**Development Philosophy**: Test-first, iOS-standard-compliant, performance-focused, maintainable through data-driven configuration.

---

**Version**: 1.0.0
**Last Updated**: 2025-11-22
**Status**: Production-ready documentation
