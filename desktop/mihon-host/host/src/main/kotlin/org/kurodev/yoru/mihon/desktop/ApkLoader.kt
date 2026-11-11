// From SCANCORE's desktop/ApkLoader.kt (MIT). YORU: Aniyomi, CloudStream and
// Echo left out; inspect() added, which reads an APK's manifest and signers
// for MihonHost (what Android's package manager does there).
package org.kurodev.yoru.mihon.desktop

import com.android.apksig.ApkVerifier
import com.googlecode.d2j.dex.Dex2jar
import com.googlecode.d2j.reader.MultiDexFileReader
import com.googlecode.dex2jar.tools.BaksmaliBaseDexExceptionHandler
import eu.kanade.tachiyomi.source.Source
import eu.kanade.tachiyomi.source.SourceFactory
import net.dongliu.apk.parser.ApkFile
import org.kurodev.yoru.mihon.ApkInfo
import org.kurodev.yoru.mihon.host.ExtensionLoader
import org.kurodev.yoru.mihon.host.HostError
import org.kurodev.yoru.mihon.host.LoadedExtension
import org.w3c.dom.Element
import java.io.File
import java.net.URLClassLoader
import java.security.MessageDigest
import javax.xml.parsers.DocumentBuilderFactory

// Runs Mihon extension APKs on the JVM: checks the signature (apksig) is the
// one the app trusted, converts the Dalvik bytecode to JVM bytecode
// (dex2jar, as Suwayomi does), points date parsing at Android's behaviour,
// and loads the sources in their own class loader. The check and the
// conversion happen once per APK version; later starts load the cached jar.
class ApkLoader(
    private val cacheDir: File,
) : ExtensionLoader {
    override val libs = listOf("1.4", "1.5", "1.6")

    companion object {
        // Raised whenever conversion changes (BytecodeEditor included).
        const val CONVERTER = 4
    }

    override fun load(
        pkg: String,
        path: String,
        signer: String?,
    ): LoadedExtension {
        val apk = File(path)
        if (!apk.isFile) throw HostError("The extension's file is missing. Install it again.", 404)
        val bytes = apk.readBytes()
        // A new converter makes older conversions stale.
        val stamp = "${sha256(bytes).take(16)}-c$CONVERTER"
        val jar = File(cacheDir, "$pkg-$stamp.jar")
        val manifest = File(cacheDir, "$pkg-$stamp.meta")
        if (!jar.isFile || !manifest.isFile) {
            // Keiyoushi also publishes each extension as a signed Java jar:
            // their builds are minified since lib 1.6, and dex2jar turns the
            // minified code into classes Java refuses ("Bad type on operand
            // stack"). Suwayomi installs these jars too.
            if (path.endsWith(".jar")) {
                val meta = verifyJar(apk, signer)
                copyJar(apk, jar)
                manifest.writeText(meta.entries.joinToString("\n") { "${it.key}=${it.value}" })
            } else {
                verify(apk, signer)
                convert(bytes, jar)
                manifest.writeText(metadata(apk).entries.joinToString("\n") { "${it.key}=${it.value}" })
            }
            // Older conversions of this extension are no longer needed.
            cacheDir.listFiles { f -> f.name.startsWith("$pkg-") && !f.name.startsWith("$pkg-$stamp") }?.forEach { it.delete() }
        }
        val meta = manifest.readLines().associate { it.substringBefore('=') to typedValue(it.substringAfter('=')) }
        val lib = lib(meta)
        if (lib.toDoubleOrNull() !in libs.map { it.toDouble() }) {
            throw HostError("This extension uses lib $lib, which this Yoru does not run.", 426)
        }
        val classes =
            meta["tachiyomi.extension.class"]
                ?.split(";")
                ?.map { it.trim() }
                ?.filter { it.isNotEmpty() }
                ?: throw HostError("The extension does not say which sources it has.", 422)
        val loader = ChildFirstClassLoader(arrayOf(jar.toURI().toURL()), javaClass.classLoader)
        val instances =
            classes.map { name ->
                val className = if (name.startsWith(".")) (meta["package"]?.takeIf { it.isNotEmpty() } ?: pkg) + name else name
                Class.forName(className, false, loader).getDeclaredConstructor().newInstance()
            }
        return LoadedExtension(
            sources =
                instances.flatMap {
                    when (it) {
                        is Source -> listOf(it)
                        is SourceFactory -> it.createSources()
                        else -> throw HostError("The extension's class ${it.javaClass.name} is not a source.", 422)
                    }
                },
        )
    }

    // YORU: the APK's manifest and signers, read without running its code
    // (MihonHost's inspect). Unsigned or tampered files are refused here, as
    // Android's package manager refuses them.
    fun inspect(path: String): ApkInfo {
        val apk = File(path)
        if (!apk.isFile) throw HostError("The extension's file is missing. Install it again.", 404)
        if (path.endsWith(".jar")) {
            val (meta, signers) = readJar(apk, null)
            return ApkInfo(
                pkg = meta["package"].orEmpty(),
                name = meta["label"],
                versionName = meta["versionName"],
                versionCode = meta["versionCode"]?.toLongOrNull() ?: 0L,
                lib = lib(meta),
                nsfw = meta["tachiyomi.extension.nsfw"]?.toIntOrNull() == 1,
                signers = signers,
            )
        }
        val signers = signers(apk)
        val meta = metadata(apk).mapValues { typedValue(it.value) }
        val parsed =
            try {
                ApkFile(apk).use { it.apkMeta }
            } catch (e: Exception) {
                throw HostError("The extension's file could not be read.", 422)
            }
        return ApkInfo(
            pkg = parsed.packageName,
            name = parsed.label,
            versionName = parsed.versionName,
            versionCode = parsed.versionCode ?: 0L,
            lib = lib(meta),
            nsfw = meta["tachiyomi.extension.nsfw"]?.toIntOrNull() == 1,
            signers = signers,
        )
    }

    // The extension lib from the manifest, else from the version name
    // (1.4.12 is lib 1.4), as Mihon reads it.
    private fun lib(meta: Map<String, String>): String =
        meta["tachiyomix.extensionLib"]?.takeIf { it.isNotEmpty() && it.toDoubleOrNull() != 0.0 }
            ?: meta["versionName"].orEmpty().substringBeforeLast('.')

    // SHA-256 of each signing certificate, lowercase hex; refuses a file whose
    // signature does not check out.
    private fun signers(apk: File): List<String> {
        val result =
            try {
                ApkVerifier.Builder(apk).build().verify()
            } catch (e: Exception) {
                throw HostError("The extension's file could not be read.", 422)
            }
        if (!result.isVerified) {
            val reason = result.errors.firstOrNull()?.toString() ?: "unknown"
            throw HostError("The extension's signature does not check out ($reason).", 403)
        }
        return result.signerCertificates.map { sha256(it.encoded) }.ifEmpty { throw HostError("The extension is not signed.", 403) }
    }

    private fun verify(
        apk: File,
        signer: String?,
    ) {
        val signers = signers(apk)
        if (signer != null && signer.lowercase() !in signers) throw HostError("The extension is signed with a key Yoru did not trust.", 403)
    }

    // A jar extension: every file but the signature's own must be signed by
    // the trusted key (Java checks each entry's digest as it is read).
    // Returns the meta-data of its AndroidManifest.xml, which is plain XML.
    private fun verifyJar(
        file: File,
        signer: String?,
    ): Map<String, String> = readJar(file, signer).first

    // YORU: also returns the signers, for inspect.
    private fun readJar(
        file: File,
        signer: String?,
    ): Pair<Map<String, String>, List<String>> {
        var manifest: ByteArray? = null
        val seen = linkedSetOf<String>()
        try {
            java.util.jar.JarFile(file, true).use { jar ->
                var signed = 0
                for (entry in jar.entries()) {
                    if (entry.isDirectory) continue
                    val bytes = jar.getInputStream(entry).use { it.readBytes() }
                    val name = entry.name
                    if (name.startsWith("META-INF/") && name.count { it == '/' } == 1) continue
                    val signers = entry.codeSigners.orEmpty().map { sha256(it.signerCertPath.certificates.first().encoded) }
                    if (signers.isEmpty()) throw HostError("The extension has a file that is not signed ($name).", 403)
                    seen += signers
                    if (signer != null && signer.lowercase() !in signers) {
                        throw HostError("The extension is signed with a key Yoru did not trust.", 403)
                    }
                    if (name == "AndroidManifest.xml") manifest = bytes
                    signed++
                }
                if (signed == 0) throw HostError("The extension is not signed.", 403)
            }
        } catch (e: SecurityException) {
            throw HostError("The extension's signature does not check out (${e.message}).", 403)
        }
        val xml = manifest ?: throw HostError("The extension has no manifest.", 422)
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(xml.inputStream())
        val root = doc.documentElement
        val out =
            mutableMapOf(
                "versionName" to root.getAttribute("android:versionName"),
                "versionCode" to root.getAttribute("android:versionCode"),
                "package" to root.getAttribute("package"),
            )
        (doc.getElementsByTagName("application").item(0) as? Element)?.getAttribute("android:label")?.takeIf { it.isNotEmpty() }?.let { out["label"] = it }
        val nodes = doc.getElementsByTagName("meta-data")
        for (i in 0 until nodes.length) {
            val e = nodes.item(i) as? Element ?: continue
            out[e.getAttribute("android:name")] = e.getAttribute("android:value").replace('\n', ' ')
        }
        return out to seen.toList()
    }

    // The checked jar without its signature (the date fix below edits the
    // classes, which a signed jar would then refuse to load).
    private fun copyJar(
        source: File,
        jar: File,
    ) {
        cacheDir.mkdirs()
        val temp = File(jar.path + ".part")
        temp.delete()
        java.util.zip.ZipInputStream(source.inputStream().buffered()).use { input ->
            java.util.zip.ZipOutputStream(temp.outputStream().buffered()).use { output ->
                while (true) {
                    val entry = input.nextEntry ?: break
                    val name = entry.name
                    if (entry.isDirectory || name.startsWith("META-INF/") || name.contains("..")) continue
                    output.putNextEntry(java.util.zip.ZipEntry(name))
                    input.copyTo(output)
                    output.closeEntry()
                }
            }
        }
        BytecodeEditor.fixAndroidClasses(temp.toPath())
        if (!temp.renameTo(jar)) throw HostError("The extension could not be saved.", 500)
    }

    private fun convert(
        apk: ByteArray,
        jar: File,
    ) {
        cacheDir.mkdirs()
        val temp = File(jar.path + ".part")
        temp.delete()
        val handler = BaksmaliBaseDexExceptionHandler()
        Dex2jar
            .from(InlinedConstructors.fix(MultiDexFileReader.open(apk)))
            .withExceptionHandler(handler)
            .reUseReg(false)
            .topoLogicalSort()
            .skipDebug(true)
            .optimizeSynchronized(false)
            .printIR(false)
            .noCode(false)
            .skipExceptions(false)
            .dontSanitizeNames(true)
            .computeFrames(true)
            .to(temp.toPath())
        if (handler.hasException()) {
            temp.delete()
            throw HostError("The extension could not be converted to run on this computer.", 422)
        }
        BytecodeEditor.fixAndroidClasses(temp.toPath())
        copyResources(apk, temp)
        if (!temp.renameTo(jar)) throw HostError("The converted extension could not be saved.", 500)
    }

    // The APK's other files (assets/, res/ and any at its root) go into the
    // jar too: on Android an extension's class loader reads them from the
    // APK, so getResourceAsStream("assets/i18n/messages_en.properties")
    // works there. Keiyoushi's builds load their texts that way when the
    // source is made, and without them every one failed with a
    // NullPointerException. Not META-INF: its signatures are the APK's and
    // would make Java reject the converted classes.
    private fun copyResources(
        apk: ByteArray,
        jar: File,
    ) {
        java.nio.file.FileSystems.newFileSystem(jar.toPath()).use { zip ->
            java.util.zip.ZipInputStream(apk.inputStream()).use { input ->
                while (true) {
                    val entry = input.nextEntry ?: break
                    val name = entry.name
                    if (entry.isDirectory || name.startsWith("META-INF/") || name.endsWith(".dex") || name.contains("..")) continue
                    if (name == "AndroidManifest.xml" || name == "resources.arsc") continue
                    val target = zip.getPath(name)
                    if (java.nio.file.Files.exists(target)) continue
                    target.parent?.let { java.nio.file.Files.createDirectories(it) }
                    java.nio.file.Files.copy(input, target)
                }
            }
        }
    }

    // The APK parser writes typed values it does not know as {type:data}:
    // Keiyoushi's builds declare tachiyomix.extensionLib as a float (1.6 is
    // {4:1070386381}), which read as text made every one of them "lib
    // {4:…}". Android's binary XML types: 4 float, 16 and 17 int, 18 boolean.
    private fun typedValue(value: String): String {
        val match = Regex("""^\{(\d+):(-?\d+)\}$""").matchEntire(value) ?: return value
        val data = match.groupValues[2].toLong().toInt()
        return when (match.groupValues[1].toInt()) {
            4 -> java.lang.Float.intBitsToFloat(data).toString()
            16, 17 -> data.toString()
            18 -> (data != 0).toString()
            else -> value
        }
    }

    // The meta-data of the manifest's <application>, and the version name.
    private fun metadata(apk: File): Map<String, String> =
        try {
            ApkFile(apk).use { parsed ->
                val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(parsed.manifestXml.byteInputStream())
                val out = mutableMapOf("versionName" to (parsed.apkMeta.versionName ?: ""))
                val nodes = doc.getElementsByTagName("meta-data")
                for (i in 0 until nodes.length) {
                    val e = nodes.item(i) as? Element ?: continue
                    out[e.getAttribute("android:name")] = e.getAttribute("android:value").replace('\n', ' ')
                }
                out
            }
        } catch (e: HostError) {
            throw e
        } catch (e: Exception) {
            throw HostError("The extension's file could not be read.", 422)
        }

    private fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
}

// Classes come from the extension first, so its own copies of libraries win;
// the host's API classes are not in the extension, so they come from the
// host, which is what makes it run.
class ChildFirstClassLoader(
    urls: Array<java.net.URL>,
    parent: ClassLoader,
) : URLClassLoader(urls, parent) {
    override fun loadClass(
        name: String,
        resolve: Boolean,
    ): Class<*> =
        synchronized(getClassLoadingLock(name)) {
            val c =
                findLoadedClass(name)
                    ?: if (name.startsWith("java.") || name.startsWith("javax.") || name.startsWith("kotlin.")) {
                        super.loadClass(name, false)
                    } else {
                        try {
                            findClass(name)
                        } catch (_: ClassNotFoundException) {
                            super.loadClass(name, false)
                        }
                    }
            if (resolve) resolveClass(c)
            c
        }
}
