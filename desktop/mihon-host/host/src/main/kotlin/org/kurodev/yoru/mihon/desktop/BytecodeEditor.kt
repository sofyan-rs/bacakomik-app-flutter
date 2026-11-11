// From Suwayomi-Server (MPL-2.0): points converted extensions at
// AndroidCompat's Android-behaving SimpleDateFormat. Changed for SCANCORE:
// package, logging, interface calls dex2jar writes as class calls, and the
// class's name in stack map frames.
package org.kurodev.yoru.mihon.desktop

/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import org.objectweb.asm.ClassReader
import org.objectweb.asm.ClassVisitor
import org.objectweb.asm.ClassWriter
import org.objectweb.asm.FieldVisitor
import org.objectweb.asm.Handle
import org.objectweb.asm.MethodVisitor
import org.objectweb.asm.Opcodes
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import kotlin.streams.asSequence

object BytecodeEditor {
    // SCANCORE: kotlin-logging's lambdas, quiet unless something fails.
    private val logger =
        object {
            fun trace(message: () -> Any?) = Unit

            fun error(
                e: Throwable,
                message: () -> Any?,
            ) = System.err.println("${message()}: $e")
        }

    /**
     * Replace some java class references inside a jar with new ones that behave like Androids
     *
     * @param jarFile The JarFile to replace class references in
     */
    fun fixAndroidClasses(
        jarFile: Path,
        runtime: ClassLoader? = null,
    ) {
        // SCANCORE: a plugin runtime's interfaces (CloudStream's, Echo's)
        // count too; the host's class loader does not see them.
        pluginClasses.set(runtime)
        try {
            fix(jarFile)
        } finally {
            pluginClasses.remove()
        }
    }

    private fun fix(jarFile: Path) {
        FileSystems.newFileSystem(jarFile, null as ClassLoader?)?.use {
            // SCANCORE: dex2jar writes calls to interface methods (a default
            // method called through super, as getSourcePreferences() is) as
            // plain method references, which the JVM refuses. The interfaces
            // are the jar's own and the host's.
            jarInterfaces.clear()
            Files
                .walk(it.getPath("/"))
                .asSequence()
                .filter { p -> p.toString().endsWith(".class") }
                .forEach { p ->
                    runCatching {
                        val reader = ClassReader(Files.readAllBytes(p))
                        if (reader.access and Opcodes.ACC_INTERFACE != 0) jarInterfaces.add(reader.className)
                    }
                }
            Files
                .walk(it.getPath("/"))
                .asSequence()
                .filterNotNull()
                .filterNot(Files::isDirectory)
                .mapNotNull(::getClassBytes)
                .map(::transform)
                .forEach(::write)
        }
    }

    /**
     * Get class bytes from a [Path]
     *
     * @param path The path entry to get the class bytes from
     *
     * @return [Pair] of the [Path] plus the class [ByteArray], or null if it's not a valid class
     */
    private fun getClassBytes(path: Path): Pair<Path, ByteArray>? {
        return try {
            if (path.toString().endsWith(".class")) {
                val bytes = Files.readAllBytes(path)
                if (bytes.size < 4) {
                    // Invalid class size
                    return null
                }
                val cafebabe =
                    String.format(
                        "%02X%02X%02X%02X",
                        bytes[0],
                        bytes[1],
                        bytes[2],
                        bytes[3],
                    )
                if (cafebabe.lowercase() != "cafebabe") {
                    // Corrupted class
                    return null
                }

                path to bytes
            } else {
                null
            }
        } catch (e: Exception) {
            logger.error(e) { "Error loading class from Path: $path" }
            null
        }
    }

    /**
     * The path where replacement classes will reside
     */
    private const val REPLACEMENT_PATH = "xyz/nulldev/androidcompat/replace"

    private val jarInterfaces = java.util.Collections.synchronizedSet(HashSet<String>())
    private val hostInterfaces = java.util.concurrent.ConcurrentHashMap<String, Boolean>()

    private val pluginClasses = ThreadLocal<ClassLoader?>()

    private fun isInterface(owner: String?): Boolean {
        if (owner == null || owner.startsWith("[")) return false
        if (owner in jarInterfaces) return true
        pluginClasses.get()?.let { loader ->
            runCatching { Class.forName(owner.replace('/', '.'), false, loader).isInterface }.getOrNull()?.let { return it }
        }
        return hostInterfaces.getOrPut(owner) {
            runCatching { Class.forName(owner.replace('/', '.'), false, BytecodeEditor::class.java.classLoader).isInterface }.getOrDefault(false)
        }
    }

    /**
     * List of classes that will be replaced
     */
    private val classesToReplace =
        listOf(
            "java/text/SimpleDateFormat",
        )

    /**
     * Replace direct references to the class, used on places
     * that don't have any other text then the class
     *
     * @return [String] of class or null if [String] was null
     */
    private fun String?.replaceDirectly() =
        when (this) {
            null -> null
            in classesToReplace -> "$REPLACEMENT_PATH/$this"
            else -> this
        }

    /**
     * Replace references to the class, used in places that have
     * other text around the class references
     *
     * @return [String] with class references replaced, or null if [String] was null
     */
    private fun String?.replaceIndirectly(): String? {
        if (this == null) return null
        var classReference: String = this
        classesToReplace.forEach {
            classReference = classReference.replace(it, "$REPLACEMENT_PATH/$it")
        }
        return classReference
    }

    /**
     * Replace all references to certain classes inside the class file
     * with ones that behave more like Androids
     *
     * @param pair Class bytecode to load into ASM for ease of modification
     *
     * @return [ByteArray] with modified bytecode
     */
    private fun transform(pair: Pair<Path, ByteArray>): Pair<Path, ByteArray> {
        // Read the class and prepare to modify it
        val cr = ClassReader(pair.second)
        val cw = ClassWriter(cr, 0)
        // Modify the class
        cr.accept(
            object : ClassVisitor(Opcodes.ASM5, cw) {
                // Modify field descriptor, for example
                // class MangaYes {
                //     val format = SimpleDateFormat("YYYY-MM-dd")
                // }
                override fun visitField(
                    access: Int,
                    name: String?,
                    desc: String?,
                    signature: String?,
                    cst: Any?,
                ): FieldVisitor? {
                    logger.trace { "CLass Field" to "${desc.replaceIndirectly()}: ${cst?.let { it::class.java.simpleName }}: $cst" }
                    return super.visitField(access, name, desc.replaceIndirectly(), signature, cst)
                }

                override fun visit(
                    version: Int,
                    access: Int,
                    name: String?,
                    signature: String?,
                    superName: String?,
                    interfaces: Array<out String>?,
                ) {
                    logger.trace { "Visiting $name: $signature: $superName" }
                    super.visit(version, access, name, signature, superName, interfaces)
                }

                // Modify method bytecode, for example
                // class MangaYes {
                //     fun fetchChapterList() {
                //         SimpleDateFormat("YYYY-MM-dd")
                //     }
                // }
                override fun visitMethod(
                    access: Int,
                    name: String,
                    desc: String,
                    signature: String?,
                    exceptions: Array<String?>?,
                ): MethodVisitor {
                    logger.trace { "Processing method $name: ${desc.replaceIndirectly()}: $signature" }
                    val mv: MethodVisitor? =
                        super.visitMethod(
                            access,
                            name,
                            desc.replaceIndirectly(),
                            signature,
                            exceptions,
                        )
                    return object : MethodVisitor(Opcodes.ASM5, mv) {
                        override fun visitLdcInsn(cst: Any?) {
                            logger.trace { "Ldc" to "${cst?.let { "${it::class.java.simpleName}: $it" }}" }
                            super.visitLdcInsn(cst)
                        }

                        // Replace method type, for example
                        // val format = DateFormat()
                        // fun fetchChapterList() {
                        //     if (format is SimpleDateFormat)
                        // }
                        override fun visitTypeInsn(
                            opcode: Int,
                            type: String?,
                        ) {
                            logger.trace {
                                "Type" to "$opcode: ${type.replaceDirectly()}"
                            }
                            super.visitTypeInsn(
                                opcode,
                                type.replaceDirectly(),
                            )
                        }

                        // Replace method field, for example
                        // fun fetchChapterList() {
                        //     val format = SimpleDateFormat("YYYY-MM-dd")
                        // }
                        override fun visitMethodInsn(
                            opcode: Int,
                            owner: String?,
                            name: String?,
                            desc: String?,
                            itf: Boolean,
                        ) {
                            logger.trace {
                                "Method" to "$opcode: ${owner.replaceDirectly()}: $name: ${desc.replaceIndirectly()}"
                            }
                            val onInterface = itf || isInterface(owner)
                            super.visitMethodInsn(
                                if (onInterface && opcode == Opcodes.INVOKEVIRTUAL) Opcodes.INVOKEINTERFACE else opcode,
                                owner.replaceDirectly(),
                                name,
                                desc.replaceIndirectly(),
                                onInterface,
                            )
                        }

                        // Replace class field call from method, for example
                        // val format = SimpleDateFormat("YYYY-MM-dd")
                        // fun fetchChapterList() {
                        //     format.format(Date())
                        // }
                        override fun visitFieldInsn(
                            opcode: Int,
                            owner: String?,
                            name: String?,
                            desc: String?,
                        ) {
                            logger.trace { "Field" to "$opcode: $owner: $name: ${desc.replaceIndirectly()}" }
                            super.visitFieldInsn(opcode, owner, name, desc.replaceIndirectly())
                        }

                        // SCANCORE: the frames dex2jar computed name the class
                        // as well; left alone, a SimpleDateFormat kept in a
                        // local across a branch fails verification.
                        override fun visitFrame(
                            type: Int,
                            numLocal: Int,
                            local: Array<out Any?>?,
                            numStack: Int,
                            stack: Array<out Any?>?,
                        ) {
                            fun replaced(items: Array<out Any?>?) = items?.map { if (it is String) it.replaceDirectly() else it }?.toTypedArray()
                            super.visitFrame(type, numLocal, replaced(local), numStack, replaced(stack))
                        }

                        override fun visitInvokeDynamicInsn(
                            name: String?,
                            desc: String?,
                            bsm: Handle?,
                            vararg bsmArgs: Any?,
                        ) {
                            logger.trace { "InvokeDynamic" to "$name: $desc" }
                            super.visitInvokeDynamicInsn(name, desc, bsm, *bsmArgs)
                        }
                    }
                }
            },
            0,
        )
        return pair.first to cw.toByteArray()
    }

    private fun write(pair: Pair<Path, ByteArray>) {
        Files.write(
            pair.first,
            pair.second,
            StandardOpenOption.CREATE,
            StandardOpenOption.TRUNCATE_EXISTING,
        )
    }
}
