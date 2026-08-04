import java.util.Properties
import java.io.FileInputStream
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// secrets.json から機密情報を一括読み込み
val secretsFile = rootProject.file("../secrets.json")
val secretsJson = if (secretsFile.exists()) {
    try {
        JsonSlurper().parseText(secretsFile.readText()) as Map<*, *>
    } catch (e: Exception) {
        emptyMap<String, String>()
    }
} else {
    emptyMap<String, String>()
}

val admobAppId = secretsJson["ZEN_SUDOKU_ADMOB_APP_ID"] as? String

android {
    namespace = "jp.co.integrityworks.sudoku"
    compileSdk = libs.versions.compileSdk.get().toInt()
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.co.integrityworks.sudoku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = libs.versions.targetSdk.get().toInt()
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 取得できない場合はテスト用IDをデフォルトにする
        manifestPlaceholders["zenSudokuAdmobAppId"] = admobAppId ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            val alias = secretsJson["ZEN_SUDOKU_ANDROID_KEY_ALIAS"] as? String
            val keyPass = secretsJson["ZEN_SUDOKU_ANDROID_KEY_PASSWORD"] as? String
            val storePass = secretsJson["ZEN_SUDOKU_ANDROID_STORE_PASSWORD"] as? String
            val storeFilePath = secretsJson["ZEN_SUDOKU_ANDROID_STORE_FILE"] as? String

            if (alias != null && keyPass != null && storePass != null && storeFilePath != null) {
                keyAlias = alias
                keyPassword = keyPass
                storePassword = storePass
                storeFile = file(storeFilePath)
            }
        }
    }

    buildTypes {
        release {
            // secrets.json があり、かつ必要な署名項目が揃っている場合のみ release 署名を使う
            val isSigningConfigReady = secretsJson.containsKey("ZEN_SUDOKU_ANDROID_KEY_ALIAS") && 
                                      secretsJson.containsKey("ZEN_SUDOKU_ANDROID_KEY_PASSWORD") && 
                                      secretsJson.containsKey("ZEN_SUDOKU_ANDROID_STORE_PASSWORD") && 
                                      secretsJson.containsKey("ZEN_SUDOKU_ANDROID_STORE_FILE")
            
            signingConfig = if (isSigningConfigReady) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
