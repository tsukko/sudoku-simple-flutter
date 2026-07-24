plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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

        // secrets.json から AdMob アプリIDを読み込む
        val secretsFile = rootProject.file("secrets.json")
        val admobAppId = if (secretsFile.exists()) {
            try {
                val json = groovy.json.JsonSlurper().parseText(secretsFile.readText()) as Map<*, *>
                json["ZEN_SUDOKU_ADMOB_APP_ID"] as? String
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }
        
        // 取得できない場合はテスト用IDをデフォルトにする
        manifestPlaceholders["zenSudokuAdmobAppId"] = admobAppId ?: "ca-app-pub-3940256099942544~3347511713"
    }

    val keystorePropertiesFile = rootProject.file("android/key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as? String
            keyPassword = keystoreProperties["keyPassword"] as? String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as? String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
