package com.yourcompany.cyrillicime.ime.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yourcompany.cyrillicime.ime.model.Profile

/**
 * Main keyboard UI using Jetpack Compose
 */
@Composable
fun KeyboardView(
    profile: Profile?,
    inputBuffer: String,
    onKeyPress: (String) -> Unit,
    onDeletePress: () -> Unit,
    onSpacePress: () -> Unit,
    onEnterPress: () -> Unit,
    onSwitchKeyboard: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(4.dp)
        ) {
            // Buffer display
            if (inputBuffer.isNotEmpty()) {
                BufferDisplay(buffer = inputBuffer)
            }

            // Profile indicator
            profile?.let {
                ProfileIndicator(profile = it)
            }

            // Keyboard layout
            profile?.let {
                KeyboardLayout(
                    keys = it.keyboardLayout,
                    onKeyPress = onKeyPress
                )
            }

            // Function keys row
            FunctionKeyRow(
                onDeletePress = onDeletePress,
                onSpacePress = onSpacePress,
                onEnterPress = onEnterPress,
                onSwitchKeyboard = onSwitchKeyboard
            )
        }
    }
}

@Composable
private fun BufferDisplay(buffer: String) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = buffer,
            modifier = Modifier.padding(8.dp),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ProfileIndicator(profile: Profile) {
    Text(
        text = profile.getDisplayName("ja"),
        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

@Composable
private fun KeyboardLayout(
    keys: List<String>,
    onKeyPress: (String) -> Unit
) {
    // Split keys into rows (10 keys per row)
    val rows = keys.chunked(10)

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                row.forEach { key ->
                    KeyButton(
                        key = key,
                        onClick = { onKeyPress(key) },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun KeyButton(
    key: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    FilledTonalButton(
        onClick = onClick,
        modifier = modifier
            .aspectRatio(1f),
        shape = MaterialTheme.shapes.small,
        colors = ButtonDefaults.filledTonalButtonColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer
        )
    ) {
        Text(
            text = key,
            style = MaterialTheme.typography.titleLarge
        )
    }
}

@Composable
private fun FunctionKeyRow(
    onDeletePress: () -> Unit,
    onSpacePress: () -> Unit,
    onEnterPress: () -> Unit,
    onSwitchKeyboard: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        // Switch keyboard button
        FilledTonalButton(
            onClick = onSwitchKeyboard,
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.filledTonalButtonColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer
            )
        ) {
            Text("🌐")
        }

        // Space button
        FilledTonalButton(
            onClick = onSpacePress,
            modifier = Modifier.weight(4f),
            colors = ButtonDefaults.filledTonalButtonColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Text("空白")
        }

        // Delete button
        FilledTonalButton(
            onClick = onDeletePress,
            modifier = Modifier.weight(1.5f),
            colors = ButtonDefaults.filledTonalButtonColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer
            )
        ) {
            Text("⌫")
        }

        // Enter button
        FilledTonalButton(
            onClick = onEnterPress,
            modifier = Modifier.weight(1.5f),
            colors = ButtonDefaults.filledTonalButtonColors(
                containerColor = MaterialTheme.colorScheme.tertiaryContainer
            )
        ) {
            Text("↵")
        }
    }
}
