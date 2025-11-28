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
package com.pismo.keyboard

import android.app.Application
import android.util.Log

/**
 * Main Application class for Pismo IME.
 *
 * Handles application-wide initialization and provides
 * utility methods for logging.
 */
class PismoApp : Application() {

    companion object {
        private const val TAG = "Pismo"
        private const val DEBUG = true

        /**
         * Utility method for logging debug messages.
         */
        fun printLog(tag: String, message: String) {
            if (DEBUG) {
                Log.d("$TAG/$tag", message)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        printLog(TAG, "Application created")
    }
}
