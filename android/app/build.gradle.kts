plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sign_language"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sign_language"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = flutter.minSdkVersion
        // targetSdk = flutter.targetSdkVersion
        // versionCode = flutter.versionCode
        // versionName = flutter.versionName

        minSdk = 28
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // ndk {
        //     abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        // }

        // externalNativeBuild {
        //     cmake {
        //         cppFlags += listOf("-std=c++17", "-fexceptions", "-frtti", "-O2")
        //         arguments += listOf(
        //             "-DANDROID_PLATFORM=android-28",
        //             "-DANDROID_STL=c++_shared"
        //         )
        //     }
        // }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // externalNativeBuild {
    //     cmake {
    //         path "src/main/cpp/CMakeLists.txt"
    //     }
    // }

    // sourceSets {
    //     main {
    //         jniLibs.srcDirs = ['src/main/jniLibs']
    //     }
    // }
}

flutter {
    source = "../.."
}
