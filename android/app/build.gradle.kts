import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (Google Play upload key):
// - Codemagic: the android_signing keystore exports CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD,
//   CM_KEY_ALIAS and CM_KEY_PASSWORD.
// - Local: android/key.properties (storeFile, storePassword, keyAlias, keyPassword); never commit it.
// Without either, release builds fall back to the debug key so `flutter run --release` still works;
// Google Play rejects those, and the Codemagic Play workflow checks the signature before uploading.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val ciKeystore = System.getenv("CM_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }
val localKeystore = keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotBlank() }

android {
    namespace = "com.securebydesigninc.secure_by_design_app"
    // Google Play requires new apps and updates to target Android 16 (API 36) from August 31, 2026.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once the first build is uploaded to Google Play.
        applicationId = "com.securebydesigninc.secure_by_design_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = maxOf(flutter.targetSdkVersion, 36)
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (ciKeystore != null) {
                storeFile = file(ciKeystore)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            } else if (localKeystore != null) {
                storeFile = rootProject.file(localKeystore)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (ciKeystore != null || localKeystore != null) {
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
