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

import android.content.res.TypedArray
import android.util.TypedValue

/**
 * Utility functions for dimension calculations.
 */
object DimensUtil {

    /**
     * Parses a dimension or fraction value from TypedArray.
     *
     * @param index The attribute index
     * @param base The base value for percentage calculations
     * @param defaultValue The default value to return if not found
     * @return The parsed dimension value
     */
    fun TypedArray.getDimensionOrFraction(index: Int, base: Int, defaultValue: Int): Int {
        val value = peekValue(index) ?: return defaultValue
        return when (value.type) {
            TypedValue.TYPE_DIMENSION -> {
                getDimensionPixelOffset(index, defaultValue)
            }
            TypedValue.TYPE_FRACTION -> {
                (getFraction(index, base.toFloat(), base.toFloat()) + 0.5f).toInt()
            }
            else -> {
                defaultValue
            }
        }
    }
}
