package com.yourcompany.cyrillicime.ime.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Input profile representing a Cyrillic keyboard layout
 */
@Serializable
data class Profile(
    @SerialName("id")
    val id: String,

    @SerialName("name_ja")
    val nameJa: String,

    @SerialName("name_en")
    val nameEn: String,

    @SerialName("keyboardLayout")
    val keyboardLayout: List<String>,

    @SerialName("inputSchemaId")
    val inputSchemaId: String
) {
    /**
     * Get display name based on system locale
     */
    fun getDisplayName(language: String = "en"): String {
        return if (language.startsWith("ja")) nameJa else nameEn
    }
}
