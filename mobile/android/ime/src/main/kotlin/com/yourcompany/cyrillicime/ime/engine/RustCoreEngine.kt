package com.yourcompany.cyrillicime.ime.engine

import com.yourcompany.cyrillicime.core.NativeLib
import com.yourcompany.cyrillicime.ime.model.ConversionResult
import kotlinx.serialization.json.Json

/**
 * Wrapper for Rust Core JNI with Kotlin-friendly API
 */
class RustCoreEngine private constructor() {
    companion object {
        val instance by lazy { RustCoreEngine() }
    }

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    /**
     * Initialize the engine
     */
    fun initialize(profilesJson: String, kanaEngineJson: String): Boolean {
        return try {
            NativeLib.initEngine(profilesJson, kanaEngineJson)
        } catch (e: Exception) {
            android.util.Log.e("RustCoreEngine", "Initialization failed", e)
            false
        }
    }

    /**
     * Load a schema
     */
    fun loadSchema(schemaJson: String, schemaId: String): Boolean {
        return try {
            NativeLib.loadSchema(schemaJson, schemaId)
        } catch (e: Exception) {
            android.util.Log.e("RustCoreEngine", "Schema load failed", e)
            false
        }
    }

    /**
     * Process a key press
     */
    fun processKey(key: String, buffer: String, profileId: String): ConversionResult? {
        return try {
            val resultJson = NativeLib.processKey(key, buffer, profileId) ?: return null
            json.decodeFromString<ConversionResult>(resultJson)
        } catch (e: Exception) {
            android.util.Log.e("RustCoreEngine", "Key processing failed", e)
            null
        }
    }

    /**
     * Get version
     */
    fun getVersion(): String {
        return try {
            NativeLib.getVersion()
        } catch (e: Exception) {
            "unknown"
        }
    }
}
