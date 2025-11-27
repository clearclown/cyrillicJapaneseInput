# Special Rules - ん, っ, Separators

## 撥音 ん (Nasal Sound)

The nasal sound ん requires special handling because Н is also used as a consonant in syllables like На (な), Ни (に), etc.

### Rules for ん Generation

1. **Double Н**: `НН` → `ん`
   - Example: `АННАЙ` → `あんない` (案内)

2. **Н + Consonant**: `Н` + consonant → `ん` + consonant
   - Example: `КАНДА` → `かんだ` (神田)
   - The Н is converted to ん, then the consonant starts a new syllable

3. **Н + Separator + Vowel**: `Н'А` or `НЪА` → `んあ`
   - Used when ん is followed by a vowel
   - Example: `ГИН'ИРО` → `ぎんいろ` (銀色)

### Implementation Note

**IMPORTANT**: Do NOT add a direct `Н` → `ん` mapping in the main mapping table. This causes conflicts with syllables like `НА` (な).

Instead, handle ん in special rule processing:
```
if lastChar == "Н" {
    if inputChar == "Н" {
        return "ん"  // НН → ん
    }
    if isConsonant(inputChar) {
        return "ん" + inputChar  // Н + consonant
    }
    // Otherwise, wait for syllable completion (e.g., НА → な)
}
```

## 促音 っ (Sokuon / Double Consonant)

### Rules for っ Generation

1. **Double Consonant**: Same consonant twice → `っ` + consonant
   - Example: `КАППА` → `かっぱ` (河童)
   - `КК` → `っК` → eventually `っか`

2. **Explicit ъ prefix**: `ЪЦ` → `っ`
   - Direct input for small っ

### Consonants that trigger Sokuon

All consonants EXCEPT:
- Н (handled as nasal sound)
- Vowels (А, И, У, Э, О, etc.)
- Special characters (Ъ, Ь, etc.)

## Separators (区切り文字)

Separators are used to disambiguate `ん` + vowel sequences.

### Supported Separators

| Input | Output | Example |
|-------|--------|---------|
| Н'А | んあ | кан'и → かんい |
| Н'И | んい | - |
| Н'У | んう | - |
| Н'Э | んえ | - |
| Н'О | んお | - |
| Н'Я | んや | - |
| Н'Ю | んゆ | - |
| Н'Ё | んよ | - |
| НЪА | んあ | same as above |
| НЪИ | んい | - |
| НЪУ | んう | - |
| НЪЭ | んえ | - |
| НЪО | んお | - |
| НЪЯ | んや | - |
| НЪЮ | んゆ | - |
| НЪЁ | んよ | - |

Both `'` (apostrophe) and `Ъ` (hard sign) work as separators.

## 長音 ー (Long Vowel)

The katakana long vowel mark ー is input directly from the keyboard.

In the keyboard layout, a dedicated key is provided for ー input.
