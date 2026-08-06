# Flutter Proguard Rules

# Standard Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AdMob / Google Mobile Ads specific rules (if needed, though usually included in the library)
-keep public class com.google.android.gms.ads.** {
   public *;
}

# Keep members of the generated BuildContext/R classes if necessary
-keep class **.R$* {
    <fields>;
}

# Play Core Library rules (to fix R8 errors about missing classes)
-dontwarn com.google.android.play.core.**

# Additional Flutter/Android rules
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**


