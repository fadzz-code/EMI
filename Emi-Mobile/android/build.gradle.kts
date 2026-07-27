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
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null && project.name == "flutter_bluetooth_serial") {
                namespace = "io.github.edufolly.flutterbluetoothserial"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
