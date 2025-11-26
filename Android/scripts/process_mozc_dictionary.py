#!/usr/bin/env python3
"""
Process Mozc dictionary files to create a lightweight kana-kanji dictionary.

Outputs:
- kanji_dict.json: Main dictionary (hiragana -> kanji candidates)
- single_kanji.json: Single character conversions
"""

import os
import json
import gzip
from collections import defaultdict
from pathlib import Path

# Configuration
MOZC_DATA_DIR = Path("../../docs/repos/mozc/src/data")
OUTPUT_DIR = Path("../app/src/main/assets/dictionary")

# Cost threshold - lower cost = more common words
# We'll keep entries with cost < threshold for mobile efficiency
COST_THRESHOLD = 6500  # Adjust based on resulting file size
MAX_CANDIDATES_PER_READING = 15  # Maximum candidates per hiragana reading


def parse_dictionary_line(line: str) -> tuple | None:
    """Parse a line from dictionary*.txt
    Format: reading\tlid\trid\tcost\tword
    """
    parts = line.strip().split('\t')
    if len(parts) < 5:
        return None

    reading = parts[0]
    try:
        cost = int(parts[3])
    except ValueError:
        return None
    word = parts[4]

    return reading, cost, word


def parse_single_kanji_line(line: str) -> tuple | None:
    """Parse a line from single_kanji.tsv
    Format: reading\tkanji1kanji2kanji3...
    """
    parts = line.strip().split('\t')
    if len(parts) < 2:
        return None

    reading = parts[0]
    # Characters are concatenated, split them
    kanji_list = list(parts[1])

    return reading, kanji_list


def is_hiragana(text: str) -> bool:
    """Check if text is pure hiragana."""
    for char in text:
        code = ord(char)
        # Hiragana range: 0x3040-0x309F
        # Also allow prolonged sound mark (ー) and small tsu (っ)
        if not (0x3040 <= code <= 0x309F or char in ['ー', 'っ']):
            return False
    return True


def process_main_dictionaries():
    """Process dictionary00.txt through dictionary09.txt"""
    dict_dir = MOZC_DATA_DIR / "dictionary_oss"

    # reading -> list of (cost, word)
    entries = defaultdict(list)

    for i in range(10):
        dict_file = dict_dir / f"dictionary{i:02d}.txt"
        if not dict_file.exists():
            print(f"Warning: {dict_file} not found")
            continue

        print(f"Processing {dict_file.name}...")
        with open(dict_file, 'r', encoding='utf-8') as f:
            for line in f:
                result = parse_dictionary_line(line)
                if result is None:
                    continue

                reading, cost, word = result

                # Skip non-hiragana readings or same reading/word
                if not is_hiragana(reading):
                    continue
                if reading == word:
                    continue

                # Only include entries under cost threshold
                if cost < COST_THRESHOLD:
                    entries[reading].append((cost, word))

    # Sort by cost and limit candidates
    kanji_dict = {}
    for reading, candidates in entries.items():
        # Sort by cost (lower = more common)
        candidates.sort(key=lambda x: x[0])
        # Take top N candidates, store only words
        kanji_dict[reading] = [word for cost, word in candidates[:MAX_CANDIDATES_PER_READING]]

    return kanji_dict


def process_single_kanji():
    """Process single_kanji.tsv"""
    single_kanji_file = MOZC_DATA_DIR / "single_kanji" / "single_kanji.tsv"

    single_kanji = {}

    if not single_kanji_file.exists():
        print(f"Warning: {single_kanji_file} not found")
        return single_kanji

    print(f"Processing {single_kanji_file.name}...")
    with open(single_kanji_file, 'r', encoding='utf-8') as f:
        for line in f:
            result = parse_single_kanji_line(line)
            if result is None:
                continue

            reading, kanji_list = result

            # Keep only first 20 kanji candidates per reading
            single_kanji[reading] = kanji_list[:20]

    return single_kanji


def save_dictionary(data: dict, filename: str, compress: bool = True):
    """Save dictionary as JSON, optionally compressed."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    json_str = json.dumps(data, ensure_ascii=False, separators=(',', ':'))

    if compress:
        output_path = OUTPUT_DIR / f"{filename}.json.gz"
        with gzip.open(output_path, 'wt', encoding='utf-8') as f:
            f.write(json_str)
    else:
        output_path = OUTPUT_DIR / f"{filename}.json"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(json_str)

    size_kb = output_path.stat().st_size / 1024
    print(f"Saved {output_path.name}: {size_kb:.1f} KB, {len(data)} entries")

    return output_path


def main():
    print("=== Mozc Dictionary Processor ===")
    print(f"Cost threshold: {COST_THRESHOLD}")
    print(f"Max candidates per reading: {MAX_CANDIDATES_PER_READING}")
    print()

    # Process main dictionaries
    print("--- Processing Main Dictionaries ---")
    kanji_dict = process_main_dictionaries()
    print(f"Total entries: {len(kanji_dict)}")

    # Process single kanji
    print("\n--- Processing Single Kanji ---")
    single_kanji = process_single_kanji()
    print(f"Total single kanji entries: {len(single_kanji)}")

    # Save outputs
    print("\n--- Saving Dictionaries ---")
    save_dictionary(kanji_dict, "kanji_dict", compress=True)
    save_dictionary(single_kanji, "single_kanji", compress=True)

    # Also save uncompressed for debugging
    save_dictionary(kanji_dict, "kanji_dict_debug", compress=False)
    save_dictionary(single_kanji, "single_kanji_debug", compress=False)

    print("\n=== Done ===")


if __name__ == "__main__":
    os.chdir(Path(__file__).parent)
    main()
