plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ajmal.taxi_app"
    compileSdk = 35 // yoki o'zingniki
    defaultConfig {
        applicationId = "com.ajmal.taxi_app"
        minSdk = 23
        targetSdk = 35 // yoki o'zingniki
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    ndkVersion = "26.1.10909125" // Eng so'nggi NDK
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0")
}
