/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
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
package com.pismo.keyboard.widget

import kotlin.math.abs

/**
 * Represents the direction of a flick gesture.
 * Used to determine which character to input based on swipe direction.
 */
enum class FlickDirection {
    CENTER,  // No swipe, just tap
    LEFT,
    TOP,
    RIGHT,
    BOTTOM;

    companion object {
        /**
         * Minimum distance (in pixels) required to register as a flick.
         * Shorter movements are treated as a tap (CENTER).
         */
        private const val MIN_FLICK_DISTANCE = 30f

        /**
         * Calculate the flick direction from start to end coordinates.
         *
         * @param startX Starting X coordinate
         * @param startY Starting Y coordinate
         * @param endX Ending X coordinate
         * @param endY Ending Y coordinate
         * @return The direction of the flick, or CENTER if it was a tap
         */
        fun fromCoordinates(startX: Float, startY: Float, endX: Float, endY: Float): FlickDirection {
            val dx = endX - startX
            val dy = endY - startY
            val distance = kotlin.math.sqrt(dx * dx + dy * dy)

            // If distance is too small, it's a tap
            if (distance < MIN_FLICK_DISTANCE) {
                return CENTER
            }

            // Determine direction based on which axis has larger movement
            // Following iOS logic from extension CGPoint.swift
            return when {
                dx > 0 && abs(dy) < dx -> RIGHT
                dx < 0 && abs(dy) < -dx -> LEFT
                dy > 0 && abs(dx) < dy -> BOTTOM  // Android: positive Y is down
                dy < 0 && abs(dx) < -dy -> TOP
                else -> CENTER
            }
        }
    }
}
