# Cyrillic to Japanese Kana Mapping System

This document describes the mapping rules for converting Cyrillic script input to Japanese Hiragana.

## Version 1.2.0 New Features

### 「を」の入力対応
- **Во → を** (助詞の「を」が入力可能に)
- わ行のパターンに一致: Ва=わ, Ви=ゐ, Вэ=ゑ, **Во=を**

### 「ぢ」「づ」の明示的入力
- **Дьи → ぢ** (soft sign で「じ」と区別)
- **Дьу → づ** (soft sign で「ず」と区別)

| 入力 | 出力 | 備考 |
|-----|------|------|
| Во | を | 助詞「を」 |
| Дьи | ぢ | 「じ」(Дзи)と区別 |
| Дьу | づ | 「ず」(Дзу)と区別 |

## Overview

The system uses a **greedy matching algorithm** that processes input character by character, attempting to match the longest possible sequence first.

## Core Concepts

### 1. Matching Priority

The converter checks in this order:
1. **Complete match** - If the current buffer + input forms a valid mapping, convert immediately
2. **Prefix match** - If it's a prefix of a longer sequence, wait for more input
3. **Special rules** - Handle ん (nasal) and っ (sokuon)
4. **Pass through** - If no match, output the character as-is

**Important**: Complete matches must be checked BEFORE prefix matches. Otherwise, single characters like У (which is both a complete match for う AND a prefix for Уа, Уи, etc.) will get stuck in "wait" state.

### 2. Buffer Management

- The system maintains a composing buffer
- When a match is found, it may need to delete previous characters and replace with kana
- `InputOperation(deleteLast: N, input: "kana")` - Delete N chars from buffer, insert kana

## Mapping Tables

See individual files:
- [seion.md](./seion.md) - Basic syllables (清音)
- [dakuten.md](./dakuten.md) - Voiced syllables (濁音)
- [youon.md](./youon.md) - Palatalized syllables (拗音)
- [special.md](./special.md) - Special rules (ん, っ, separators)
- [alternatives.md](./alternatives.md) - Alternative input methods

## Keyboard Profiles

The system supports multiple Cyrillic keyboard layouts:

### Slavic Languages
- **Standard (Russian)** - JCUKEN layout
- **Ukrainian** - Modified with і, ї, є, ґ
- **Belarusian** - Modified with ў (unique to Belarusian)
- **Bulgarian** - BDS layout (different arrangement)
- **Serbian** - With љ, њ, џ, ћ, ђ
- **Macedonian** - Similar to Serbian with ѓ, ќ, ѕ

### Turkic Languages (Central Asia)
- **Kazakh** - Extended Cyrillic with ә, ғ, қ, ң, ө, ұ, ү, һ, і
- **Kyrgyz** - Russian base + ң, ө, ү

### Mongolian
- **Mongolian** - Russian base + ө, ү

### Profile Fallback Logic
- Macedonian → Serbian (similar character set)
- Kazakh/Kyrgyz/Mongolian → Standard Russian (shared base alphabet)

Each profile maps the same Japanese sounds but uses characters appropriate for that language.

## Implementation Notes for Android

When implementing for Android:
1. Use the same mapping data structures
2. Implement the same greedy matching algorithm
3. Pay attention to:
   - Complete match vs prefix match priority
   - Special handling for Н (nasal sound)
   - Sokuon (っ) via consonant doubling
