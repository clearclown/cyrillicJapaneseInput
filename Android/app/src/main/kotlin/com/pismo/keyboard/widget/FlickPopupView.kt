/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.pismo.keyboard.widget

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import com.pismo.keyboard.R

/**
 * A popup view that displays flick input options in a cross pattern.
 * Shows the center character and available directional alternatives.
 */
class FlickPopupView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    companion object {
        private const val POPUP_WIDTH = 80f   // dp - narrower for single direction
        private const val POPUP_HEIGHT = 100f // dp - taller for vertical layout
        private const val CELL_SIZE = 40f     // dp
        private const val TEXT_SIZE = 24f     // sp
        private const val CORNER_RADIUS = 12f // dp
    }

    private val density = resources.displayMetrics.density
    private val popupWidth = (POPUP_WIDTH * density).toInt()
    private val popupHeight = (POPUP_HEIGHT * density).toInt()
    private val cellSize = CELL_SIZE * density
    private val cornerRadius = CORNER_RADIUS * density

    private val backgroundPaint = Paint().apply {
        isAntiAlias = true
        color = Color.parseColor("#E0303030")
        style = Paint.Style.FILL
    }

    private val highlightPaint = Paint().apply {
        isAntiAlias = true
        color = Color.parseColor("#4080FF")
        style = Paint.Style.FILL
    }

    private val textPaint = Paint().apply {
        isAntiAlias = true
        color = Color.WHITE
        textSize = TEXT_SIZE * resources.displayMetrics.scaledDensity
        textAlign = Paint.Align.CENTER
    }

    private val dimTextPaint = Paint().apply {
        isAntiAlias = true
        color = Color.parseColor("#888888")
        textSize = TEXT_SIZE * resources.displayMetrics.scaledDensity
        textAlign = Paint.Align.CENTER
    }

    private var centerLabel: String = ""
    private var topLabel: String = ""
    private var leftLabel: String = ""
    private var rightLabel: String = ""
    private var bottomLabel: String = ""
    private var currentDirection: FlickDirection = FlickDirection.CENTER

    private val backgroundRect = RectF()
    private val cellRect = RectF()

    init {
        // Make view not focusable
        isFocusable = false
        isFocusableInTouchMode = false
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(popupWidth, popupHeight)
    }

    /**
     * Set the labels for each direction.
     * @param center The center (default) character
     * @param top The top swipe character (or empty if none)
     * @param left The left swipe character (or empty if none)
     * @param right The right swipe character (or empty if none)
     * @param bottom The bottom swipe character (or empty if none)
     */
    fun setLabels(center: String, top: String = "", left: String = "", right: String = "", bottom: String = "") {
        centerLabel = center
        topLabel = top
        leftLabel = left
        rightLabel = right
        bottomLabel = bottom
        invalidate()
    }

    /**
     * Set the currently highlighted direction.
     */
    fun setDirection(direction: FlickDirection) {
        if (currentDirection != direction) {
            currentDirection = direction
            invalidate()
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val w = width.toFloat()
        val h = height.toFloat()
        val centerX = w / 2
        val halfCell = cellSize / 2

        // Draw background
        backgroundRect.set(0f, 0f, w, h)
        canvas.drawRoundRect(backgroundRect, cornerRadius, cornerRadius, backgroundPaint)

        // Calculate text vertical center offset
        val textOffset = (textPaint.descent() + textPaint.ascent()) / 2

        // Vertical layout: top label at top, center label at bottom
        // Only show directions that have labels
        val topY = h * 0.3f
        val centerY = h * 0.7f

        // Draw highlight for current direction
        when (currentDirection) {
            FlickDirection.CENTER -> {
                cellRect.set(centerX - halfCell, centerY - halfCell, centerX + halfCell, centerY + halfCell)
                canvas.drawRoundRect(cellRect, 8 * density, 8 * density, highlightPaint)
            }
            FlickDirection.TOP -> {
                if (topLabel.isNotEmpty()) {
                    cellRect.set(centerX - halfCell, topY - halfCell, centerX + halfCell, topY + halfCell)
                    canvas.drawRoundRect(cellRect, 8 * density, 8 * density, highlightPaint)
                }
            }
            FlickDirection.LEFT -> {
                if (leftLabel.isNotEmpty()) {
                    cellRect.set(centerX - halfCell, centerY - halfCell, centerX + halfCell, centerY + halfCell)
                    canvas.drawRoundRect(cellRect, 8 * density, 8 * density, highlightPaint)
                }
            }
            FlickDirection.RIGHT -> {
                if (rightLabel.isNotEmpty()) {
                    cellRect.set(centerX - halfCell, centerY - halfCell, centerX + halfCell, centerY + halfCell)
                    canvas.drawRoundRect(cellRect, 8 * density, 8 * density, highlightPaint)
                }
            }
            FlickDirection.BOTTOM -> {
                if (bottomLabel.isNotEmpty()) {
                    cellRect.set(centerX - halfCell, centerY - halfCell, centerX + halfCell, centerY + halfCell)
                    canvas.drawRoundRect(cellRect, 8 * density, 8 * density, highlightPaint)
                }
            }
        }

        // Draw top label (alternative character) - only if exists
        if (topLabel.isNotEmpty()) {
            val topPaint = if (currentDirection == FlickDirection.TOP) textPaint else dimTextPaint
            canvas.drawText(topLabel, centerX, topY - textOffset, topPaint)
        }

        // Draw center label (main character) at bottom
        val centerPaint = if (currentDirection == FlickDirection.CENTER) textPaint else dimTextPaint
        canvas.drawText(centerLabel, centerX, centerY - textOffset, centerPaint)
    }
}
