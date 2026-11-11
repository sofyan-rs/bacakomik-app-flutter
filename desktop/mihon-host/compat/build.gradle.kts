// Android API stand-ins for the desktop JVM: Suwayomi's AndroidCompat
// (MPL-2.0, see NOTICE.md) over AOSP's android.jar stubs.
import java.net.URI
import java.security.MessageDigest
import java.util.Base64
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
    `java-library`
}

// AOSP's public API 30 android.jar (Apache-2.0), the same file Suwayomi's
// getAndroid.sh uses, without the classes this module implements (and the
// java.*, org.json and similar copies the JVM or this module provide).
val androidJarUrl =
    "https://android.googlesource.com/platform/prebuilts/sdk/+/6cd31be5e4e25901aadf838120d71a79b46d9add/30/public/android.jar?format=TEXT"
val androidJarSha256 = "2f0e6e4ec44e95beefe0c041541afcec4f55f8b964b33599a987efb6e972f990"

val androidStubs by tasks.registering {
    val sources = layout.projectDirectory.dir("src/main/java")
    val download = layout.buildDirectory.file("android-stubs/android-30.jar")
    val output = layout.buildDirectory.file("android-stubs/android.jar")
    inputs.dir(sources)
    inputs.property("sha256", androidJarSha256)
    outputs.file(output)
    doLast {
        val raw = download.get().asFile
        if (!raw.exists() || sha256(raw.readBytes()) != androidJarSha256) {
            raw.parentFile.mkdirs()
            val text = URI(androidJarUrl).toURL().readText().replace("\n", "")
            raw.writeBytes(Base64.getDecoder().decode(text))
        }
        val bytes = raw.readBytes()
        check(sha256(bytes) == androidJarSha256) { "android.jar does not match its checksum" }
        val root = sources.asFile
        // Zip entries use "/" on every system (Windows paths do not).
        val implemented = root.walkTopDown().filter { it.isFile }.map { it.relativeTo(root).invariantSeparatorsPath.substringBeforeLast('.') }.toSet()
        val dropped = listOf("org/json/", "org/apache/", "org/w3c/", "org/xml/", "org/xmlpull/", "junit/", "javax/", "java/")
        ZipFile(raw).use { zip ->
            ZipOutputStream(output.get().asFile.outputStream().buffered()).use { out ->
                for (entry in zip.entries()) {
                    val name = entry.name
                    if (dropped.any { name.startsWith(it) }) continue
                    if (name.endsWith(".class")) {
                        val outer = name.removeSuffix(".class").substringBefore('$').removeSuffix("Kt")
                        if (outer in implemented) continue
                    }
                    out.putNextEntry(ZipEntry(name))
                    zip.getInputStream(entry).use { it.copyTo(out) }
                    out.closeEntry()
                }
            }
        }
    }
}

fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

dependencies {
    api(files(androidStubs))
    api(libs.coroutines.core)
    api(libs.serialization.json)
    api(libs.okhttp.core)
    api(libs.rxjava)
    api(libs.jsoup)
    implementation(libs.kotlin.reflect)
    implementation(libs.slf4j.api)
    implementation(libs.xmlpull)
    implementation(libs.settings.core)
    implementation(libs.settings.serialization)
    implementation(libs.icu4j)
    implementation(libs.twelvemonkeys.imageio.jpeg)
    implementation(libs.twelvemonkeys.imageio.webp)
    implementation(libs.imageio.webp)
    implementation(libs.sqlite.jdbc)
    implementation(libs.rhino)
    // JCEF's Java part, in the runtime; its native part (Chromium) is
    // downloaded when an extension first opens a web view (the host's
    // CefRuntime).
    implementation(libs.jcef)
    implementation(libs.apk.parser)
    implementation(libs.dex2jar.translator)
    implementation(libs.dex2jar.tools)
    compileOnly(libs.apksig)
    compileOnly(libs.android.annotations)
}
