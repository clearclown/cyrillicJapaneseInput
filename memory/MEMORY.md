# Pismo Project Memory

## Project Overview
iOS keyboard extension (+ Android in-dev) that enables Japanese input via Cyrillic script.
- iOS: Swift/SwiftUI, Xcode project at `iOS/`
- Android: Kotlin, Gradle project at `Android/`

## Architecture (iOS)
```
Cyrillic key → KeyboardActionManager → InputManager
                                          ├── CyrillicKanaConverter (Cyrillic→Hiragana)
                                          ├── KanaKanjiConverter/Zenzai (Hiragana→Kanji)
                                          ├── LiveConversionManager (real-time display)
                                          └── DisplayedTextManager (text proxy)
```

## Key Files
- `iOS/AzooKeyCore/Sources/AzooKeyUtils/CyrillicKanaConverter.swift` — 1060 lines, 21 language profiles, 200+ mappings, complete
- `iOS/Keyboard/Display/InputManager.swift` — central input hub, ~1050 lines
- `iOS/Keyboard/Display/KeyboardActionManager.swift` — user action dispatcher, 778 lines
- `iOS/Keyboard/Display/LiveConversionManager.swift` — 156 lines, live kana→kanji
- `iOS/AzooKeyCore/Sources/AzooKeyUtils/KeyboardSetting/MemoryResetCondition.swift` — learning memory reset
- `Android/app/src/main/kotlin/com/pismo/keyboard/service/PismoInputMethodService.kt` — Android IME
- `Android/app/src/main/kotlin/com/pismo/keyboard/converter/CyrillicKanaConverter.kt` — 492 lines, 5 profiles

## Language Profiles (iOS: 21, Android: 5)
iOS primary: standard, ukrainian, belarusian, bulgarian, serbian, macedonian
iOS extended: kazakh, kyrgyz, mongolian, tajik, uzbek, tatar, bashkir, chuvash, sakha, buryat, kalmyk, azerbaijani, churchSlavonic, komi, khanty, chukchi, abkhaz

## Fixes Applied
- `KeyboardActionManager.swift:765` — `hideLearningMemory()` was empty stub; implemented with `MemoryResetCondition.set(value: .need)`

## Remaining TODOs (non-blocking, refactoring notes)
- `InputManager.swift:25,31` — consolidate manager classes (design note)
- `InputManager.swift:289` — ruby matching optimization idea
- `InputManager.swift:744` — verify `requireSetResult` semantics
- `LiveConversionManager.swift:66-67` — live conversion UX enhancements
- `PredictionManager.swift:20` — use shared `mergeCandidates` helper
- `DisplayedTextManager.swift:201` — iOS 16+ `rawDeleteForward` workaround (acknowledged as hard to fix)

## Status
- iOS: Production-ready, published on App Store
- Android: Core implemented (5 profiles, full IME service, kanji dict), not yet released
