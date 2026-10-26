// From SCANCORE's AndroidLoader.kt (MIT). BACAKOMIK: Aniyomi (anime) left out.
package org.kurodev.bacakomik.mihon.host.android

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import org.kurodev.bacakomik.mihon.host.ExtensionLoader
import org.kurodev.bacakomik.mihon.host.HostError
import org.kurodev.bacakomik.mihon.host.LoadedExtension
import dalvik.system.DelegateLastClassLoader
import eu.kanade.tachiyomi.source.Source
import eu.kanade.tachiyomi.source.SourceFactory
import java.io.File
import java.security.MessageDigest

// Loads Mihon extensions inside the app, as Mihon loads its private ones:
// the package manager reads the APK's manifest and checks its signature,
// and the classes load from the read-only file the app stored, children
// first. No conversion.
class AndroidLoader(
    private val context: Context,
) : ExtensionLoader {
    override val libs = listOf("1.4", "1.5", "1.6")

    override fun load(
        pkg: String,
        path: String,
        signer: String?,
    ): LoadedExtension {
        val info = inspect(path)
        val signers = signers(info)
        if (signer != null && signer.lowercase() !in signers) throw HostError("The extension is signed with a key BacaKomik did not trust.", 403)
        val app = info.applicationInfo!!
        val meta = app.metaData ?: throw HostError("The extension does not say which sources it has.", 422)
        val lib = lib(info)
        if (lib.toDoubleOrNull() !in libs.map { it.toDouble() }) {
            throw HostError("This extension uses lib $lib, which this BacaKomik does not run.", 426)
        }
        val classes =
            meta
                .getString("tachiyomi.extension.class")
                ?.split(";")
                ?.map { it.trim() }
                ?.filter { it.isNotEmpty() }
                ?: throw HostError("The extension does not say which sources it has.", 422)
        val loader = DelegateLastClassLoader(path, app.nativeLibraryDir, context.classLoader)
        val instances =
            classes.map { name ->
                val className = if (name.startsWith(".")) info.packageName + name else name
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

    // The APK's manifest and signer, read without installing it.
    fun inspect(path: String): PackageInfo {
        val apk = File(path)
        if (!apk.isFile) throw HostError("The extension's file is missing. Install it again.", 404)
        // Android 14 runs code only from files nobody can write to.
        if (apk.canWrite()) apk.setReadOnly()
        val flags = PackageManager.GET_META_DATA or PackageManager.GET_SIGNING_CERTIFICATES
        val info: PackageInfo =
            context.packageManager.getPackageArchiveInfo(apk.path, flags)
                ?: throw HostError("The extension's file could not be read.", 422)
        val app = info.applicationInfo ?: throw HostError("The extension's file could not be read.", 422)
        app.sourceDir = apk.path
        app.publicSourceDir = apk.path
        return info
    }

    // SHA-256 of each signing certificate, lowercase hex.
    fun signers(info: PackageInfo): List<String> {
        val signing = info.signingInfo ?: throw HostError("The extension is not signed.", 403)
        val certificates = if (signing.hasMultipleSigners()) signing.apkContentsSigners else signing.signingCertificateHistory
        return certificates.map { sha256(it.toByteArray()) }.ifEmpty { throw HostError("The extension is not signed.", 403) }
    }

    fun lib(info: PackageInfo): String =
        info.applicationInfo
            ?.metaData
            ?.getFloat("tachiyomix.extensionLib")
            ?.takeIf { it != 0f }
            ?.toString()
            ?: info.versionName.orEmpty().substringBeforeLast('.')

    private fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
}
