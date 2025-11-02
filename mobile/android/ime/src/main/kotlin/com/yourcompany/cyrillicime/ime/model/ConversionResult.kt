package com.yourcompany.cyrillicime.ime.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Result from Rust Core conversion engine
 */
@Serializable
data class ConversionResult(
    @SerialName("action")
    val action: String, // "commit", "composing", "clear"

    @SerialName("output")
    val output: String,

    @SerialName("buffer")
    val buffer: String
) {
    val isCommit: Boolean get() = action == "commit"
    val isComposing: Boolean get() = action == "composing"
    val isClear: Boolean get() = action == "clear"
}
