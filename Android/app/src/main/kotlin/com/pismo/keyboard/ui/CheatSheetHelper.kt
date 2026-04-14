/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Cheat sheet dialog showing Cyrillic → Kana mapping table.
 */
package com.pismo.keyboard.ui

import android.app.AlertDialog
import android.content.Context
import android.graphics.Typeface
import android.view.Gravity
import android.view.LayoutInflater
import android.widget.TableLayout
import android.widget.TableRow
import android.widget.TextView
import com.pismo.keyboard.R

/**
 * Shows a cheat sheet dialog with Cyrillic-to-Kana mappings.
 *
 * The table is organized by phonetic category (vowels, consonants, special)
 * with columns: Cyrillic input → Romaji → Hiragana output.
 */
object CheatSheetHelper {

    // Vowel mappings: (Cyrillic, Romaji, Hiragana)
    private val vowels = listOf(
        Triple("А", "a", "あ"),
        Triple("И", "i", "い"),
        Triple("У", "u", "う"),
        Triple("Э", "e", "え"),
        Triple("О", "o", "お"),
    )

    // Consonant row mappings
    private val consonants = listOf(
        Triple("Ка", "ka", "か"), Triple("Са", "sa", "さ"), Triple("Та", "ta", "た"),
        Triple("На", "na", "な"), Triple("Ха", "ha", "は"), Triple("Ма", "ma", "ま"),
        Triple("Ра", "ra", "ら"), Triple("Ва", "wa", "わ"),
        Triple("Га", "ga", "が"), Triple("Дза", "za", "ざ"), Triple("Да", "da", "だ"),
        Triple("Ба", "ba", "ば"), Triple("Па", "pa", "ぱ"),
        Triple("Кя", "kya", "きゃ"), Triple("Ся", "sha", "しゃ"), Triple("Ча", "cha", "ちゃ"),
        Triple("Ня", "nya", "にゃ"), Triple("Хя", "hya", "ひゃ"), Triple("Мя", "mya", "みゃ"),
        Triple("Ря", "rya", "りゃ"),
    )

    // Special mappings
    private val special = listOf(
        Triple("Я", "ya", "や"), Triple("Ю", "yu", "ゆ"), Triple("Ё", "yo", "よ"),
        Triple("Чи", "chi", "ち"), Triple("Цу", "tsu", "つ"), Triple("Фу", "fu", "ふ"),
        Triple("НН", "nn", "ん"), Triple("КК~", "kk~", "っ + ~"),
        Triple("Н'", "n'", "ん (区切り)"),
    )

    fun createDialog(context: Context): AlertDialog {
        val view = LayoutInflater.from(context).inflate(R.layout.dialog_cheatsheet, null)

        val tableVowels = view.findViewById<TableLayout>(R.id.table_vowels)
        val tableConsonants = view.findViewById<TableLayout>(R.id.table_consonants)
        val tableSpecial = view.findViewById<TableLayout>(R.id.table_special)

        addHeader(context, tableVowels)
        vowels.forEach { addRow(context, tableVowels, it) }

        addHeader(context, tableConsonants)
        consonants.forEach { addRow(context, tableConsonants, it) }

        addHeader(context, tableSpecial)
        special.forEach { addRow(context, tableSpecial, it) }

        return AlertDialog.Builder(context, android.R.style.Theme_DeviceDefault_Dialog)
            .setView(view)
            .setPositiveButton("OK", null)
            .create()
    }

    private fun addHeader(context: Context, table: TableLayout) {
        val row = TableRow(context).apply {
            setPadding(0, 4, 0, 4)
        }
        listOf("キリル", "ローマ字", "かな").forEach { label ->
            row.addView(TextView(context).apply {
                text = label
                textSize = 12f
                setTypeface(null, Typeface.BOLD)
                gravity = Gravity.CENTER
                setPadding(8, 4, 8, 4)
            })
        }
        table.addView(row)
    }

    private fun addRow(context: Context, table: TableLayout, data: Triple<String, String, String>) {
        val row = TableRow(context).apply {
            setPadding(0, 2, 0, 2)
        }
        val sizes = listOf(16f, 12f, 16f)
        listOf(data.first, data.second, data.third).forEachIndexed { i, text ->
            row.addView(TextView(context).apply {
                this.text = text
                textSize = sizes[i]
                gravity = Gravity.CENTER
                setPadding(8, 4, 8, 4)
            })
        }
        table.addView(row)
    }
}
