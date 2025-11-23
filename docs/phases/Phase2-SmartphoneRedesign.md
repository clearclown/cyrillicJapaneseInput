# Phase 2: Smartphone-Appropriate IME Redesign

**Date**: 2025-11-23
**Status**: ✅ COMPLETE (Code changes done, tests need updating)

## Problem Analysis

### Current Design (WRONG for Smartphones)

The current implementation follows a **desktop IME paradigm**:

❌ Mode switcher UI with 4 modes (АБВ, あ, ア, あ変)
❌ Manual space-key triggered conversion
❌ Complex mode management with UserDefaults persistence
❌ User must explicitly choose when to convert

**Code Evidence**:
- `InputMode` enum with 4 cases (Shared/Models/InputMode.swift:11-22)
- Mode toggle button (CyrillicKeyboard/Views/CyrillicKeyboardView.swift:291)
- Space key conversion (CyrillicKeyboard/Engine/CyrillicInputManager.swift:274-294)
- Mode conditionals throughout codebase

### Required Design (Smartphone-Appropriate)

Following **azooKey architecture** for smartphones:

✅ Single Japanese IME mode only
✅ Automatic live conversion as user types
✅ Space key just inserts space character
✅ No mode switcher UI needed

**Reference**: azooKey (docs/repos/azooKey/)
- `LiveConversionManager` handles automatic conversion (Keyboard/Display/LiveConversionManager.swift)
- `InputManager` delegates to LiveConversionManager automatically (Keyboard/Display/InputManager.swift:27)
- No manual mode switching

## User Feedback

> "「アああ変」この機能はいらない．わざわざスペースで変換はしない．スマホ向けだよ．これ，もう一度設計し直して．"

Translation:
> "The 'ア あ あ変' function is not needed. Don't do manual conversion with space key. This is for smartphones. Redesign this again."

## Implementation Plan

### Step 1: Simplify InputMode Enum ✅

**File**: `Shared/Models/InputMode.swift`

**Change**: Keep only `.japaneseIME` mode, remove all others.

```swift
// BEFORE (4 modes)
enum InputMode: String, Codable, CaseIterable {
    case directCyrillic      // АБВ
    case japaneseHiragana    // あ
    case japaneseKatakana    // ア
    case japaneseIME         // あ変
}

// AFTER (single mode - smartphone appropriate)
enum InputMode: String, Codable {
    case japaneseIME  // Only mode needed for smartphone IME

    var displayNameJa: String {
        return "日本語（IME）"
    }

    var displayNameEn: String {
        return "Japanese (IME)"
    }
}
```

**Rationale**: Smartphone keyboards don't need mode switching. Always Japanese IME with automatic conversion.

### Step 2: Remove Mode Switcher Button

**File**: `CyrillicKeyboard/Views/CyrillicKeyboardView.swift`

**Remove**:
- Line 86: `private var inputModeButton: UIButton?`
- Lines 290-294: Input mode button creation
- Lines 471-527: `handleInputModeToggle()` method
- Lines 528-530: `updateInputModeButton()` method
- Lines 77-82: `inputMode` computed property (use constant instead)

**Add**: Globe button for switching between keyboards (iOS standard)

```swift
// BEFORE
let inputModeBtn = createKeyButton(title: inputMode.shortName, action: #selector(handleInputModeToggle))
inputModeButton = inputModeBtn

// AFTER (remove button entirely)
// No mode button needed - always in japaneseIME mode
```

### Step 3: Simplify Space Key Handling

**File**: `CyrillicKeyboard/Engine/CyrillicInputManager.swift`

**Change**: Remove conversion logic from `processSpace()`, just commit and insert space.

```swift
// BEFORE (lines 274-294)
func processSpace() {
    if currentInputMode == .japaneseIME && !composingText.isEmpty {
        if isLiveConversionEnabled {
            liveConversionManager.cycleSelectedClauseCandidate()
        } else if isConverting {
            cycleToNextCandidate()
        } else {
            startConversion()  // MANUAL CONVERSION (wrong for smartphones)
        }
    } else {
        commitIfNeeded()
        displayedTextManager.insertText(" ")
    }
}

// AFTER (smartphone-appropriate)
func processSpace() {
    // Commit any live conversion, then insert space
    if !composingText.isEmpty {
        commitLiveConversion()
    }
    displayedTextManager.insertText(" ")
}
```

**Rationale**: Space is just space. Conversion happens automatically via `LiveConversionManager`.

### Step 4: Remove Mode Conditionals from CyrillicInputManager

**File**: `CyrillicKeyboard/Engine/CyrillicInputManager.swift`

**Remove**:
- Lines 192-228: `handleDirectCyrillicMode()`, `handleHiraganaMode()`, `handleKatakanaMode()`
- Lines 142-145: Mode switch in `processKey()`
- Line 50-52: `isLiveConversionEnabled` property (always true)
- Lines 296-394: Manual conversion methods (`startConversion()`, `cycleToNextCandidate()`, etc.)

**Simplify**: `processKey()` always uses live conversion

```swift
// BEFORE (complex mode switching)
func processKey(_ key: String) {
    // ... conversion logic ...

    switch currentInputMode {
    case .directCyrillic:
        handleDirectCyrillicMode(result: result)
    case .japaneseHiragana:
        handleHiraganaMode(result: result)
    case .japaneseKatakana:
        handleKatakanaMode(result: result)
    case .japaneseIME:
        handleIMEMode(result: result)
    }
}

// AFTER (always IME with live conversion)
func processKey(_ key: String) {
    // ... conversion logic ...

    // Always use live conversion (smartphone paradigm)
    let hiragana = composingText.hiraganaTarget
    liveConversionManager.processInput(hiragana)
    // Display updates via callback
}
```

### Step 5: Remove UserDefaults InputMode Storage

**File**: `Shared/Extensions/UserDefaults+AppGroup.swift`

**Remove**:
- Lines 27: `static let currentInputMode = "current_input_mode"` key
- Lines 50-61: `currentInputMode` property

**Rationale**: No mode to store - always japaneseIME.

### Step 6: Update KeyboardViewController

**File**: `CyrillicKeyboard/KeyboardViewController.swift`

**Remove**:
- Line 200: `inputManager.setInputMode(view.currentInputMode)`
- Mode-related delegate calls

### Step 7: Enable Live Conversion by Default

**File**: `CyrillicKeyboard/Engine/LiveConversionManager.swift`

**Verify**: `isEnabled = true` (line 39) - ✅ Already correct

**Adjust**: Lower minimumLength and conversionDelay for smartphone feel

```swift
// Current (might be too conservative)
var minimumLength: Int = 3
var conversionDelay: TimeInterval = 0.5

// Smartphone-appropriate (more responsive)
var minimumLength: Int = 2
var conversionDelay: TimeInterval = 0.2
```

## Testing Plan

1. **Build and Run**: Verify no compile errors
2. **Visual Test**: Confirm mode button removed from UI
3. **Functional Test**:
   - Type Cyrillic → hiragana displays ✅
   - Continue typing → automatic conversion triggers ✅
   - Press space → just inserts space, no manual conversion ✅
   - Candidate bar shows options automatically ✅

## Expected Outcome

**Smartphone-Appropriate IME**:
- Clean keyboard UI (no mode switcher)
- Automatic live conversion (like iOS native keyboard)
- Responsive conversion triggers
- Natural typing flow without manual intervention

**User Experience**:
```
User types: К А Н Ж И
Display shows: かんじ (composing)
After 0.2s: 漢字 (auto-converted)
User presses space: " " inserted
```

No mode button, no manual conversion, just seamless Japanese input via Cyrillic keyboard.

## Implementation Complete ✅

**Date Completed**: 2025-11-23

### Files Modified

1. **Shared/Models/InputMode.swift** (26 lines)
   - Simplified enum from 4 modes to single `.japaneseIME`
   - Removed: `directCyrillic`, `japaneseHiragana`, `japaneseKatakana`

2. **CyrillicKeyboard/Views/CyrillicKeyboardView.swift** (lines 77-79, 283-285, 460-502)
   - Changed `inputMode` from computed property to constant
   - Removed `inputModeButton` property and UI code
   - Removed mode toggle methods

3. **CyrillicKeyboard/Engine/CyrillicInputManager.swift** (lines 50-52, 142-228, 276-394)
   - Removed `isLiveConversionEnabled` property (always true)
   - Simplified `processKey()` to always use live conversion
   - Removed 4 mode-specific handler methods
   - Simplified `processSpace()` to commit + insert space only
   - Removed manual conversion methods (`startConversion()`, `cycleToNextCandidate()`, etc.)
   - Updated `processReturn()`, `processDelete()`, arrow key handlers
   - Removed `toggleLiveConversion()` method

4. **Shared/Extensions/UserDefaults+AppGroup.swift** (lines 27, 50-61)
   - Removed `currentInputMode` key from Keys enum
   - Removed `currentInputMode` property

5. **CyrillicKeyboard/KeyboardViewController.swift** (line 200)
   - Removed `inputManager.setInputMode(view.currentInputMode)` call

6. **CyrillicKeyboard/Engine/LiveConversionManager.swift** (lines 42, 45)
   - Adjusted `minimumLength`: 3 → 2 (more responsive)
   - Adjusted `conversionDelay`: 0.5s → 0.2s (faster conversion)
   - Verified `isEnabled = true` (smartphone-appropriate)

### Build Status

✅ **Build Successful**

Test Results:
- Core conversion tests: All passing (110+ tests)
- Profile tests: All passing (Bulgarian, Russian, Serbian, Ukrainian, Analytical)
- Performance tests: All passing
- **19 test failures**: Expected, related to removed InputMode enum and mode switching
  - These tests need updating to match new smartphone paradigm
  - Failures in: CyrillicInputManagerTests, ModelTests, RustCoreFFITests

### What Changed

**Before (Desktop Paradigm)**:
```
User types: К А Н Ж И
Display: かんじ (composing)
User presses SPACE → triggers manual conversion
Display: 【漢字】 (conversion mode with candidates)
User cycles through candidates
User presses ENTER → commits selected candidate
```

**After (Smartphone Paradigm)**:
```
User types: К А Н Ж И
Display: かんじ (composing)
After 0.2s → automatic live conversion
Display: 漢字 (auto-converted with clauses)
User presses SPACE → just inserts space: "漢字 "
```

### Next Steps

1. Update failing tests to match smartphone paradigm
2. Remove test assertions about mode switching
3. Update test mocks for simplified flow
4. Verify in iOS Simulator with manual testing

## References

- azooKey LiveConversionManager: `docs/repos/azooKey/Keyboard/Display/LiveConversionManager.swift`
- azooKey InputManager: `docs/repos/azooKey/Keyboard/Display/InputManager.swift`
- User feedback: "わざわざスペースで変換はしない．スマホ向けだよ"

---

**Created**: 2025-11-23
**Completed**: 2025-11-23
**Author**: Claude Code (AI Assistant)
**Status**: ✅ Code Complete (Tests need updating)
