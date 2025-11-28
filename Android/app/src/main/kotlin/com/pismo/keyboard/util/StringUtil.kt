/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Based on Android-IME by LiteKite Startup
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.pismo.keyboard.util

/**
 * Utility functions for string manipulation.
 */
object StringUtil {

    /**
     * Parses a comma-separated string of integers.
     *
     * @return IntArray of parsed values
     */
    fun String.parseCSV(): IntArray {
        val count = this.count { it == ',' } + 1
        val values = IntArray(count)
        var start = 0
        var end: Int
        var index = 0

        while (true) {
            end = this.indexOf(',', start)
            val value = if (end > 0) {
                this.substring(start, end).trim()
            } else {
                this.substring(start).trim()
            }

            try {
                values[index] = value.toInt()
            } catch (e: NumberFormatException) {
                // If parsing fails, use the first character's code
                if (value.isNotEmpty()) {
                    values[index] = value[0].code
                }
            }

            if (end < 0) break
            start = end + 1
            index++
        }

        return values
    }

    /**
     * Checks if a string contains only punctuation characters.
     *
     * @return true if the string is punctuation
     */
    fun String.isPunctuation(): Boolean {
        if (this.isEmpty()) return false
        return this.all { !Character.isLetterOrDigit(it) && !Character.isWhitespace(it) }
    }
}
