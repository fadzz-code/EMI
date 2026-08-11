import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested) {
    val signingKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
    val missingSigningKeys = signingKeys.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    require(hasReleaseSigning && missingSigningKeys.isEmpty()) {
        "Release signing requires android/key.properties with ${signingKeys.joinToString()}."
    }
    require(file(keystoreProperties.getProperty("storeFile")).isFile) {
        "Release signing storeFile does not exist."
    }

    val dartDefines = (project.findProperty("dart-defines") as String?)
        .orEmpty()
        .split(',')
        .filter { it.isNotBlank() }
        .associate { encoded ->
            String(Base64.getDecoder().decode(encoded), Charsets.UTF_8).split('=', limit = 2).let {
                it.first() to it.getOrElse(1) { "" }
            }
        }
    require(dartDefines["APP_ENV"] == "production") {
        "Release requires --dart-define=APP_ENV=production."
    }
    require(dartDefines["API_BASE_URL"]?.startsWith("https://") == true) {
        "Release requires HTTPS --dart-define=API_BASE_URL."
    }
}

android {
    namespace = "id.emikolaka.emi_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "id.emikolaka.emi_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
