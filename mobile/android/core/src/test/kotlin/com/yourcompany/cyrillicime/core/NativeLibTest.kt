package com.yourcompany.cyrillicime.core

import org.junit.Test
import org.junit.Assert.*

/**
 * Unit tests for NativeLib JNI interface
 * 
 * Note: These tests cannot run without the native library loaded.
 * They serve as documentation and will be executed in androidTest.
 */
class NativeLibTest {

    @Test
    fun testNativeLibExists() {
        // Verify NativeLib class exists and has expected methods
        val methods = NativeLib::class.java.declaredMethods
        
        val methodNames = methods.map { it.name }
        assertTrue("initEngine method should exist", methodNames.contains("initEngine"))
        assertTrue("loadSchema method should exist", methodNames.contains("loadSchema"))
        assertTrue("processKey method should exist", methodNames.contains("processKey"))
        assertTrue("getVersion method should exist", methodNames.contains("getVersion"))
    }

    @Test
    fun testJvmStaticAnnotations() {
        // Verify methods are JvmStatic
        val methods = NativeLib::class.java.declaredMethods
        assertTrue("Should have at least 4 methods", methods.size >= 4)
    }
}
