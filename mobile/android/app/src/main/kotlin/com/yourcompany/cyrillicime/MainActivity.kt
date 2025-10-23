package com.yourcompany.cyrillicime

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.yourcompany.cyrillicime.ui.ProfileSelectionScreen
import com.yourcompany.cyrillicime.ui.theme.CyrillicIMETheme

/**
 * Main activity for IME settings
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            CyrillicIMETheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ProfileSelectionScreen()
                }
            }
        }
    }
}
