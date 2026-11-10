# Project-specific R8/ProGuard rules for the Android release build.
#
# Note: most Flutter/Dart code is compiled to native code by Flutter, so this
# file mainly affects Android/Kotlin/Java code and native Android plugins.

# -----------------------------------------------------------------------------
# Flutter embedding / plugin registration
# -----------------------------------------------------------------------------
# Keep Flutter framework and generated plugin wrapper classes. These classes are
# referenced from generated Android glue code and plugin registration paths.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep app entry point. It is declared in AndroidManifest.xml and extends
# AudioServiceActivity, so keeping the class name avoids lifecycle lookup issues.
-keep class com.example.bilimusic.MainActivity { *; }

# Keep Flutter plugin implementation class names. GeneratedPluginRegistrant
# directly references many of them, but keeping names is a safe middle ground:
# it does not disable optimization of their internals.
-keepnames class * implements io.flutter.embedding.engine.plugins.FlutterPlugin

# Flutter contains optional support for Play Store deferred components. This app
# does not declare Android dynamic feature modules, so Play Core splitinstall
# classes are not packaged. Suppress only those optional-reference warnings.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# -----------------------------------------------------------------------------
# Audio playback / media session
# -----------------------------------------------------------------------------
# audio_service declares Android Service/Receiver components used by the system
# and media buttons. Keep them because Android may instantiate them by name.
-keep class com.ryanheise.audioservice.** { *; }

# just_audio and media_kit plugins are used for playback. Their plugin packages
# may interact with ExoPlayer/Media3/native layers, so preserve public APIs while
# still allowing R8 to optimize private implementation details.
-keep class com.ryanheise.just_audio.** { public *; }
-keep class com.alexmercerind.media_kit_libs_android_audio.** { public *; }

# -----------------------------------------------------------------------------
# Android reflection / annotations metadata
# -----------------------------------------------------------------------------
# Keep common metadata used by Kotlin, reflection, generic signatures,
# annotations, and useful release stack traces.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Hide the original source file names in release stack traces while retaining
# line numbers. Remove this line if you prefer original file names for debugging.
-renamesourcefileattribute SourceFile

# -----------------------------------------------------------------------------
# WebView JavaScript bridge
# -----------------------------------------------------------------------------
# This project currently has no native WebView JavaScript interface. If you add
# one later, keep only the exact bridge class/methods annotated with
# @JavascriptInterface instead of keeping broad packages.
# Example:
# -keepclassmembers class com.example.bilimusic.MyJsBridge {
#     @android.webkit.JavascriptInterface <methods>;
# }
