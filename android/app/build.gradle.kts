plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.musio"

    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.musio"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // On active la réduction de code
            isMinifyEnabled = true
            isShrinkResources = true

            // ON AJOUTE CETTE LIGNE POUR LIRE TON FICHIER :
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

/** ✅ Kotlin JVM 17 (évite l’erreur 1.8 vs 17) */
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}
