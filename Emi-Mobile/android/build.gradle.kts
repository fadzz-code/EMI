allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// `flutter_bluetooth_serial` (last published 2021, unmaintained) has no
// `namespace` declared in its own `android/build.gradle`, which the
// Android Gradle Plugin used here (8.x) requires. Rather than forking the
// plugin, backfill the namespace from its manifest package at configure
// time — a standard, non-invasive workaround for this exact class of
// abandoned-plugin AGP incompatibility.
//
// It also hardcodes `compileSdkVersion 30`, which predates the
// `android:attr/lStar` resource introduced in API 31 — release builds
// (which enable resource shrinking/verification) fail to link against
// that resource with "AAPT: error: resource android:attr/lStar not
// found." Bumping this plugin's own compileSdk to match the app's
// (`flutter.compileSdkVersion`, currently 36) resolves it without
// touching the plugin's Kotlin/Java sources.
subprojects {
    if (project.name == "flutter_bluetooth_serial") {
        afterEvaluate {
            plugins.withId("com.android.library") {
                extensions.configure<com.android.build.gradle.LibraryExtension> {
                    if (namespace == null) {
                        namespace = "io.github.edufolly.flutterbluetoothserial"
                    }
                    compileSdk = 36
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
