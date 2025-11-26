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
        PismoApp.printLog(TAG, "onCreateInputView: starting")
        try {
            _binding = LayoutKeyboardViewBinding.inflate(LayoutInflater.from(this))
            PismoApp.printLog(TAG, "onCreateInputView: binding inflated successfully")
            return binding.root
        } catch (e: Exception) {
            PismoApp.printLog(TAG, "onCreateInputView: ERROR - ${e.message}")
            throw e
        }
    }

    override fun onShowInputRequested(flags: Int, configChange: Boolean): Boolean {
        val result = super.onShowInputRequested(flags, configChange)
        PismoApp.printLog(TAG, "onShowInputRequested: flags=$flags configChange=$configChange result=$result")
        // Always return true to ensure keyboard shows
        return true
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        PismoApp.printLog(TAG, "onStartInputView: restarting=$restarting binding=${_binding != null}")
        _editorInfo = info

        // Ensure binding is available - onCreateInputView may not have been called yet
        val keyboardBinding = _binding
        if (keyboardBinding == null) {
            PismoApp.printLog(TAG, "onStartInputView: binding is null, skipping setup")
            return
        }

        keyboardBinding.vKeyboard.setKeyboard(cyrillicKeyboard)
        keyboardBinding.vKeyboard.addCallback(keyboardActionListener)
        keyboardBinding.vKeyboard.setShifted(info.initialCapsMode != 0)
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        PismoApp.printLog(TAG, "onFinishInputView:")
        _binding?.vKeyboard?.removeCallback(keyboardActionListener)
    }

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onEvaluateInputViewShown(): Boolean {
        // Always show input view - this is critical for the keyboard to be displayed
        PismoApp.printLog(TAG, "onEvaluateInputViewShown: returning true")
        return true
    }

    override fun onDestroy() {
        PismoApp.printLog(TAG, "onDestroy:")
        _binding = null
        super.onDestroy()
    }

    private val keyboardActionListener = object : KeyboardView.KeyboardActionListener {

        override fun onKey(primaryCode: Int) {
            PismoApp.printLog(TAG, "onKey: $primaryCode")
            val keyboardView = _binding?.vKeyboard ?: return

            when (primaryCode) {
                Keyboard.KEYCODE_SHIFT -> {
                    // Toggle Capitalization
                    keyboardView.setShifted(!keyboardView.isShifted())
                }
                Keyboard.KEYCODE_MODE_CHANGE -> {
                    // Switch between Cyrillic and Symbol keyboard
                    if (keyboardView.keyboard === cyrillicKeyboard) {
                        keyboardView.setKeyboard(symbolKeyboard)
                    } else {
                        keyboardView.setKeyboard(cyrillicKeyboard)
                    }
                }
                Keyboard.KEYCODE_DONE -> {
                    val action = _editorInfo?.let { it.imeOptions and EditorInfo.IME_MASK_ACTION } ?: return
                    currentInputConnection?.performEditorAction(action)
                }
                Keyboard.KEYCODE_DELETE -> {
                    currentInputConnection?.deleteSurroundingText(1, 0)
                }
                Keyboard.KEYCODE_MAIN_KEYBOARD -> {
                    keyboardView.setKeyboard(cyrillicKeyboard)
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
        val info = _editorInfo ?: return
        val imeOptionsActionId = getImeOptionsActionId(info)
        when {
            IME_ACTION_CUSTOM_LABEL == imeOptionsActionId -> {
                currentInputConnection?.performEditorAction(info.actionId)
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
        val keyboardView = _binding?.vKeyboard
        if (keyboardView != null && keyboardView.isShifted()) {
            commitText = commitText.uppercase(keyboardView.getLocale())
        }
        PismoApp.printLog(TAG, "commitText: $commitText")
        currentInputConnection?.commitText(commitText, 1)
    }

    private fun commitText(text: String) {
        PismoApp.printLog(TAG, "commitText: $text")
        currentInputConnection?.commitText(text, 1)
    }
}
