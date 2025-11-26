/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Based on Android-IME by LiteKite Startup
 * https://github.com/LiteKite/Android-IME
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
package com.pismo.keyboard.service

import android.inputmethodservice.InputMethodService
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import com.pismo.keyboard.PismoApp
import com.pismo.keyboard.R
import com.pismo.keyboard.databinding.LayoutKeyboardViewBinding
import com.pismo.keyboard.widget.Keyboard
import com.pismo.keyboard.widget.KeyboardView

/**
 * Main Input Method Service for Pismo.
 *
 * Handles keyboard display, key input processing, and text commitment
 * to the currently focused input field.
 */
class PismoInputMethodService : InputMethodService() {

    companion object {
        private val TAG: String = PismoInputMethodService::class.java.simpleName
        private const val IME_ACTION_CUSTOM_LABEL = EditorInfo.IME_MASK_ACTION + 1
    }

    private var _editorInfo: EditorInfo? = null
    private val editorInfo: EditorInfo get() = _editorInfo!!

    private lateinit var cyrillicKeyboard: Keyboard
    private lateinit var symbolKeyboard: Keyboard

    private var _binding: LayoutKeyboardViewBinding? = null
    private val binding: LayoutKeyboardViewBinding get() = _binding!!

    init {
        PismoApp.printLog(TAG, "init:")
    }

    override fun onCreate() {
        super.onCreate()
        PismoApp.printLog(TAG, "onCreate:")
        parseKeyboardLayoutFromXml()
    }

    private fun parseKeyboardLayoutFromXml() {
        cyrillicKeyboard = createKeyboard(Keyboard.LAYOUT_KEYBOARD_CYRILLIC_RU)
        symbolKeyboard = createKeyboard(Keyboard.LAYOUT_KEYBOARD_SYMBOL)
    }

    private fun createKeyboard(layoutXml: String): Keyboard {
        return Keyboard(
            this,
            resources.getIdentifier(layoutXml, Keyboard.DEF_TYPE, packageName)
        )
    }

    override fun onCreateInputView(): View {
        PismoApp.printLog(TAG, "onCreateInputView:")
        _binding = LayoutKeyboardViewBinding.inflate(LayoutInflater.from(this))
        return binding.root
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        PismoApp.printLog(TAG, "onStartInputView:")
        _editorInfo = info
        binding.vKeyboard.setKeyboard(cyrillicKeyboard)
        binding.vKeyboard.addCallback(keyboardActionListener)
        binding.vKeyboard.setShifted(info.initialCapsMode != 0)
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        PismoApp.printLog(TAG, "onFinishInputView:")
        binding.vKeyboard.removeCallback(keyboardActionListener)
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onDestroy() {
        PismoApp.printLog(TAG, "onDestroy:")
        _binding = null
        super.onDestroy()
    }

    private val keyboardActionListener = object : KeyboardView.KeyboardActionListener {

        override fun onKey(primaryCode: Int) {
            PismoApp.printLog(TAG, "onKey: $primaryCode")
            when (primaryCode) {
                Keyboard.KEYCODE_SHIFT -> {
                    // Toggle Capitalization
                    binding.vKeyboard.setShifted(!binding.vKeyboard.isShifted())
                }
                Keyboard.KEYCODE_MODE_CHANGE -> {
                    // Switch between Cyrillic and Symbol keyboard
                    if (binding.vKeyboard.keyboard === cyrillicKeyboard) {
                        binding.vKeyboard.setKeyboard(symbolKeyboard)
                    } else {
                        binding.vKeyboard.setKeyboard(cyrillicKeyboard)
                    }
                }
                Keyboard.KEYCODE_DONE -> {
                    val action = editorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
                    currentInputConnection?.performEditorAction(action)
                }
                Keyboard.KEYCODE_DELETE -> {
                    currentInputConnection?.deleteSurroundingText(1, 0)
                }
                Keyboard.KEYCODE_MAIN_KEYBOARD -> {
                    binding.vKeyboard.setKeyboard(cyrillicKeyboard)
                }
                Keyboard.KEYCODE_CLOSE_KEYBOARD -> {
                    requestHideSelf(0)
                }
                Keyboard.KEYCODE_ENTER -> {
                    handleEnterKey()
                }
                Keyboard.KEYCODE_SPACE -> {
                    commitText(" ")
                }
                else -> {
                    commitText(primaryCode)
                }
            }
        }

        override fun onStopInput() {
            requestHideSelf(0)
        }
    }

    private fun handleEnterKey() {
        val imeOptionsActionId = getImeOptionsActionId(editorInfo)
        when {
            IME_ACTION_CUSTOM_LABEL == imeOptionsActionId -> {
                currentInputConnection?.performEditorAction(editorInfo.actionId)
            }
            EditorInfo.IME_ACTION_NONE != imeOptionsActionId -> {
                currentInputConnection?.performEditorAction(imeOptionsActionId)
            }
            else -> {
                // Regular enter key - input a newline
                currentInputConnection?.commitText("\n", 1)
            }
        }
    }

    private fun getImeOptionsActionId(info: EditorInfo): Int {
        return when {
            info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION != 0 -> {
                EditorInfo.IME_ACTION_NONE
            }
            info.actionLabel != null -> {
                IME_ACTION_CUSTOM_LABEL
            }
            else -> {
                info.imeOptions and EditorInfo.IME_MASK_ACTION
            }
        }
    }

    private fun commitText(code: Int) {
        var commitText = Char(code).toString()
        // Characters come through as lowercase, uppercase them if keyboard is shifted
        if (binding.vKeyboard.isShifted()) {
            commitText = commitText.uppercase(binding.vKeyboard.getLocale())
        }
        PismoApp.printLog(TAG, "commitText: $commitText")
        currentInputConnection?.commitText(commitText, 1)
    }

    private fun commitText(text: String) {
        PismoApp.printLog(TAG, "commitText: $text")
        currentInputConnection?.commitText(text, 1)
    }
}
