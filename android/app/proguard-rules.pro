# Keep rules for release builds. If you enable minify (isMinifyEnabled = true),
# uncomment or use these so network/reflection and plugins keep working.
# -keep class com.ryanheise.just_audio.** { *; }
# -keep class kotlin.** { *; }
# -keep class com.google.android.exoplayer2.** { *; }
# -keepattributes Signature
# -keepattributes *Annotation*
# -dontwarn org.conscrypt.**

# Preserve Dart/Flutter plugin classes if you enable R8 later
# -keep class io.flutter.plugins.** { *; }
