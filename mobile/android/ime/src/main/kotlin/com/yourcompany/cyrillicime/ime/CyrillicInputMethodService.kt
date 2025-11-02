package com.yourcompany.cyrillicime.ime

import android.inputmethodservice.InputMethodService
import android.view.View
import androidx.compose.runtime.*
import androidx.compose.ui.platform.ComposeView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.ViewTreeLifecycleOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import com.yourcompany.cyrillicime.ime.engine.ProfileManager
import com.yourcompany.cyrillicime.ime.engine.RustCoreEngine
import com.yourcompany.cyrillicime.ime.ui.KeyboardView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * Main IME service implementation
 */
class CyrillicInputMethodService : InputMethodService(), LifecycleOwner, SavedStateRegistryOwner {

    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateRegistryController = SavedStateRegistryController.create(this)
    
    private lateinit var profileManager: ProfileManager
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    
    private var inputBuffer by mutableStateOf("")
    private var composeView: ComposeView? = null

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateRegistryController.savedStateRegistry

    override fun onCreate() {
        super.onCreate()
        savedStateRegistryController.performRestore(null)
        lifecycleRegistry.currentState = Lifecycle.State.CREATED

        // Initialize ProfileManager
        val prefs = getSharedPreferences("cyrillic_ime_prefs", MODE_PRIVATE)
        profileManager = ProfileManager(this, prefs)

        // Load profiles and initialize engine
        if (!profileManager.loadProfiles()) {
            android.util.Log.e("CyrillicIME", "Failed to load profiles")
        }

        if (!profileManager.initializeEngine()) {
            android.util.Log.e("CyrillicIME", "Failed to initialize engine")
        }

        android.util.Log.i("CyrillicIME", "Service created, Rust Core version: ${RustCoreEngine.instance.getVersion()}")
    }

    override fun onCreateInputView(): View {
        lifecycleRegistry.currentState = Lifecycle.State.STARTED

        composeView = ComposeView(this).apply {
            setViewTreeLifecycleOwner(this@CyrillicInputMethodService)
            setViewTreeSavedStateRegistryOwner(this@CyrillicInputMethodService)

            setContent {
                val currentProfile by profileManager.currentProfile.collectAsState()

                KeyboardView(
                    profile = currentProfile,
                    inputBuffer = inputBuffer,
                    onKeyPress = ::handleKeyPress,
                    onDeletePress = ::handleDelete,
                    onSpacePress = ::handleSpace,
                    onEnterPress = ::handleEnter,
                    onSwitchKeyboard = ::advanceToNextInputMode
                )
            }
        }

        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
        return composeView!!
    }

    private fun handleKeyPress(key: String) {
        val profile = profileManager.currentProfile.value ?: return

        val result = RustCoreEngine.instance.processKey(
            key = key,
            buffer = inputBuffer,
            profileId = profile.id
        ) ?: return

        when {
            result.isCommit -> {
                currentInputConnection?.commitText(result.output, 1)
                inputBuffer = result.buffer
            }
            result.isComposing -> {
                inputBuffer = result.buffer
                currentInputConnection?.setComposingText(result.buffer, 1)
            }
            result.isClear -> {
                inputBuffer = ""
                currentInputConnection?.finishComposingText()
            }
        }

        // Haptic feedback
        performHapticFeedback()
    }

    private fun handleDelete() {
        if (inputBuffer.isNotEmpty()) {
            // Delete from buffer
            inputBuffer = inputBuffer.dropLast(1)
            if (inputBuffer.isEmpty()) {
                currentInputConnection?.finishComposingText()
            } else {
                currentInputConnection?.setComposingText(inputBuffer, 1)
            }
        } else {
            // Delete from text field
            currentInputConnection?.deleteSurroundingText(1, 0)
        }
        performHapticFeedback()
    }

    private fun handleSpace() {
        if (inputBuffer.isNotEmpty()) {
            currentInputConnection?.commitText(inputBuffer, 1)
            inputBuffer = ""
        }
        currentInputConnection?.commitText(" ", 1)
        performHapticFeedback()
    }

    private fun handleEnter() {
        if (inputBuffer.isNotEmpty()) {
            currentInputConnection?.commitText(inputBuffer, 1)
            inputBuffer = ""
        }
        currentInputConnection?.commitText("\n", 1)
        performHapticFeedback()
    }

    private fun performHapticFeedback() {
        // Haptic feedback will be implemented in KeyboardView
    }

    override fun onDestroy() {
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        composeView = null
        super.onDestroy()
    }
}
