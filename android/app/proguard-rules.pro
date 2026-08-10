# Keep members of the generated BuildContext/R classes if necessary
-keep class **.R$* {
    <fields>;
}

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AdMob
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }

# Prevent R8 from stripping away native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Common ProGuard settings for Flutter plugins
-dontwarn com.google.android.play.core.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**



