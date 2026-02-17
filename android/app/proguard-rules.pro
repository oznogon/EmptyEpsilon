# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep SDL2 Activity and related classes
-keep class org.libsdl.app.** { *; }
-keep class eu.daid.emptyepsilon.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
