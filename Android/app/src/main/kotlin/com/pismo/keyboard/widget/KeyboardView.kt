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
import android.view.ViewGroup
import android.widget.FrameLayout
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

    // Flick gesture tracking
    private var flickStartX = 0f
    private var flickStartY = 0f
    private var currentFlickDirection = FlickDirection.CENTER

    // Flick popup overlay
    private var flickPopupView: FlickPopupView? = null
    private var popupContainer: FrameLayout? = null
    private val popupWidth = (80 * resources.displayMetrics.density).toInt()
    private val popupHeight = (100 * resources.displayMetrics.density).toInt()
    private var activeFlickKey: Keyboard.Key? = null

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
        // Request parent to not intercept touch events during keyboard switch
        parent?.requestDisallowInterceptTouchEvent(true)
        invalidateAllKeys()
        // Reset after a short delay
        postDelayed({ parent?.requestDisallowInterceptTouchEvent(false) }, 100)
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

    /**
     * Sets the popup container for flick input overlay.
     * This should be called from the InputMethodService after inflating the layout.
     */
    fun setPopupContainer(container: FrameLayout) {
        PismoApp.printLog(TAG, "setPopupContainer: container=$container")
        this.popupContainer = container
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
        // Use save/restore to prevent clipRect from accumulating
        canvas.save()
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
        canvas.restore()

        drawPending = false
        dirtyRect.setEmpty()
    }

    private fun onKeyDraw(key: Keyboard.Key) {
        val canvas = this.canvas ?: return
        val drawableState = key.getDrawableState()
        keyBackground?.state = drawableState
        key.icon?.state = drawableState

        // Calculate actual draw width - extend to actual view edge if key has EDGE_RIGHT flag
        // Use actual view width (width - padding) instead of keyboard.keyboardWidth to avoid rounding errors
        val actualKeyboardWidth = width - paddingLeft - paddingRight
        val drawWidth = if (key.hasEdgeRight()) {
            actualKeyboardWidth - key.x
        } else {
            key.width
        }

        val bounds = keyBackground?.bounds
        if (drawWidth != bounds?.right || key.height != bounds.bottom) {
            keyBackground?.setBounds(0, 0, drawWidth, key.height)
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
                // Prevent parent from intercepting touch events
                parent?.requestDisallowInterceptTouchEvent(true)
                abortKey = false
                currentKeyIndex = keyboard.getKeyIndex(touchX, touchY)
                PismoApp.printLog(TAG, "ACTION_DOWN: touchX=$touchX touchY=$touchY keyIndex=$currentKeyIndex")
                if (currentKeyIndex == Keyboard.NOT_A_KEY) return true

                val currentKey = keys[currentKeyIndex]
                PismoApp.printLog(TAG, "ACTION_DOWN: key label='${currentKey.label}' codes=${currentKey.codes.toList()}")

                // Initialize flick tracking
                flickStartX = event.x
                flickStartY = event.y
                currentFlickDirection = FlickDirection.CENTER

                isPressed = true
                currentKey.onPressed()
                invalidateKey(currentKeyIndex)

                // Show flick popup if key has flick mappings
                PismoApp.printLog(TAG, "hasFlickMappings=${currentKey.hasFlickMappings()} popupChars='${currentKey.popupKeyboardChars}'")
                if (currentKey.hasFlickMappings()) {
                    PismoApp.printLog(TAG, "Showing flick popup for key '${currentKey.label}'")
                    showFlickPopup(currentKey, currentKey.x, currentKey.y)
                }

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

                // Update flick direction based on current position
                currentFlickDirection = FlickDirection.fromCoordinates(
                    flickStartX, flickStartY, event.x, event.y
                )

                // Update popup direction indicator
                updateFlickPopup(currentFlickDirection)

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
                    // Calculate final flick direction
                    currentFlickDirection = FlickDirection.fromCoordinates(
                        flickStartX, flickStartY, event.x, event.y
                    )
                    PismoApp.printLog(TAG, "ACTION_UP: flick direction=$currentFlickDirection")

                    val isInside = currentKey.isInside(touchX, touchY)
                    isPressed = false
                    currentKey.onReleased(isInside)
                    invalidateKey(currentKeyIndex)
                    if (!currentKey.isRepeatable) {
                        sendKeyEvent()
                    }
                }
                // Hide popup and reset flick state
                hideFlickPopup()
                currentFlickDirection = FlickDirection.CENTER
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

        // Use flick direction to get the appropriate character code
        val code = key.getCodeForFlickDirection(currentFlickDirection)
        val flickLabel = key.getLabelForFlickDirection(currentFlickDirection)

        PismoApp.printLog(TAG, "sendKeyEvent: keyIndex=$currentKeyIndex label='${key.label}' " +
            "flickDirection=$currentFlickDirection flickLabel='$flickLabel' code=$code")

        callbacks.forEach { it.onKey(code) }
    }

    private fun removeCallbacks() {
        removeCallbacks(performLongPress)
        removeCallbacks(performRepeatKey)
    }

    /**
     * Shows the flick popup for a key with flick mappings.
     */
    private fun showFlickPopup(key: Keyboard.Key, keyX: Int, keyY: Int) {
        PismoApp.printLog(TAG, "showFlickPopup: keyX=$keyX keyY=$keyY container=$popupContainer")
        if (!key.hasFlickMappings()) return

        val container = popupContainer
        if (container == null) {
            PismoApp.printLog(TAG, "showFlickPopup: no popup container set!")
            return
        }

        // Create popup view if needed
        if (flickPopupView == null) {
            flickPopupView = FlickPopupView(context)
            PismoApp.printLog(TAG, "showFlickPopup: created new FlickPopupView")
        }

        val popupView = flickPopupView ?: return

        // Set labels from key's popup characters
        val center = key.label.toString()
        val chars = key.popupKeyboardChars
        val top = if (chars.isNotEmpty()) chars[0].toString() else ""
        val left = if (chars.length > 1) chars[1].toString() else ""
        val right = if (chars.length > 2) chars[2].toString() else ""
        val bottom = if (chars.length > 3) chars[3].toString() else ""

        popupView.setLabels(center, top, left, right, bottom)
        popupView.setDirection(FlickDirection.CENTER)

        // Calculate popup position centered above the key
        // Use keyboard view dimensions since container might not be laid out yet
        val popupX = keyX + key.width / 2 - popupWidth / 2
        val popupY = keyY - popupHeight - (10 * resources.displayMetrics.density).toInt()

        // Ensure popup stays within keyboard view bounds
        val maxX = width - popupWidth
        val adjustedX = if (maxX > 0) popupX.coerceIn(0, maxX) else popupX.coerceAtLeast(0)
        val adjustedY = popupY.coerceAtLeast(0)

        // Remove from parent if already added
        (popupView.parent as? ViewGroup)?.removeView(popupView)

        // Create layout params for positioning
        val params = FrameLayout.LayoutParams(popupWidth, popupHeight).apply {
            leftMargin = adjustedX
            topMargin = adjustedY
        }

        // Add to container and make visible
        container.addView(popupView, params)
        container.visibility = View.VISIBLE
        activeFlickKey = key

        PismoApp.printLog(TAG, "showFlickPopup: popup added at ($adjustedX, $adjustedY)")
    }

    /**
     * Updates the flick popup direction indicator.
     */
    private fun updateFlickPopup(direction: FlickDirection) {
        flickPopupView?.setDirection(direction)
    }

    /**
     * Hides the flick popup.
     */
    private fun hideFlickPopup() {
        val popupView = flickPopupView ?: return
        val container = popupContainer ?: return

        (popupView.parent as? ViewGroup)?.removeView(popupView)
        container.visibility = View.GONE
        activeFlickKey = null

        PismoApp.printLog(TAG, "hideFlickPopup: popup hidden")
    }

    private fun close() {
        removeCallbacks()
        hideFlickPopup()
        popupContainer = null
        flickPopupView = null
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
