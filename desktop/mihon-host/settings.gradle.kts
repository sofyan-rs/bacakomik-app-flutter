// Yoru's Mihon extension host for Windows, macOS and Linux
// (docs/ARCHITECTURE.md §8.9): the Kotlin code of android/mihon on a JVM,
// over SCANCORE's AndroidCompat and dex2jar loader. See NOTICE.md.
rootProject.name = "yoru-mihon-host"

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
        google()
        // JetBrains' JCEF, which compat's web view classes compile against.
        maven("https://packages.jetbrains.team/maven/p/ij/intellij-dependencies") {
            content { includeGroup("org.jetbrains.intellij.deps.jcef") }
        }
    }
}

include(":compat", ":host")
