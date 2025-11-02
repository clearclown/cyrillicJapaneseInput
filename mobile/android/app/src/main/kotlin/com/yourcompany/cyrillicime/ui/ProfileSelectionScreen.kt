package com.yourcompany.cyrillicime.ui

import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

/**
 * Profile selection screen UI
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileSelectionScreen() {
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Cyrillic IME") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Enable IME card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "キーボードの有効化",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Cyrillic IMEを使用するには、システム設定でキーボードを有効にする必要があります。",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Button(
                        onClick = {
                            val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                            context.startActivity(intent)
                        },
                        modifier = Modifier.align(Alignment.End)
                    ) {
                        Icon(Icons.Default.Settings, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("設定を開く")
                    }
                }
            }

            // About card
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "アプリについて",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "Cyrillic IMEは、キリル文字配列を用いて日本語ひらがなを入力するためのIMEです。",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Divider()
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "バージョン",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "1.0.0",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Usage instructions
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "使い方",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "1. 上記ボタンから設定画面を開く",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = "2. 「Cyrillic IME」を有効にする",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = "3. キーボード切り替えボタン（🌐）で切り替え",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Text(
                        text = "4. キリル文字を入力すると日本語に変換されます",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}
