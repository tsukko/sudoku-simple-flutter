import java.util.Properties
import java.io.FileInputStream
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = File(rootProject.projectDir, "key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// secrets.json から AdMob アプリIDを読み込む
val secretsFile = rootProject.file("../secrets.json")
val admobAppId = if (secretsFile.exists()) {
    try {
        val json = JsonSlurper().parseText(secretsFile.readText()) as Map<*, *>
        json["ZEN_SUDOKU_ADMOB_APP_ID"] as? String
    } catch (e: Exception) {
        null
    }
} else {
    null
}

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
            val alias = keystoreProperties.getProperty("keyAlias")
            val keyPass = keystoreProperties.getProperty("keyPassword")
            val storePass = keystoreProperties.getProperty("storePassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")

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
            // key.properties があり、かつ必要な項目が揃っている場合のみ release 署名を使う
            val isSigningConfigReady = keystoreProperties.containsKey("keyAlias") && 
                                      keystoreProperties.containsKey("keyPassword") && 
                                      keystoreProperties.containsKey("storePassword") && 
                                      keystoreProperties.containsKey("storeFile")
            
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
