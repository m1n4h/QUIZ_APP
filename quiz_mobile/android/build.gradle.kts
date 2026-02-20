// In your Flutter project, this file is located at `android/build.gradle.kts`

plugins {
    // These are typically already present for your Android and Kotlin setup
    id("com.android.application") version "8.9.1" apply false // Use your actual Android Application plugin version
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false // Use your actual Kotlin Android plugin version

    // This is the line that *must* be present with the version
    // You should check for the absolute latest stable version, but "4.3.15" is a common one.
    id("com.google.gms.google-services") version "4.3.15" apply false
}

// The 'allprojects' and 'subprojects' blocks you provided typically come after the plugins block.
allprojects {
    repositories {
        google()
        maven(url = "https://repo1.maven.org/maven2/")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}