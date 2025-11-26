/*
 * Pismo - Cyrillic Japanese Input Method
 * Copyright (c) 2024-2025 Pismo Project
 *
 * Based on Android-IME by LiteKite Startup
 * https://github.com/LiteKite/Android-IME
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
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import com.pismo.keyboard.PismoApp
import com.pismo.keyboard.R
import java.util.Locale
import kotlin.math.max

/**
 * A view that renders a virtual Keyboard.
 *
 * Handles rendering of keys and detecting key presses and touch movements.
 */
class KeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    companion object {
        private val TAG: String = KeyboardView::class.java.simpleName
        private const val MAX_ALPHA = 255
        private const val REPEAT_KEY_DELAY = 50L
        private const val REPEAT_KEY_START_DELAY = 400L
    }

    private val keyBackground: Drawable?
    private val keyBgPadding = Rect(0, 0, 0, 0)
    private var labelTextSize = 18
    private var keyTextColorPrimary = -0x1000000
    private var keyTextColorSecondary = -0x67000000
    private val useKeyTextColorSecondary: Boolean

    internal var keyboard: Keyboard? = null

    private var keyboardChanged = false
    private var drawPending = false
    private val dirtyRect = Rect()
    private var buffer: Bitmap? = null
    private var canvas: Canvas? = Canvas()

    private val paint = Paint().apply {
        isAntiAlias = true
        textSize = labelTextSize.toFloat()
        textAlign = Paint.Align.CENTER
        alpha = MAX_ALPHA
        color = Color.TRANSPARENT
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
    }

    private var currentKeyIndex = Keyboard.NOT_A_KEY
    private var abortKey = false
    private var lastPointerCount = 1
    private var lastPointerX = 0f
    private var lastPointerY = 0f

    private val callbacks: ArrayList<KeyboardActionListener> = ArrayList()

    private val performLongPress = Runnable {
        if (isPressed && isLongClickable) {
            performLongClick()
        }
    }

    private val performRepeatKey = object : Runnable {
        override fun run() {
            sendKeyEvent()
            postDelayed(this, REPEAT_KEY_DELAY)
        }
    }

    init {
        val ta = context.obtainStyledAttributes(attrs, R.styleable.KeyboardView, defStyleAttr, 0)
        keyBackground = ta.getDrawable(R.styleable.KeyboardView_keyBackground)
        keyBackground?.getPadding(keyBgPadding)
        keyTextColorPrimary = ta.getColor(
            R.styleable.KeyboardView_keyTextColorPrimary,
            keyTextColorPrimary
        )
        useKeyTextColorSecondary = ta.getBoolean(
            R.styleable.KeyboardView_useKeyTextColorSecondary,
            false
        )
        keyTextColorSecondary = ta.getColor(
            R.styleable.KeyboardView_keyTextColorSecondary,
            keyTextColorSecondary
        )
        labelTextSize = ta.getDimensionPixelSize(
            R.styleable.KeyboardView_labelTextSize,
            labelTextSize
        )
        ta.recycle()

        if (isInEditMode) {
            val dummyKeyboard = Keyboard(
                context,
                resources.getIdentifier(
                    Keyboard.LAYOUT_KEYBOARD_CYRILLIC_RU,
                    Keyboard.DEF_TYPE,
                    context.packageName
                )
            )
            setKeyboard(dummyKeyboard)
        }
    }

    fun addCallback(callback: KeyboardActionListener) {
        if (!callbacks.contains(callback)) {
            callbacks.add(callback)
        }
    }

    fun removeCallback(callback: KeyboardActionListener) {
        callbacks.remove(callback)
    }

    fun setKeyboard(keyboard: Keyboard) {
        removeCallbacks()
        this.keyboard = keyboard
        abortKey = true
        keyboardChanged = true
        currentKeyIndex = Keyboard.NOT_A_KEY
        invalidateAllKeys()
    }

    fun setShifted(shifted: Boolean): Boolean {
        val keyboard = this.keyboard ?: return false
        if (keyboard.setShifted(shifted)) {
            invalidateAllKeys()
            return true
        }
        return false
    }

    fun isShifted(): Boolean {
        return keyboard?.isShifted ?: false
    }

    fun getLocale(): Locale = resources.configuration.locales[0]

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val keyboard = this.keyboard
        if (keyboard == null) {
            setMeasuredDimension(paddingLeft + paddingRight, paddingTop + paddingBottom)
            return
        }
        setMeasuredDimension(
            keyboard.keyboardWidth + paddingLeft + paddingRight,
            keyboard.keyboardHeight + paddingTop + paddingBottom
        )
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        invalidateAllKeys()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (drawPending || buffer == null || keyboardChanged) {
            onBufferDraw(null)
        }
        val buffer = this.buffer
        if (buffer != null) {
            canvas.drawBitmap(buffer, 0F, 0F, null)
        }
    }

    private fun onBufferDraw(invalidatedKey: Keyboard.Key?) {
        if (buffer == null || keyboardChanged) {
            if (buffer == null || keyboardChanged &&
                (buffer?.width != width || buffer?.height != height)
            ) {
                val w = max(1, width)
                val h = max(1, height)
                buffer = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                canvas?.setBitmap(buffer)
            }
            keyboardChanged = false
        }
        val keyboard = this.keyboard ?: return
        val canvas = this.canvas ?: return

        canvas.setBitmap(buffer)
        canvas.clipRect(dirtyRect)
        canvas.drawColor(0x00000000, PorterDuff.Mode.CLEAR)
        canvas.translate(0F, 0F)
        canvas.drawRect(0F, 0F, width.toFloat(), height.toFloat(), paint)

        if (invalidatedKey != null) {
            onKeyDraw(invalidatedKey)
        } else {
            for (key in keyboard.keys) {
                onKeyDraw(key)
            }
        }

        drawPending = false
        dirtyRect.setEmpty()
    }

    private fun onKeyDraw(key: Keyboard.Key) {
        val canvas = this.canvas ?: return
        val drawableState = key.getDrawableState()
        keyBackground?.state = drawableState
        key.icon?.state = drawableState

        val bounds = keyBackground?.bounds
        if (key.width != bounds?.right || key.height != bounds.bottom) {
            keyBackground?.setBounds(0, 0, key.width, key.height)
        }

        canvas.save()
        canvas.translate((key.x + paddingLeft).toFloat(), (key.y + paddingTop).toFloat())
        keyBackground?.draw(canvas)

        val keyLabel = key.adjustLabelCase(getLocale())
        if (keyLabel.isNotEmpty()) {
            paint.color = when {
                Character.isLetterOrDigit(keyLabel[0]) -> keyTextColorPrimary
                useKeyTextColorSecondary -> keyTextColorSecondary
                else -> keyTextColorPrimary
            }
            paint.textSize = labelTextSize.toFloat()
            canvas.drawText(
                keyLabel,
                (key.width - keyBgPadding.left - keyBgPadding.right) / 2F + keyBgPadding.left,
                (key.height - keyBgPadding.top - keyBgPadding.bottom) / 2F +
                    (paint.textSize - paint.descent()) / 2F + keyBgPadding.top,
                paint
            )
            paint.setShadowLayer(0f, 0f, 0f, 0)
        } else if (key.icon != null) {
            val x = (key.width - keyBgPadding.left - keyBgPadding.right - key.icon.intrinsicWidth) /
                2F + keyBgPadding.left
            val y = (key.height - keyBgPadding.top - keyBgPadding.bottom - key.icon.intrinsicHeight) /
                2F + keyBgPadding.top
            canvas.translate(x, y)
            key.icon.draw(canvas)
        }

        canvas.restore()
    }

    private fun invalidateAllKeys() {
        dirtyRect.union(0, 0, width, height)
        drawPending = true
        postInvalidate()
    }

    private fun invalidateKey(keyIndex: Int) {
        val keyboard = this.keyboard ?: return
        if (drawPending) return
        val keys = keyboard.keys
        if (keyIndex < 0 || keyIndex >= keys.size) return

        val key = keys[keyIndex]
        val left = key.x + paddingLeft
        val top = key.y + paddingTop
        val right = key.x + key.width + paddingLeft
        val bottom = key.y + key.height + paddingTop
        dirtyRect.union(left, top, right, bottom)
        onBufferDraw(key)
        postInvalidate(left, top, right, bottom)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val pointerCount = event.pointerCount
        var result: Boolean

        if (pointerCount == lastPointerCount) {
            if (pointerCount == 1) {
                result = handleTouchEvent(event)
                lastPointerX = event.x
                lastPointerY = event.y
            } else {
                result = true
            }
        } else {
            if (pointerCount == 1) {
                val down = MotionEvent.obtain(
                    event.eventTime, event.eventTime, MotionEvent.ACTION_DOWN,
                    event.x, event.y, event.metaState
                )
                result = handleTouchEvent(down)
                down.recycle()
                if (event.action == MotionEvent.ACTION_UP) {
                    result = handleTouchEvent(event)
                }
            } else {
                val up = MotionEvent.obtain(
                    event.eventTime, event.eventTime, MotionEvent.ACTION_UP,
                    lastPointerX, lastPointerY, event.metaState
                )
                result = handleTouchEvent(up)
                up.recycle()
            }
        }
        if (event.action == MotionEvent.ACTION_UP) {
            performClick()
        }
        lastPointerCount = pointerCount
        return result
    }

    private fun handleTouchEvent(event: MotionEvent): Boolean {
        val keyboard = this.keyboard ?: return true
        if (abortKey && event.action != MotionEvent.ACTION_DOWN &&
            event.action != MotionEvent.ACTION_CANCEL
        ) {
            return true
        }

        val keys = keyboard.keys
        val touchX = (event.x - paddingLeft).toInt()
        val touchY = (event.y - paddingTop).toInt()

        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                abortKey = false
                currentKeyIndex = keyboard.getKeyIndex(touchX, touchY)
                if (currentKeyIndex == Keyboard.NOT_A_KEY) return true

                val currentKey = keys[currentKeyIndex]
                isPressed = true
                currentKey.onPressed()
                invalidateKey(currentKeyIndex)
                postDelayed(performLongPress, ViewConfiguration.getLongPressTimeout().toLong())
                if (currentKey.isRepeatable) {
                    sendKeyEvent()
                    postDelayed(performRepeatKey, REPEAT_KEY_START_DELAY)
                }
            }
            MotionEvent.ACTION_MOVE -> {
                removeCallbacks()
                if (currentKeyIndex == Keyboard.NOT_A_KEY) return true

                val currentKey = keys[currentKeyIndex]
                if (currentKey.isPressed) {
                    if (currentKey.isInside(touchX, touchY)) {
                        postDelayed(
                            performLongPress,
                            ViewConfiguration.getLongPressTimeout().toLong()
                        )
                    } else {
                        isPressed = false
                        currentKey.onReleased(false)
                        invalidateKey(currentKeyIndex)
                    }
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                abortKey = true
                removeCallbacks()
                if (currentKeyIndex == Keyboard.NOT_A_KEY) return true

                val currentKey = keys[currentKeyIndex]
                if (currentKey.isPressed) {
                    val isInside = currentKey.isInside(touchX, touchY)
                    isPressed = false
                    currentKey.onReleased(isInside)
                    invalidateKey(currentKeyIndex)
                    if (!currentKey.isRepeatable) {
                        sendKeyEvent()
                    }
                }
            }
        }
        return true
    }

    override fun performClick(): Boolean {
        PismoApp.printLog(TAG, "performClick")
        return super.performClick()
    }

    private fun sendKeyEvent() {
        if (currentKeyIndex == Keyboard.NOT_A_KEY) return
        val keyboard = this.keyboard ?: return
        val key = keyboard.keys[currentKeyIndex]
        callbacks.forEach { it.onKey(key.codes[0]) }
    }

    private fun removeCallbacks() {
        removeCallbacks(performLongPress)
        removeCallbacks(performRepeatKey)
    }

    private fun close() {
        removeCallbacks()
        buffer = null
        canvas = null
    }

    override fun onDetachedFromWindow() {
        close()
        super.onDetachedFromWindow()
    }

    /**
     * Listener for keyboard events.
     */
    interface KeyboardActionListener {
        fun onKey(primaryCode: Int)
        fun onStopInput()
    }
}
