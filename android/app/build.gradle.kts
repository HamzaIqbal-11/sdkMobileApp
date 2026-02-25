plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gyroscope"
    compileSdk = flutter.compileSdkVersion

    // ✅ Fix 1: NDK version hardcoded to match plugin requirement
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.gyroscope"
        // ✅ Fix 2: minSdk 24 - gyroscope SDK requires minimum API 24
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Fix 3: SDK dependency REMOVED - plugin handles this internally
// Duplicate karne ki zaroorat nahi - gyroscope_plugin already JitPack se leta hai