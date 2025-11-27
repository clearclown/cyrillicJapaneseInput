# Implementation Notes

## Critical Bug Prevention

### Bug 1: Vowel stuck in "Wait" state

**Problem**: Single vowels like У (う) were not converting because they are both:
- A complete match (У → う)
- A prefix for longer sequences (Уа → うぁ, Уи → うぃ)

**Fix**: Check complete matches BEFORE prefix matches in the algorithm.

**Affected profiles**: ALL profiles (Standard, Ukrainian, Bulgarian, Serbian, Belarusian)

```
// WRONG ORDER (causes bug)
if (isPrefix(candidate)) return Wait
if (isCompleteMatch(candidate)) return Convert

// CORRECT ORDER
if (isCompleteMatch(candidate)) return Convert
if (isPrefix(candidate)) return Wait
```

### Bug 2: НА converting to んあ instead of な

**Problem**: Direct mapping of Н → ん causes conflict with syllables like НА (な).

**Fix**: Do NOT add Н → ん to the main mapping table. Handle ん only through special rules:
- НН → ん (double Н)
- Н + consonant → ん + consonant
- Н + separator → ん + vowel

**Affected profiles**: ALL profiles use Н for the N consonant.

## Profile-Specific Considerations

### Bulgarian (BDS Layout)

- Uses Ъ for the "u" sound in some positions (e.g., Къ for く)
- The converter handles this correctly through profile-specific column selection
- Test: Ensure Ъ alone converts correctly for Bulgarian profile

### Ukrainian

- Uses І instead of И for "i" sound
- Uses Ї, Є, Ґ for Ukrainian-specific sounds
- Ї has longpress for special input on keyboard

### Serbian

- Uses Ј (J) instead of soft vowels for Y-sounds
- Uses Љ, Њ, Џ, Ћ, Ђ for Serbian-specific sounds
- Џ is used for じゃ行 sounds

### Belarusian

- Uses Ў (U with breve) for わ行 sounds

## Testing Requirements

### Unit Tests for Converter

Each profile should have tests for:

1. **Basic vowels**: А→あ, И→い, У→う, Э→え, О→お
2. **Basic syllables**: КА→か, СА→さ, etc.
3. **Nasal sound (ん)**:
   - НН → ん
   - НА → な (NOT んあ)
   - Н + consonant → ん + consonant
   - Н'А → んあ
4. **Sokuon (っ)**:
   - КК → っК
   - Double consonants
5. **Prefix vs Complete match**:
   - У alone → う (not wait)
   - НА → な (not んあ)

### Test Cases Template

```swift
// iOS (Swift)
func testStandardProfile() {
    let converter = CyrillicKanaConverter()
    converter.setProfile(.standard)

    // Test vowels
    XCTAssertEqual(process("У", buffer: ""), "う")
    XCTAssertEqual(process("А", buffer: ""), "あ")

    // Test syllables
    XCTAssertEqual(process("А", buffer: "К"), "か") // КА → か
    XCTAssertEqual(process("А", buffer: "Н"), "な") // НА → な, NOT んあ

    // Test nasal
    XCTAssertEqual(process("Н", buffer: "Н"), "ん") // НН → ん
    XCTAssertEqual(process("Д", buffer: "Н"), "んД") // Н + consonant
}

// Android (Kotlin)
@Test
fun testStandardProfile() {
    val converter = CyrillicKanaConverter(Profile.STANDARD)

    // Test vowels
    assertEquals("う", converter.process("У", ""))
    assertEquals("あ", converter.process("А", ""))

    // Test syllables
    assertEquals("か", converter.process("А", "К"))
    assertEquals("な", converter.process("А", "Н")) // NOT んあ
}
```

## Algorithm Pseudocode

```
function process(input, buffer):
    inputUpper = input.toUpperCase()

    // Step 1: Try longer matches (buffer + input)
    for i in range(min(buffer.length, 4), 0, -1):
        suffix = buffer.suffix(i)
        candidate = suffix.toUpperCase() + inputUpper

        // IMPORTANT: Complete match FIRST
        if mapping.contains(candidate):
            return Operation(delete: i, output: mapping[candidate])

        // Then prefix check
        if prefixes.contains(candidate):
            return Operation(delete: 0, output: input)  // Wait

    // Step 2: Special rules (ん, っ)
    lastChar = buffer.lastChar?.toUpperCase()

    // Nasal (ん)
    if lastChar == "Н":
        if inputUpper == "Н":
            return Operation(delete: 1, output: "ん")
        if isConsonant(inputUpper):
            return Operation(delete: 1, output: "ん" + input)

    // Sokuon (っ)
    if lastChar == inputUpper && isSokuonConsonant(inputUpper):
        return Operation(delete: 1, output: "っ" + input)

    // Step 3: Single character match
    if mapping.contains(inputUpper):
        return Operation(delete: 0, output: mapping[inputUpper])

    if prefixes.contains(inputUpper):
        return Operation(delete: 0, output: input)  // Wait

    // No match - pass through
    return Operation(delete: 0, output: input)
```
