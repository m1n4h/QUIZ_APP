// /home/minah/Pictures/flutter course/QUIZ_APP/quiz_mobile/android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quiz_mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.quiz_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode as Int // Explicitly cast to Int if needed, or ensure flutter.versionCode is Int
        versionName = flutter.versionName

        // Corrected manifestPlaceholders syntax
        manifestPlaceholders["appAuthRedirectScheme"] = "com.example.quiz_mobile"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true // Correct property name is isMinifyEnabled
            isShrinkResources = true // Keep false for faster debug builds
            // Corrected proguardFiles function call and string literals
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            // You might want to also set isMinifyEnabled = false here if you're not minifying debug builds
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro") // Optional for debug
        }
    }
}

flutter {
    source = "../.."
}

// Corrected dependencies declaration using Kotlin DSL syntax
dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("androidx.browser:browser:1.5.0")
}