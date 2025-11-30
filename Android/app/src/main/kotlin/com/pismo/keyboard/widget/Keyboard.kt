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
import android.content.res.Resources
import android.content.res.XmlResourceParser
import android.graphics.drawable.Drawable
import android.util.TypedValue
import android.util.Xml
import com.pismo.keyboard.R
import com.pismo.keyboard.util.DimensUtil.getDimensionOrFraction
import com.pismo.keyboard.util.StringUtil.parseCSV
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException
import java.util.Locale

/**
 * Loads an XML description of a keyboard and stores the attributes of the keys.
 *
 * A keyboard consists of rows of keys.
 *
 * @param context The context
 * @param layoutRes The XML resource ID for the keyboard layout
 */
class Keyboard(context: Context, layoutRes: Int) {

    companion object {
        /** Keyboard layout types */
        const val DEF_TYPE = "xml"
        const val LAYOUT_KEYBOARD_CYRILLIC_RU = "keyboard_cyrillic_ru"
        const val LAYOUT_KEYBOARD_SYMBOL = "keyboard_symbol"

        /** XML layout tags */
        const val TAG_KEYBOARD = "Keyboard"
        const val TAG_ROW = "Row"
        const val TAG_KEY = "Key"

        /** Edge flags */
        const val EDGE_LEFT = 0x01
        const val EDGE_RIGHT = 0x02
        const val EDGE_TOP = 0x04
        const val EDGE_BOTTOM = 0x08

        /** Key codes */
        const val KEYCODE_ENTER = '\n'.code
        const val KEYCODE_SPACE = ' '.code
        const val KEYCODE_SHIFT = -1
        const val KEYCODE_MODE_CHANGE = -2
        const val KEYCODE_DONE = -4
        const val KEYCODE_DELETE = -5
        const val KEYCODE_ALT = -6
        const val KEYCODE_MAIN_KEYBOARD = -8
        const val KEYCODE_CLOSE_KEYBOARD = -99

        const val NOT_A_KEY = -1

        /** Keyboard key drawable states */
        private val KEY_STATE_NORMAL = intArrayOf()
        private val KEY_STATE_PRESSED = intArrayOf(android.R.attr.state_pressed)
        private val KEY_STATE_NORMAL_ON = intArrayOf(
            android.R.attr.state_checkable,
            android.R.attr.state_checked
        )
        private val KEY_STATE_NORMAL_OFF = intArrayOf(android.R.attr.state_checkable)
        private val KEY_STATE_PRESSED_ON = intArrayOf(
            android.R.attr.state_pressed,
            android.R.attr.state_checkable,
            android.R.attr.state_checked
        )
        private val KEY_STATE_PRESSED_OFF = intArrayOf(
            android.R.attr.state_pressed,
            android.R.attr.state_checkable
        )
    }

    /** Display dimensions */
    private val displayWidth: Int = context.resources.displayMetrics.widthPixels
    private val displayHeight: Int = context.resources.displayMetrics.heightPixels

    /** Keyboard dimensions */
    internal var keyboardWidth: Int = 0
    internal var keyboardHeight: Int = 0

    /** Default key properties */
    private var defaultKeyWidth: Int = displayWidth / 10
    private var defaultKeyHeight: Int = defaultKeyWidth
    private var defaultKeyHorizontalGap = 0
    private var defaultKeyVerticalGap = 0

    /** List of rows and keys */
    private val rows: ArrayList<Row> = ArrayList()
    internal val keys: ArrayList<Key> = ArrayList()

    /** Shift state */
    internal var isShifted = false
    private val shiftKeys = arrayOf<Key?>(null, null)
    private val modifierKeys: ArrayList<Key> = ArrayList()

    init {
        loadKeyboard(context, context.resources.getXml(layoutRes))
    }

    @Throws(XmlPullParserException::class)
    private fun loadKeyboard(context: Context, parser: XmlResourceParser) {
        var x = 0
        var y = 0
        var inKey = false
        var inRow = false
        var currentRow: Row? = null
        var currentKey: Key? = null

        while (parser.next() != XmlPullParser.END_DOCUMENT) {
            if (parser.eventType == XmlPullParser.START_TAG) {
                when (parser.name) {
                    TAG_KEYBOARD -> {
                        parseKeyboardAttributes(context.resources, parser)
                    }
                    TAG_ROW -> {
                        x = 0
                        inRow = true
                        currentRow = Row(context.resources, parser)
                        rows.add(currentRow)
                    }
                    TAG_KEY -> {
                        inKey = true
                        if (currentRow != null) {
                            currentKey = Key(
                                context.resources,
                                context.theme,
                                x,
                                y,
                                parser,
                                currentRow
                            )
                            keys.add(currentKey)
                            if (currentKey.codes.isNotEmpty() &&
                                currentKey.codes[0] == KEYCODE_SHIFT
                            ) {
                                for (i in shiftKeys.indices) {
                                    if (shiftKeys[i] == null) {
                                        shiftKeys[i] = currentKey
                                        break
                                    }
                                }
                                modifierKeys.add(currentKey)
                            } else if (currentKey.codes.isNotEmpty() &&
                                currentKey.codes[0] == KEYCODE_ALT
                            ) {
                                modifierKeys.add(currentKey)
                            }
                            currentRow.keys.add(currentKey)
                        }
                    }
                }
            } else if (parser.eventType == XmlPullParser.END_TAG) {
                if (inKey) {
                    inKey = false
                    if (currentKey != null) {
                        x += currentKey.width + currentKey.horizontalGap
                        if (x > keyboardWidth) {
                            keyboardWidth = x
                        }
                    }
                } else if (inRow) {
                    inRow = false
                    if (currentRow != null) {
                        y += currentRow.keyHeight + currentRow.keyVerticalGap
                    }
                }
            }
        }
        keyboardHeight = y - defaultKeyVerticalGap
    }

    private fun parseKeyboardAttributes(res: Resources, parser: XmlResourceParser) {
        parser.require(XmlPullParser.START_TAG, null, TAG_KEYBOARD)
        val ta = res.obtainAttributes(Xml.asAttributeSet(parser), R.styleable.Keyboard)
        defaultKeyWidth = ta.getDimensionOrFraction(
            R.styleable.Keyboard_keyWidth,
            displayWidth,
            defaultKeyWidth
        )
        defaultKeyHeight = ta.getDimensionOrFraction(
            R.styleable.Keyboard_keyHeight,
            displayHeight,
            defaultKeyHeight
        )
        defaultKeyHorizontalGap = ta.getDimensionOrFraction(
            R.styleable.Keyboard_keyHorizontalGap,
            displayWidth,
            defaultKeyHorizontalGap
        )
        defaultKeyVerticalGap = ta.getDimensionOrFraction(
            R.styleable.Keyboard_keyVerticalGap,
            displayHeight,
            defaultKeyVerticalGap
        )
        ta.recycle()
    }

    /**
     * Returns the index of the key at the given touch coordinates.
     */
    fun getKeyIndex(x: Int, y: Int): Int {
        for (index in keys.indices) {
            if (keys[index].isInside(x, y)) return index
        }
        return NOT_A_KEY
    }

    /**
     * Sets the shift state of the keyboard.
     */
    fun setShifted(shiftState: Boolean): Boolean {
        for (shiftKey in shiftKeys) {
            if (shiftKey != null) {
                shiftKey.isOn = shiftState
            }
        }
        if (isShifted != shiftState) {
            isShifted = shiftState
            return true
        }
        return false
    }

    /**
     * Container for keys in a row of the keyboard.
     */
    inner class Row(res: Resources, parser: XmlResourceParser) {
        private val keyWidth: Int
        internal val keyHeight: Int
        private val keyHorizontalGap: Int
        internal val keyVerticalGap: Int
        internal val rowEdgeFlags: Int
        internal val keys: ArrayList<Key> = ArrayList()

        init {
            parser.require(XmlPullParser.START_TAG, null, TAG_ROW)
            var ta = res.obtainAttributes(Xml.asAttributeSet(parser), R.styleable.Keyboard)
            keyWidth = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyWidth,
                displayWidth,
                defaultKeyWidth
            )
            keyHeight = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyHeight,
                displayHeight,
                defaultKeyHeight
            )
            keyHorizontalGap = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyHorizontalGap,
                displayWidth,
                defaultKeyHorizontalGap
            )
            keyVerticalGap = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyVerticalGap,
                displayHeight,
                defaultKeyVerticalGap
            )
            ta.recycle()
            ta = res.obtainAttributes(Xml.asAttributeSet(parser), R.styleable.Keyboard_Row)
            rowEdgeFlags = ta.getInt(R.styleable.Keyboard_Row_rowEdgeFlags, 0)
            ta.recycle()
        }
    }

    /**
     * Class representing a single key on the keyboard.
     */
    inner class Key(
        res: Resources,
        theme: Resources.Theme,
        x: Int,
        y: Int,
        parser: XmlResourceParser,
        parentRow: Row
    ) {
        val x: Int
        val y: Int
        internal val width: Int
        internal val height: Int
        internal val horizontalGap: Int
        internal var codes = intArrayOf()
        internal var popupKeyboardChars: CharSequence = ""
        private val edgeFlags: Int
        private val sticky: Boolean
        internal var isOn = false
        internal val isRepeatable: Boolean
        internal var label: CharSequence = ""
        internal val icon: Drawable?
        private var _isPressed = false
        internal val isPressed get() = _isPressed

        init {
            parser.require(XmlPullParser.START_TAG, null, TAG_KEY)
            var ta = res.obtainAttributes(Xml.asAttributeSet(parser), R.styleable.Keyboard)
            width = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyWidth,
                displayWidth,
                defaultKeyWidth
            )
            height = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyHeight,
                displayHeight,
                defaultKeyHeight
            )
            horizontalGap = ta.getDimensionOrFraction(
                R.styleable.Keyboard_keyHorizontalGap,
                displayWidth,
                defaultKeyHorizontalGap
            )
            this.x = x  // Set x position without extra gap (gap is handled in loadKeyboard)
            this.y = y
            ta.recycle()

            ta = res.obtainAttributes(Xml.asAttributeSet(parser), R.styleable.Keyboard_Key)
            val keyCodesTypedVal = TypedValue()
            ta.getValue(R.styleable.Keyboard_Key_codes, keyCodesTypedVal)
            if (keyCodesTypedVal.type == TypedValue.TYPE_INT_DEC ||
                keyCodesTypedVal.type == TypedValue.TYPE_INT_HEX
            ) {
                codes = intArrayOf(keyCodesTypedVal.data)
            } else if (keyCodesTypedVal.type == TypedValue.TYPE_STRING) {
                codes = keyCodesTypedVal.string.toString().parseCSV()
            }
            popupKeyboardChars = ta.getText(R.styleable.Keyboard_Key_popupCharacters) ?: ""
            edgeFlags = ta.getInt(R.styleable.Keyboard_Key_keyEdgeFlags, 0) or parentRow.rowEdgeFlags
            sticky = ta.getBoolean(R.styleable.Keyboard_Key_isSticky, false)
            isRepeatable = ta.getBoolean(R.styleable.Keyboard_Key_isRepeatable, false)
            label = ta.getText(R.styleable.Keyboard_Key_keyLabel) ?: ""
            icon = ta.getDrawable(R.styleable.Keyboard_Key_keyIcon)
            icon?.apply {
                setBounds(0, 0, intrinsicWidth, intrinsicHeight)
            }
            icon?.applyTheme(theme)
            if (codes.isEmpty() && label.isNotEmpty()) {
                codes = intArrayOf(label[0].code)
            }
            // Debug: log key codes for special keys
            if (codes.isNotEmpty() && codes[0] < 0) {
                android.util.Log.d("Pismo/Keyboard", "Key parsed: label='$label' codes=${codes.toList()}")
            }
            ta.recycle()
        }

        /**
         * Detects if a point falls inside this key.
         */
        fun isInside(x: Int, y: Int): Boolean {
            val leftEdge = edgeFlags and EDGE_LEFT > 0
            val rightEdge = edgeFlags and EDGE_RIGHT > 0
            val topEdge = edgeFlags and EDGE_TOP > 0
            val bottomEdge = edgeFlags and EDGE_BOTTOM > 0
            return (
                (x >= this.x || leftEdge && x <= this.x + width) &&
                    (x < this.x + width || rightEdge && x >= this.x) &&
                    (y >= this.y || topEdge && y <= this.y + height) &&
                    (y < this.y + height || bottomEdge && y >= this.y)
                )
        }

        /**
         * Adjusts the label case based on shift state.
         */
        fun adjustLabelCase(locale: Locale): String {
            var labelText = this.label
            if (isShifted &&
                labelText.isNotEmpty() &&
                labelText.length < 3 &&
                Character.isLowerCase(labelText[0])
            ) {
                labelText = labelText.toString().uppercase(locale)
            }
            return labelText.toString()
        }

        fun onPressed() {
            _isPressed = true
        }

        fun onReleased(inside: Boolean) {
            _isPressed = false
            if (sticky && inside) {
                isOn = !isOn
            }
        }

        fun getDrawableState(): IntArray {
            var states: IntArray = KEY_STATE_NORMAL
            if (isOn) {
                states = if (_isPressed) KEY_STATE_PRESSED_ON else KEY_STATE_NORMAL_ON
            } else {
                if (sticky) {
                    states = if (_isPressed) KEY_STATE_PRESSED_OFF else KEY_STATE_NORMAL_OFF
                } else {
                    if (_isPressed) {
                        states = KEY_STATE_PRESSED
                    }
                }
            }
            return states
        }

        /**
         * Returns true if this key has the EDGE_RIGHT flag set.
         */
        fun hasEdgeRight(): Boolean = edgeFlags and EDGE_RIGHT > 0
    }
}
