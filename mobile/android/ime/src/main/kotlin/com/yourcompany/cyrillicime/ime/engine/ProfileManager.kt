package com.yourcompany.cyrillicime.ime.engine

import android.content.Context
import android.content.SharedPreferences
import com.yourcompany.cyrillicime.ime.model.Profile
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.Json

/**
 * Manages input profiles and persists current selection
 */
class ProfileManager(
    private val context: Context,
    private val sharedPreferences: SharedPreferences
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val _profiles = MutableStateFlow<List<Profile>>(emptyList())
    val profiles: StateFlow<List<Profile>> = _profiles.asStateFlow()

    private val _currentProfile = MutableStateFlow<Profile?>(null)
    val currentProfile: StateFlow<Profile?> = _currentProfile.asStateFlow()

    companion object {
        private const val PREF_KEY_CURRENT_PROFILE_ID = "current_profile_id"
        private const val DEFAULT_PROFILE_ID = "rus_standard"
    }

    /**
     * Load profiles from assets
     */
    fun loadProfiles(): Boolean {
        return try {
            val profilesJson = context.assets.open("profiles/profiles.json")
                .bufferedReader().use { it.readText() }

            _profiles.value = json.decodeFromString<List<Profile>>(profilesJson)
            
            // Load current profile from SharedPreferences
            val savedProfileId = sharedPreferences.getString(
                PREF_KEY_CURRENT_PROFILE_ID,
                DEFAULT_PROFILE_ID
            )
            
            _currentProfile.value = _profiles.value.find { it.id == savedProfileId }
                ?: _profiles.value.firstOrNull()

            android.util.Log.i("ProfileManager", "Loaded ${_profiles.value.size} profiles")
            true
        } catch (e: Exception) {
            android.util.Log.e("ProfileManager", "Failed to load profiles", e)
            false
        }
    }

    /**
     * Switch to a different profile
     */
    fun switchProfile(profileId: String): Boolean {
        val profile = _profiles.value.find { it.id == profileId } ?: return false

        _currentProfile.value = profile
        
        // Persist selection
        sharedPreferences.edit()
            .putString(PREF_KEY_CURRENT_PROFILE_ID, profileId)
            .apply()

        android.util.Log.i("ProfileManager", "Switched to profile: $profileId")
        return true
    }

    /**
     * Load schema for a specific profile
     */
    fun loadSchemaForProfile(profile: Profile): Boolean {
        return try {
            val schemaJson = context.assets.open("profiles/schemas/${profile.inputSchemaId}.json")
                .bufferedReader().use { it.readText() }

            RustCoreEngine.instance.loadSchema(schemaJson, profile.inputSchemaId)
        } catch (e: Exception) {
            android.util.Log.e("ProfileManager", "Failed to load schema for ${profile.id}", e)
            false
        }
    }

    /**
     * Initialize Rust Core engine
     */
    fun initializeEngine(): Boolean {
        return try {
            val profilesJson = context.assets.open("profiles/profiles.json")
                .bufferedReader().use { it.readText() }

            val kanaEngineJson = context.assets.open("profiles/kana_engine.json")
                .bufferedReader().use { it.readText() }

            val success = RustCoreEngine.instance.initialize(profilesJson, kanaEngineJson)
            
            if (success) {
                android.util.Log.i("ProfileManager", "Rust Core initialized successfully")
                // Load schema for current profile
                _currentProfile.value?.let { loadSchemaForProfile(it) }
            }
            
            success
        } catch (e: Exception) {
            android.util.Log.e("ProfileManager", "Failed to initialize engine", e)
            false
        }
    }
}
