plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire plugin
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties if exists
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nil.streamapp" // Matches your app ID
    compileSdk = 36 // Required by plugins
    ndkVersion = "27.0.12077973" // Only needed if using NDK plugins

    defaultConfig {
        applicationId = "com.nil.streamapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Optional: MultiDex if your app exceeds method limit
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Temporarily disabled to fix build - can enable later
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("release") // Optional: debug with same key
        }
    }
}

flutter {
    source = "../.." // Adjust path if needed
}

dependencies {
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.multidex:multidex:2.0.1") // Optional for MultiDex
}
