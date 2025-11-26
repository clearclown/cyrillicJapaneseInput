# Pismo - ProGuard Rules
# Add project specific ProGuard rules here.

# Keep InputMethodService
-keep class * extends android.inputmethodservice.InputMethodService

# Keep custom views
-keep class com.pismo.keyboard.widget.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }
