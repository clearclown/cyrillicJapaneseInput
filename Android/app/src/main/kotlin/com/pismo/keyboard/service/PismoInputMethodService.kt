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

import android.graphics.Typeface
import android.inputmethodservice.InputMethodService
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.pismo.keyboard.PismoApp
import com.pismo.keyboard.R
import com.pismo.keyboard.converter.CyrillicKanaConverter
import com.pismo.keyboard.converter.KanjiConverter
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
    private var currentLocale: String = "ru"

    private var _binding: LayoutKeyboardViewBinding? = null
    private val binding: LayoutKeyboardViewBinding get() = _binding!!

    // Cyrillic to Kana converter
    private val converter = CyrillicKanaConverter()

    // Kana to Kanji converter
    private var kanjiConverter: KanjiConverter? = null

    // Current hiragana buffer for kanji conversion
    private var hiraganaBuffer = StringBuilder()

    // Current candidates
    private var currentCandidates = listOf<String>()
    private var selectedCandidateIndex = 0

    init {
        PismoApp.printLog(TAG, "init:")
    }

    override fun onCreate() {
        super.onCreate()
        PismoApp.printLog(TAG, "onCreate:")
        parseKeyboardLayoutFromXml()

        // Initialize kanji converter
        kanjiConverter = KanjiConverter(this)
        kanjiConverter?.loadDictionaries {
            PismoApp.printLog(TAG, "Kanji dictionaries loaded")
        }
    }

    private fun parseKeyboardLayoutFromXml() {
        val layout = Keyboard.layoutForLocale(currentLocale)
        cyrillicKeyboard = createKeyboard(layout)
        symbolKeyboard = createKeyboard(Keyboard.LAYOUT_KEYBOARD_SYMBOL)
        syncConverterProfile()
    }

    override fun onCurrentInputMethodSubtypeChanged(newSubtype: android.view.inputmethod.InputMethodSubtype?) {
        super.onCurrentInputMethodSubtypeChanged(newSubtype)
        val locale = newSubtype?.locale ?: "ru"
        PismoApp.printLog(TAG, "onCurrentInputMethodSubtypeChanged: locale=$locale")
        currentLocale = locale
        parseKeyboardLayoutFromXml()
        _binding?.vKeyboard?.setKeyboard(cyrillicKeyboard)
    }

    private fun syncConverterProfile() {
        val profile = when {
            currentLocale.startsWith("uk") -> CyrillicKanaConverter.Profile.UKRAINIAN
            currentLocale.startsWith("bg") -> CyrillicKanaConverter.Profile.BULGARIAN
            currentLocale.startsWith("sr") -> CyrillicKanaConverter.Profile.SERBIAN
            currentLocale.startsWith("be") -> CyrillicKanaConverter.Profile.BELARUSIAN
            else -> CyrillicKanaConverter.Profile.STANDARD
        }
        converter.setProfile(profile)
        PismoApp.printLog(TAG, "syncConverterProfile: $profile")
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
        // Clear converter buffer when input finishes
        converter.clearBuffer()
        clearHiraganaBuffer()
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

    // MARK: - Cheat Sheet

    private fun showCheatSheet() {
        val dialogContext = android.view.ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_Dialog)
        val dialog = com.pismo.keyboard.ui.CheatSheetHelper.createDialog(dialogContext)
        dialog.window?.let { window ->
            window.setType(android.view.WindowManager.LayoutParams.TYPE_APPLICATION_ATTACHED_DIALOG)
            val token = _binding?.root?.windowToken
            if (token != null) {
                window.attributes = window.attributes.apply {
                    this.token = token
                }
            }
        }
        dialog.show()
    }

    // MARK: - Haptic & Sound Feedback

    private fun performKeyFeedback() {
        _binding?.vKeyboard?.performHapticFeedback(
            android.view.HapticFeedbackConstants.KEYBOARD_TAP,
            android.view.HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING
        )
    }

    // MARK: - Keyboard Action Listener

    private val keyboardActionListener = object : KeyboardView.KeyboardActionListener {

        override fun onKey(primaryCode: Int) {
            PismoApp.printLog(TAG, "onKey: $primaryCode")
            performKeyFeedback()
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
                    handleDelete()
                }
                Keyboard.KEYCODE_CHEATSHEET -> {
                    showCheatSheet()
                }
                Keyboard.KEYCODE_MAIN_KEYBOARD -> {
                    keyboardView.setKeyboard(cyrillicKeyboard)
                }
                Keyboard.KEYCODE_CLOSE_KEYBOARD -> {
                    requestHideSelf(0)
                }
                Keyboard.KEYCODE_ENTER -> {
                    // If we have candidates, select the current one
                    if (currentCandidates.isNotEmpty()) {
                        commitSelectedCandidate()
                    } else {
                        // Flush any remaining buffer before enter
                        flushConverterBuffer()
                        handleEnterKey()
                    }
                }
                Keyboard.KEYCODE_SPACE -> {
                    // If we have candidates, select and add space
                    if (currentCandidates.isNotEmpty()) {
                        commitSelectedCandidate()
                        commitTextDirect(" ")
                    } else {
                        // Flush buffer and add space
                        flushConverterBuffer()
                        commitTextDirect(" ")
                    }
                }
                else -> {
                    processKeyWithConverter(primaryCode)
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

    /**
     * Process a key press through the Cyrillic-to-Kana converter.
     */
    private fun processKeyWithConverter(code: Int) {
        var inputChar = Char(code).toString()
        // Handle shift - uppercase for Cyrillic input
        val keyboardView = _binding?.vKeyboard
        if (keyboardView != null && keyboardView.isShifted()) {
            inputChar = inputChar.uppercase(keyboardView.getLocale())
        }

        PismoApp.printLog(TAG, "processKeyWithConverter: input=$inputChar")

        // Process through converter
        val result = converter.processInput(inputChar)

        // Add converted hiragana to buffer for kanji conversion
        if (result.committed.isNotEmpty()) {
            PismoApp.printLog(TAG, "processKeyWithConverter: adding to hiragana buffer=${result.committed}")
            hiraganaBuffer.append(result.committed)
            updateCandidates()
        }

        // Update composing text (show hiragana buffer + unconverted Cyrillic)
        updateComposingTextWithBuffer(result.composing)
    }

    /**
     * Update the composing text displayed in the input field.
     */
    private fun updateComposingText(composing: String) {
        val ic = currentInputConnection ?: return
        if (composing.isEmpty()) {
            ic.finishComposingText()
        } else {
            ic.setComposingText(composing, 1)
        }
    }

    /**
     * Flush any remaining text in the converter buffer.
     */
    private fun flushConverterBuffer() {
        val flushed = converter.flush()
        if (flushed.isNotEmpty()) {
            PismoApp.printLog(TAG, "flushConverterBuffer: $flushed")
            currentInputConnection?.commitText(flushed, 1)
        }
        currentInputConnection?.finishComposingText()
    }

    /**
     * Commit text directly without conversion (for space, punctuation, etc.)
     */
    private fun commitTextDirect(text: String) {
        PismoApp.printLog(TAG, "commitTextDirect: $text")
        currentInputConnection?.commitText(text, 1)
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

    // ==================== Kanji Conversion Methods ====================

    /**
     * Update composing text including hiragana buffer.
     */
    private fun updateComposingTextWithBuffer(cyrillicComposing: String) {
        val ic = currentInputConnection ?: return
        val composing = hiraganaBuffer.toString() + cyrillicComposing

        if (composing.isEmpty()) {
            ic.finishComposingText()
        } else {
            ic.setComposingText(composing, 1)
        }
    }

    /**
     * Update candidate list based on current hiragana buffer.
     */
    private fun updateCandidates() {
        val hiragana = hiraganaBuffer.toString()
        PismoApp.printLog(TAG, "updateCandidates: hiragana='$hiragana', length=${hiragana.length}")

        if (hiragana.isEmpty()) {
            hideCandidateBar()
            return
        }

        kanjiConverter?.let { converter ->
            val isReady = converter.isReady()
            PismoApp.printLog(TAG, "updateCandidates: kanjiConverter.isReady()=$isReady")

            if (isReady) {
                currentCandidates = converter.getCandidates(hiragana)
                selectedCandidateIndex = 0
                PismoApp.printLog(TAG, "updateCandidates: candidates=${currentCandidates.size}, list=${currentCandidates.take(5)}")
                showCandidateBar()
            } else {
                PismoApp.printLog(TAG, "updateCandidates: dictionary not ready yet")
            }
        } ?: run {
            PismoApp.printLog(TAG, "updateCandidates: kanjiConverter is null")
        }
    }

    /**
     * Show candidate bar with current candidates.
     */
    private fun showCandidateBar() {
        val binding = _binding ?: return

        binding.candidateScrollView.visibility = View.VISIBLE
        binding.candidateBar.removeAllViews()

        currentCandidates.forEachIndexed { index, candidate ->
            val textView = createCandidateTextView(candidate, index)
            binding.candidateBar.addView(textView)

            // Add divider except after last item
            if (index < currentCandidates.size - 1) {
                binding.candidateBar.addView(createDivider())
            }
        }

        // Scroll to start
        binding.candidateScrollView.scrollTo(0, 0)
    }

    /**
     * Create a TextView for a candidate.
     */
    private fun createCandidateTextView(text: String, index: Int): TextView {
        return TextView(this).apply {
            this.text = text
            textSize = resources.getDimension(R.dimen.candidate_text_size) / resources.displayMetrics.density
            setPadding(
                resources.getDimensionPixelSize(R.dimen.candidate_padding_horizontal),
                resources.getDimensionPixelSize(R.dimen.candidate_padding_vertical),
                resources.getDimensionPixelSize(R.dimen.candidate_padding_horizontal),
                resources.getDimensionPixelSize(R.dimen.candidate_padding_vertical)
            )

            // Highlight selected candidate
            if (index == selectedCandidateIndex) {
                setTextColor(ContextCompat.getColor(context, R.color.candidate_text_selected))
                setBackgroundColor(ContextCompat.getColor(context, R.color.candidate_background_selected))
                setTypeface(null, Typeface.BOLD)
            } else {
                setTextColor(ContextCompat.getColor(context, R.color.candidate_text))
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
            }

            // Click to select candidate
            setOnClickListener {
                selectCandidate(index)
            }
        }
    }

    /**
     * Create a divider view between candidates.
     */
    private fun createDivider(): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, LinearLayout.LayoutParams.MATCH_PARENT).apply {
                setMargins(0, 8, 0, 8)
            }
            setBackgroundColor(ContextCompat.getColor(context, R.color.candidate_divider))
        }
    }

    /**
     * Hide candidate bar.
     */
    private fun hideCandidateBar() {
        _binding?.candidateScrollView?.visibility = View.GONE
        _binding?.candidateBar?.removeAllViews()
        currentCandidates = emptyList()
        selectedCandidateIndex = 0
    }

    /**
     * Select a candidate by index.
     */
    private fun selectCandidate(index: Int) {
        if (index < 0 || index >= currentCandidates.size) return

        selectedCandidateIndex = index
        commitSelectedCandidate()
    }

    /**
     * Commit the currently selected candidate.
     */
    private fun commitSelectedCandidate() {
        if (currentCandidates.isEmpty()) return

        val selected = currentCandidates.getOrElse(selectedCandidateIndex) {
            hiraganaBuffer.toString()
        }

        PismoApp.printLog(TAG, "commitSelectedCandidate: $selected")

        // Replace composing text with selected candidate (don't use finishComposingText as it commits the hiragana)
        currentInputConnection?.setComposingText("", 1)  // Clear composing without committing
        currentInputConnection?.commitText(selected, 1)

        // Clear buffer and candidates
        clearHiraganaBuffer()
    }

    /**
     * Clear hiragana buffer and hide candidates.
     */
    private fun clearHiraganaBuffer() {
        hiraganaBuffer.clear()
        hideCandidateBar()
    }

    /**
     * Handle delete/backspace key.
     * Removes characters from buffers in the correct order:
     * 1. Converter composing buffer (unconverted Cyrillic)
     * 2. Hiragana buffer (converted kana awaiting kanji conversion)
     * 3. Committed text (already in the text field)
     */
    private fun handleDelete() {
        PismoApp.printLog(TAG, "handleDelete: composing=${converter.getComposingText()}, hiragana=${hiraganaBuffer}")

        // First check if there's composing text in the converter buffer
        val composing = converter.getComposingText()
        if (composing.isNotEmpty()) {
            // Remove last character from converter buffer
            converter.deleteLastChar()
            updateComposingTextWithBuffer(converter.getComposingText())
            return
        }

        // Then check if there's hiragana in the buffer
        if (hiraganaBuffer.isNotEmpty()) {
            // Remove last character from hiragana buffer
            hiraganaBuffer.deleteCharAt(hiraganaBuffer.length - 1)
            updateCandidates()
            updateComposingTextWithBuffer("")

            // If buffer becomes empty, hide candidates
            if (hiraganaBuffer.isEmpty()) {
                hideCandidateBar()
                currentInputConnection?.finishComposingText()
            }
            return
        }

        // If no buffer text, delete from committed text
        currentInputConnection?.deleteSurroundingText(1, 0)
    }
}
