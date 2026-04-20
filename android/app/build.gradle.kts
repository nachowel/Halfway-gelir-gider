plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nacho.gider"
    // Bumped from flutter.compileSdkVersion (35) → 36 because androidx.core:1.18.0
    // (pulled transitively by google_fonts) requires compileSdk ≥ 36.
    compileSdk = 36
    // Plugins (connectivity_plus, file_picker, image_picker_android, etc.) request
    // NDK 27.0.12077973; NDK is backward-compatible so we pin the highest requested.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // AGP 8.9.x toolchain baseline: Java 17.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nacho.gider"
        // androidx.core:core-ktx:1.18.0 (via google_fonts) requires minSdk ≥ 23.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
