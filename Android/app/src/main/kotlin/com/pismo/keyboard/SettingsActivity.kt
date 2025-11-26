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

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Settings activity for Pismo IME.
 *
 * Provides options to enable the keyboard in system settings
 * and switch to Pismo as the active input method.
 */
class SettingsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        findViewById<Button>(R.id.btnEnableKeyboard).setOnClickListener {
            // Open system input method settings
            startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
        }

        findViewById<Button>(R.id.btnSwitchKeyboard).setOnClickListener {
            // Open input method picker
            val inputMethodManager = getSystemService(INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
            inputMethodManager.showInputMethodPicker()
        }
    }

    override fun onResume() {
        super.onResume()
        updateStatus()
    }

    private fun updateStatus() {
        val statusText = findViewById<TextView>(R.id.tvStatus)
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager

        // Check if Pismo is in the list of enabled input methods
        val isEnabled = imm.enabledInputMethodList.any {
            it.packageName == packageName
        }

        statusText.text = if (isEnabled) {
            getString(R.string.status_enabled)
        } else {
            getString(R.string.status_disabled)
        }
    }
}
