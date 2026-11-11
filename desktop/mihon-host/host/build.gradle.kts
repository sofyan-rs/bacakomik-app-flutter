import java.security.MessageDigest
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

// The helper process: android/mihon's Kotlin (the Mihon API, the extension
// host, Yoru's contract) compiled for the JVM over AndroidCompat, with
// SCANCORE's dex2jar loader. installDist puts it with its libraries in
// build/install/yoru-mihon-host.
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
    application
}

// The same files Android builds: one behaviour on every system. Left out:
// what only Android has (the package manager loader, the WebView browser
// check, settings over androidx) and the local image server for Android's
// background downloader.
val shared = rootProject.layout.projectDirectory.dir("../../android/mihon/src/main/kotlin")

sourceSets {
    main {
        kotlin {
            srcDir(shared)
            exclude("org/kurodev/yoru/mihon/host/android/**")
            exclude("org/kurodev/yoru/mihon/MihonProxy.kt")
            exclude("org/kurodev/yoru/mihon/MihonHostAndroid.kt")
        }
    }
}

// StdoutGuard calls C (Java 17's incubating foreign API) to keep native
// code's output (Chromium's) off the protocol. The runtime has these options
// built in (runtimeImage), so the app's plain `java -cp … MainKt` gets them.
val nativeAccess = listOf("--add-modules=jdk.incubator.foreign", "--enable-native-access=ALL-UNNAMED")

tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.addAll(listOf("--add-modules", "jdk.incubator.foreign"))
}

application {
    applicationName = "yoru-mihon-host"
    mainClass.set("org.kurodev.yoru.mihon.desktop.MainKt")
    applicationDefaultJvmArgs = listOf("-Xss2m", "-XX:+UseSerialGC", "-XX:TieredStopAtLevel=1", "-Dfile.encoding=UTF-8") + nativeAccess
}

dependencies {
    implementation(project(":compat"))
    implementation(libs.coroutines.core)
    implementation(libs.serialization.json)
    implementation(libs.serialization.json.okio)
    implementation(libs.serialization.protobuf)
    implementation(libs.okhttp.core)
    implementation(libs.okhttp.brotli)
    // Keiyoushi's extensions decompress Zstd themselves (Mihon ships it too).
    implementation(libs.okhttp.zstd)
    implementation(libs.okhttp.dnsoverhttps)
    implementation(libs.okio)
    implementation(libs.jsoup)
    implementation(libs.rxjava)
    implementation(libs.injekt)
    implementation(libs.dex2jar.translator)
    implementation(libs.dex2jar.tools)
    implementation(libs.apk.parser)
    implementation(libs.apksig)
    // Chromium for extensions' web views (CefRuntime): the Java part here,
    // the native part downloaded on first use.
    implementation(libs.jcef)
    runtimeOnly(libs.slf4j.nop)
}

// ---------------------------------------------------------------------------
// The runtime the app downloads on first use (adapted from SCANCORE's
// desktop/build.gradle.kts): a Java trimmed with jlink to the modules
// extensions use, and the host's jars (sqlite's native library for this
// system only). `./gradlew :host:runtimeZip` builds it for the system Gradle
// runs on, with that Java. Start it with
//   <runtime>/bin/java -cp "<runtime>/lib/host/*" org.kurodev.yoru.mihon.desktop.MainKt --root <dir>
val runtimeModules =
    listOf(
        "java.base", "java.desktop", "java.logging", "java.management", "java.prefs", "java.scripting",
        "java.sql", "java.xml", "jdk.dynalink", "jdk.unsupported",
        // Not visible to jdeps, needed by extensions: TLS with EC keys,
        // non-UTF-8 sites, dates in every language, and the jar edits.
        "jdk.crypto.ec", "jdk.charsets", "jdk.localedata", "jdk.zipfs",
        // StdoutGuard (see nativeAccess).
        "jdk.incubator.foreign",
    )

// Raised when the protocol or the runtime's layout changes.
val hostVersion = "1"

fun platformName(): String {
    val os = System.getProperty("os.name").lowercase()
    val arch = System.getProperty("os.arch").lowercase().let { if (it == "amd64" || it == "x86_64") "x64" else if (it == "aarch64") "arm64" else it }
    return when {
        os.startsWith("windows") -> "windows-$arch"
        os.startsWith("mac") -> "macos-$arch"
        else -> "linux-$arch"
    }
}

// sqlite-jdbc's folder for this system's native library.
fun sqliteNative(): String {
    val os = System.getProperty("os.name").lowercase()
    val arch = System.getProperty("os.arch").lowercase().let { if (it == "amd64") "x86_64" else it }
    return "org/sqlite/native/" +
        when {
            os.startsWith("windows") -> "Windows/${if (arch == "x86_64") "x86_64" else arch}/"
            os.startsWith("mac") -> "Mac/${if (arch == "aarch64") "aarch64" else "x86_64"}/"
            else -> "Linux/${if (arch == "aarch64") "aarch64" else "x86_64"}/"
        }
}

val runtimeImage by tasks.registering {
    dependsOn("installDist")
    val out = layout.buildDirectory.dir("runtime/yoru-mihon-runtime")
    inputs.dir(layout.buildDirectory.dir("install/yoru-mihon-host/lib"))
    inputs.property("modules", runtimeModules)
    inputs.property("options", nativeAccess)
    inputs.property("hostVersion", hostVersion)
    outputs.dir(out)
    doLast {
        val dir = out.get().asFile
        dir.deleteRecursively()
        val javaHome = File(System.getProperty("java.home"))
        val jlink = File(javaHome, "bin/jlink" + if (System.getProperty("os.name").startsWith("Windows")) ".exe" else "")
        val major = JavaVersion.current().majorVersion.toInt()
        val process =
            ProcessBuilder(
                jlink.path, "--add-modules", runtimeModules.joinToString(","), "--strip-debug", "--no-header-files",
                "--no-man-pages", "--compress", if (major >= 21) "zip-6" else "2",
                // (A leading space, or jlink reads the value as one of its options.)
                "--add-options= " + nativeAccess.joinToString(" "), "--output", dir.path,
            ).redirectErrorStream(true).start()
        val log = process.inputStream.bufferedReader().readText()
        check(process.waitFor() == 0) { "jlink failed:\n$log" }
        val lib = File(dir, "lib/host").apply { mkdirs() }
        val keep = sqliteNative()
        for (jar in layout.buildDirectory.dir("install/yoru-mihon-host/lib").get().asFile.listFiles()!!) {
            val target = File(lib, jar.name)
            if (!jar.name.startsWith("sqlite-jdbc")) {
                jar.copyTo(target)
                continue
            }
            // Only this system's native library (the jar has all of them).
            ZipFile(jar).use { zip ->
                ZipOutputStream(target.outputStream().buffered()).use { zipOut ->
                    for (entry in zip.entries()) {
                        if (entry.name.startsWith("org/sqlite/native/") && !entry.isDirectory && !entry.name.startsWith(keep)) continue
                        zipOut.putNextEntry(ZipEntry(entry.name))
                        zip.getInputStream(entry).use { it.copyTo(zipOut) }
                        zipOut.closeEntry()
                    }
                }
            }
        }
        File(dir, "yoru-mihon-runtime.json").writeText("""{"host": "$hostVersion", "java": "$major", "platform": "${platformName()}"}""" + "\n")
    }
}

val runtimeZip by tasks.registering(Zip::class) {
    dependsOn(runtimeImage)
    archiveFileName.set("yoru-mihon-runtime-$hostVersion-${platformName()}.zip")
    destinationDirectory.set(layout.buildDirectory.dir("distributions"))
    from(layout.buildDirectory.dir("runtime"))
    // bin/java and friends stay executable.
    eachFile { if (path.contains("/bin/") || path.endsWith("/lib/jspawnhelper")) permissions { unix("rwxr-xr-x") } }
    doLast {
        val zip = archiveFile.get().asFile
        val sum = MessageDigest.getInstance("SHA-256").digest(zip.readBytes()).joinToString("") { "%02x".format(it) }
        File(zip.path + ".sha256").writeText("$sum  ${zip.name}\n")
    }
}
