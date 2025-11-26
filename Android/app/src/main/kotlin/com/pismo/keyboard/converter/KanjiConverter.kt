/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Kana to Kanji Converter based on Mozc dictionary data
 * https://github.com/google/mozc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 */
package com.pismo.keyboard.converter

import android.content.Context
import com.pismo.keyboard.PismoApp
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.zip.GZIPInputStream

/**
 * Converts Hiragana to Kanji using Mozc dictionary data.
 *
 * Features:
 * - Offline operation using pre-processed dictionary
 * - Single character conversion (single_kanji)
 * - Word/phrase conversion (kanji_dict)
 * - Prefix matching for candidates
 */
class KanjiConverter(private val context: Context) {

    companion object {
        private const val TAG = "KanjiConverter"
        // Try compressed first, fall back to uncompressed (Android may decompress .gz during build)
        private const val DICT_FILE_GZ = "dictionary/kanji_dict.json.gz"
        private const val DICT_FILE_JSON = "dictionary/kanji_dict.json"
        private const val SINGLE_KANJI_FILE_GZ = "dictionary/single_kanji.json.gz"
        private const val SINGLE_KANJI_FILE_JSON = "dictionary/single_kanji.json"
        private const val MAX_CANDIDATES = 10
    }

    // Main dictionary: hiragana reading -> list of kanji candidates
    private val kanjiDict = mutableMapOf<String, List<String>>()

    // Single character dictionary: hiragana -> list of kanji characters
    private val singleKanjiDict = mutableMapOf<String, List<String>>()

    // Loading state
    private var isLoaded = false
    private var isLoading = false

    /**
     * Load dictionary data asynchronously.
     */
    fun loadDictionaries(onComplete: (() -> Unit)? = null) {
        PismoApp.printLog(TAG, "loadDictionaries: called, isLoaded=$isLoaded, isLoading=$isLoading")

        if (isLoaded || isLoading) {
            PismoApp.printLog(TAG, "loadDictionaries: already loaded or loading, skipping")
            onComplete?.invoke()
            return
        }

        isLoading = true
        PismoApp.printLog(TAG, "loadDictionaries: starting background thread")

        Thread {
            try {
                PismoApp.printLog(TAG, "loadDictionaries: Loading dictionaries in background...")
                val startTime = System.currentTimeMillis()

                // Load main dictionary - try compressed first, then uncompressed
                PismoApp.printLog(TAG, "loadDictionaries: loading kanji_dict")
                if (!tryLoadDictionary(DICT_FILE_GZ, kanjiDict, true)) {
                    tryLoadDictionary(DICT_FILE_JSON, kanjiDict, false)
                }
                PismoApp.printLog(TAG, "loadDictionaries: Loaded kanji_dict: ${kanjiDict.size} entries")

                // Load single kanji dictionary - try compressed first, then uncompressed
                PismoApp.printLog(TAG, "loadDictionaries: loading single_kanji")
                if (!tryLoadDictionary(SINGLE_KANJI_FILE_GZ, singleKanjiDict, true)) {
                    tryLoadDictionary(SINGLE_KANJI_FILE_JSON, singleKanjiDict, false)
                }
                PismoApp.printLog(TAG, "loadDictionaries: Loaded single_kanji: ${singleKanjiDict.size} entries")

                val elapsed = System.currentTimeMillis() - startTime
                PismoApp.printLog(TAG, "loadDictionaries: Dictionaries loaded in ${elapsed}ms, setting isLoaded=true")

                isLoaded = true
                isLoading = false

                // Log some sample entries
                val sampleKeys = kanjiDict.keys.take(3)
                for (key in sampleKeys) {
                    PismoApp.printLog(TAG, "loadDictionaries: sample entry '$key' -> ${kanjiDict[key]?.take(3)}")
                }

                onComplete?.invoke()

            } catch (e: Exception) {
                PismoApp.printLog(TAG, "loadDictionaries: FAILED - ${e.message}")
                e.printStackTrace()
                isLoading = false
            }
        }.start()
    }

    /**
     * Try to load a dictionary file. Returns true if successful, false otherwise.
     * @param assetPath Path to the asset file
     * @param targetMap Map to populate with dictionary entries
     * @param isGzipped Whether the file is GZIP compressed
     */
    private fun tryLoadDictionary(
        assetPath: String,
        targetMap: MutableMap<String, List<String>>,
        isGzipped: Boolean
    ): Boolean {
        try {
            PismoApp.printLog(TAG, "tryLoadDictionary: opening asset $assetPath (gzipped=$isGzipped)")
            val inputStream = context.assets.open(assetPath)

            val reader = if (isGzipped) {
                val gzipStream = GZIPInputStream(inputStream)
                BufferedReader(InputStreamReader(gzipStream, Charsets.UTF_8))
            } else {
                BufferedReader(InputStreamReader(inputStream, Charsets.UTF_8))
            }

            PismoApp.printLog(TAG, "tryLoadDictionary: reading JSON content")
            val jsonString = reader.readText()
            reader.close()
            PismoApp.printLog(TAG, "tryLoadDictionary: JSON string length=${jsonString.length}")

            val jsonObject = JSONObject(jsonString)
            val keys = jsonObject.keys()

            var count = 0
            while (keys.hasNext()) {
                val key = keys.next()
                val jsonArray = jsonObject.getJSONArray(key)
                val candidates = mutableListOf<String>()

                for (i in 0 until jsonArray.length()) {
                    candidates.add(jsonArray.getString(i))
                }

                targetMap[key] = candidates
                count++
            }
            PismoApp.printLog(TAG, "tryLoadDictionary: parsed $count entries from $assetPath")
            return true

        } catch (e: java.io.FileNotFoundException) {
            PismoApp.printLog(TAG, "tryLoadDictionary: file not found $assetPath")
            return false
        } catch (e: Exception) {
            PismoApp.printLog(TAG, "tryLoadDictionary: ERROR loading $assetPath - ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    /**
     * Get conversion candidates for the given hiragana input.
     *
     * @param hiragana The hiragana text to convert
     * @return List of conversion candidates (kanji, katakana, etc.)
     */
    fun getCandidates(hiragana: String): List<String> {
        PismoApp.printLog(TAG, "getCandidates: hiragana='$hiragana', isLoaded=$isLoaded, dictSize=${kanjiDict.size}")

        if (!isLoaded || hiragana.isEmpty()) {
            PismoApp.printLog(TAG, "getCandidates: returning empty - isLoaded=$isLoaded, isEmpty=${hiragana.isEmpty()}")
            return emptyList()
        }

        val candidates = mutableListOf<String>()

        // First, add the original hiragana as a candidate
        candidates.add(hiragana)

        // Check main dictionary for exact match
        val dictEntry = kanjiDict[hiragana]
        PismoApp.printLog(TAG, "getCandidates: dictEntry for '$hiragana' = $dictEntry")
        dictEntry?.let { matches ->
            candidates.addAll(matches.take(MAX_CANDIDATES))
            PismoApp.printLog(TAG, "getCandidates: added ${matches.take(MAX_CANDIDATES).size} kanji candidates")
        }

        // For single character, also check single kanji dictionary
        if (hiragana.length == 1) {
            val singleEntry = singleKanjiDict[hiragana]
            PismoApp.printLog(TAG, "getCandidates: singleKanjiDict entry for '$hiragana' = ${singleEntry?.take(3)}")
            singleEntry?.let { matches ->
                // Add single kanji candidates that aren't already in the list
                matches.filter { it !in candidates }.take(MAX_CANDIDATES).forEach {
                    candidates.add(it)
                }
            }
        }

        // Add katakana conversion
        val katakana = toKatakana(hiragana)
        if (katakana != hiragana && katakana !in candidates) {
            candidates.add(katakana)
        }

        PismoApp.printLog(TAG, "getCandidates: returning ${candidates.size} candidates: ${candidates.take(5)}")
        return candidates.take(MAX_CANDIDATES)
    }

    /**
     * Get candidates with prefix matching.
     * Useful for showing candidates while typing.
     *
     * @param hiragana The hiragana prefix
     * @return List of (reading, candidates) pairs that start with the prefix
     */
    fun getCandidatesWithPrefix(hiragana: String): List<Pair<String, List<String>>> {
        if (!isLoaded || hiragana.isEmpty()) {
            return emptyList()
        }

        val results = mutableListOf<Pair<String, List<String>>>()

        // Exact match first
        kanjiDict[hiragana]?.let { matches ->
            results.add(hiragana to matches.take(MAX_CANDIDATES))
        }

        // Then prefix matches (limit to avoid performance issues)
        var count = 0
        for ((reading, candidates) in kanjiDict) {
            if (reading.startsWith(hiragana) && reading != hiragana) {
                results.add(reading to candidates.take(MAX_CANDIDATES))
                count++
                if (count >= 5) break
            }
        }

        return results
    }

    /**
     * Convert the given segment to the best candidate.
     * Used for auto-conversion.
     *
     * @param hiragana The hiragana segment to convert
     * @return The best conversion candidate, or original hiragana if no match
     */
    fun convertToBest(hiragana: String): String {
        if (!isLoaded || hiragana.isEmpty()) {
            return hiragana
        }

        // Try exact match in main dictionary
        kanjiDict[hiragana]?.firstOrNull()?.let { return it }

        // For single character, check single kanji
        if (hiragana.length == 1) {
            singleKanjiDict[hiragana]?.firstOrNull()?.let { return it }
        }

        // No match, return original
        return hiragana
    }

    /**
     * Segment the input and convert each segment.
     * Uses longest match first strategy.
     *
     * @param hiragana The full hiragana input
     * @return Converted text with kanji where possible
     */
    fun convertWithSegmentation(hiragana: String): String {
        if (!isLoaded || hiragana.isEmpty()) {
            return hiragana
        }

        val result = StringBuilder()
        var pos = 0

        while (pos < hiragana.length) {
            // Try to find the longest match starting at pos
            var matched = false

            for (len in minOf(hiragana.length - pos, 10) downTo 1) {
                val segment = hiragana.substring(pos, pos + len)

                if (kanjiDict.containsKey(segment)) {
                    result.append(kanjiDict[segment]!!.first())
                    pos += len
                    matched = true
                    break
                }
            }

            if (!matched) {
                // No match found, try single kanji or just append the character
                val char = hiragana[pos].toString()
                val singleKanji = singleKanjiDict[char]?.firstOrNull()

                result.append(singleKanji ?: char)
                pos++
            }
        }

        return result.toString()
    }

    /**
     * Check if dictionaries are loaded.
     */
    fun isReady(): Boolean {
        PismoApp.printLog(TAG, "isReady: isLoaded=$isLoaded, isLoading=$isLoading, dictSize=${kanjiDict.size}")
        return isLoaded
    }

    /**
     * Convert hiragana to katakana.
     */
    private fun toKatakana(hiragana: String): String {
        val sb = StringBuilder()
        for (char in hiragana) {
            val code = char.code
            // Hiragana range: 0x3041-0x3096
            // Katakana offset: 0x60 (96)
            if (code in 0x3041..0x3096) {
                sb.append((code + 0x60).toChar())
            } else {
                sb.append(char)
            }
        }
        return sb.toString()
    }

    /**
     * Data class for conversion result with multiple segments.
     */
    data class ConversionSegment(
        val reading: String,
        val candidates: List<String>,
        val selectedIndex: Int = 0
    ) {
        val selected: String get() = candidates.getOrElse(selectedIndex) { reading }
    }
}
