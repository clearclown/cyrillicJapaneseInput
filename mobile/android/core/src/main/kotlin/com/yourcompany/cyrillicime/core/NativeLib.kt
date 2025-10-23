package com.yourcompany.cyrillicime.core

/**
 * JNI interface to Rust Core engine
 *
 * All native methods are implemented in rust_core/src/jni.rs
 */
object NativeLib {
    init {
        System.loadLibrary("cyrillic_ime_core")
    }

    /**
     * Initialize the engine with profiles and kana engine JSON
     *
     * @param profilesJson JSON string containing array of profiles
     * @param kanaEngineJson JSON string containing kana mapping
     * @return true if successful, false otherwise
     */
    @JvmStatic
    external fun initEngine(profilesJson: String, kanaEngineJson: String): Boolean

    /**
     * Load a schema into the engine
     *
     * @param schemaJson JSON string containing schema mappings
     * @param schemaId Unique identifier for the schema
     * @return true if successful, false otherwise
     */
    @JvmStatic
    external fun loadSchema(schemaJson: String, schemaId: String): Boolean

    /**
     * Process a key press and return conversion result
     *
     * @param key The Cyrillic key pressed
     * @param buffer Current input buffer
     * @param profileId Active profile ID
     * @return JSON string of ConversionResult, or null if error
     */
    @JvmStatic
    external fun processKey(key: String, buffer: String, profileId: String): String?

    /**
     * Get the Rust Core version
     *
     * @return Version string
     */
    @JvmStatic
    external fun getVersion(): String
}
