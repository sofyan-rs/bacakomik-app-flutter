// From SCANCORE's desktop/InlinedConstructors.kt (MIT).
package org.kurodev.yoru.mihon.desktop

import com.googlecode.d2j.DexConstants
import com.googlecode.d2j.Method
import com.googlecode.d2j.reader.BaseDexFileReader
import com.googlecode.d2j.reader.Op
import com.googlecode.d2j.visitors.DexClassVisitor
import com.googlecode.d2j.visitors.DexCodeVisitor
import com.googlecode.d2j.visitors.DexFileVisitor
import com.googlecode.d2j.visitors.DexMethodVisitor

// R8 (Keiyoushi's builds since August 2026) drops constructors that only
// call their superclass's and has `new T` call the superclass's constructor
// itself: new-instance Ld0; invoke-direct Ljava/lang/Enum;-><init>. Android
// runs that; Java's verifier does not, and dex2jar folds the pair into
// `new Enum`, losing T. So before dex2jar reads the dex, such calls go back
// to T.<init>, and T (with any class between it and the superclass called)
// gets the constructor R8 removed: one that calls its superclass's.
// Constructors get the same treatment: R8 also has `T.<init>` call a
// grandparent's constructor on `this` (Komga's `a extends d` calls
// Object.<init>), so such calls go to T's superclass instead.
object InlinedConstructors {
    fun fix(reader: BaseDexFileReader): BaseDexFileReader {
        val supers = HashMap<String, String>()
        val constructors = HashMap<String, MutableSet<String>>()
        val calls = HashSet<Pair<String, Method>>()
        val selfCalls = HashSet<Pair<String, Method>>()
        reader.accept(
            object : DexFileVisitor() {
                override fun visit(
                    access: Int,
                    className: String,
                    superClass: String?,
                    interfaces: Array<out String>?,
                ): DexClassVisitor {
                    superClass?.let { supers[className] = it }
                    return object : DexClassVisitor() {
                        override fun visitMethod(
                            access: Int,
                            method: Method,
                        ): DexMethodVisitor {
                            if (method.name == "<init>") constructors.getOrPut(className) { HashSet() } += method.desc
                            return object : DexMethodVisitor() {
                                override fun visitCode(): DexCodeVisitor =
                                    Calls(null, Self.of(className, method)) { type, init, self ->
                                        if (self) selfCalls += type to init else calls += type to init
                                        null
                                    }
                            }
                        }
                    }
                }
            },
        )

        // For each class, the constructors to add: (parameter types, the superclass that gets the call).
        val added = HashMap<String, MutableMap<String, Pair<Array<String>, String>>>()
        val redirected = HashSet<Pair<String, String>>() // (type, desc)
        val selfRedirected = HashSet<Pair<String, String>>() // (class whose constructor calls, desc)

        // Gives the classes from `from` up to (not including) init.owner the
        // constructor init's caller expects; false if init.owner is not above.
        fun bridge(
            from: String,
            init: Method,
        ): Boolean {
            if (init.parameterTypes.any { it == "J" || it == "D" }) return false
            val chain = mutableListOf<String>()
            var at: String? = from
            while (at != null && at != init.owner && at in supers) {
                chain += at
                at = supers[at]
            }
            if (at != init.owner || chain.isEmpty()) return false
            for (c in chain) {
                if (init.desc in constructors[c].orEmpty()) continue
                added.getOrPut(c) { HashMap() }[init.desc] = init.parameterTypes to supers.getValue(c)
            }
            return true
        }
        for ((type, init) in calls) if (bridge(type, init)) redirected += type to init.desc
        for ((type, init) in selfCalls) {
            val parent = supers[type] ?: continue
            if (parent != init.owner && bridge(parent, init)) selfRedirected += type to init.desc
        }
        if (redirected.isEmpty() && selfRedirected.isEmpty()) return reader

        return object : BaseDexFileReader by reader {
            override fun accept(visitor: DexFileVisitor) = reader.accept(Rewriter(visitor, added, redirected, selfRedirected, supers))

            override fun accept(
                visitor: DexFileVisitor,
                config: Int,
            ) = reader.accept(Rewriter(visitor, added, redirected, selfRedirected, supers), config)

            override fun accept(
                visitor: DexFileVisitor,
                classIdx: Int,
                config: Int,
            ) = reader.accept(Rewriter(visitor, added, redirected, selfRedirected, supers), classIdx, config)
        }
    }

    // A constructor's own class and where `this` arrives (p0: after the
    // other registers, before the parameters).
    private class Self(
        val type: String,
        val parameterWords: Int,
    ) {
        companion object {
            fun of(
                className: String,
                method: Method,
            ) = if (method.name == "<init>") Self(className, method.parameterTypes.sumOf { if (it == "J" || it == "D") 2 else 1 }) else null
        }
    }

    // Reports, or rewrites, `new T` whose constructor call names another
    // class, and (with self) a constructor's call on `this` that skips its
    // superclass.
    private class Calls(
        visitor: DexCodeVisitor?,
        private val self: Self?,
        private val found: ((type: String, init: Method, self: Boolean) -> Method?),
    ) : DexCodeVisitor(visitor) {
        // Registers holding an object not yet constructed, and its class.
        private val fresh = HashMap<Int, String>()
        private var thisRegister = -1

        override fun visitRegister(total: Int) {
            if (self != null) thisRegister = total - self.parameterWords - 1
            super.visitRegister(total)
        }

        override fun visitTypeStmt(
            op: Op,
            a: Int,
            b: Int,
            type: String,
        ) {
            if (op == Op.NEW_INSTANCE) fresh[a] = type else fresh.remove(a)
            super.visitTypeStmt(op, a, b, type)
        }

        override fun visitMethodStmt(
            op: Op,
            args: IntArray,
            method: Method,
        ) {
            if ((op == Op.INVOKE_DIRECT || op == Op.INVOKE_DIRECT_RANGE) && method.name == "<init>" && args.isNotEmpty()) {
                val type = fresh.remove(args[0])
                if (type != null && type != method.owner) {
                    super.visitMethodStmt(op, args, found(type, method, false) ?: method)
                    return
                }
                if (type == null && self != null && args[0] == thisRegister && method.owner != self.type) {
                    thisRegister = -1
                    super.visitMethodStmt(op, args, found(self.type, method, true) ?: method)
                    return
                }
            }
            super.visitMethodStmt(op, args, method)
        }
    }

    private class Rewriter(
        visitor: DexFileVisitor,
        private val added: Map<String, Map<String, Pair<Array<String>, String>>>,
        private val redirected: Set<Pair<String, String>>,
        private val selfRedirected: Set<Pair<String, String>>,
        private val supers: Map<String, String>,
    ) : DexFileVisitor(visitor) {
        override fun visit(
            access: Int,
            className: String,
            superClass: String?,
            interfaces: Array<out String>?,
        ): DexClassVisitor? {
            val inner = super.visit(access, className, superClass, interfaces) ?: return null
            return object : DexClassVisitor(inner) {
                override fun visitMethod(
                    access: Int,
                    method: Method,
                ): DexMethodVisitor? {
                    val mv = super.visitMethod(access, method) ?: return null
                    return object : DexMethodVisitor(mv) {
                        override fun visitCode(): DexCodeVisitor? {
                            val code = super.visitCode() ?: return null
                            return Calls(code, Self.of(className, method)) { type, init, self ->
                                when {
                                    self && type to init.desc in selfRedirected -> Method(supers.getValue(type), "<init>", init.parameterTypes, "V")
                                    !self && type to init.desc in redirected -> Method(type, "<init>", init.parameterTypes, "V")
                                    else -> null
                                }
                            }
                        }
                    }
                }

                override fun visitEnd() {
                    for ((_, entry) in added[className].orEmpty()) {
                        val (params, parent) = entry
                        val mv =
                            super.visitMethod(
                                DexConstants.ACC_PUBLIC or DexConstants.ACC_CONSTRUCTOR or DexConstants.ACC_SYNTHETIC,
                                Method(className, "<init>", params, "V"),
                            ) ?: continue
                        val code = mv.visitCode()
                        if (code != null) {
                            // this in v0, then the parameters (none of them wide).
                            code.visitRegister(params.size + 1)
                            code.visitMethodStmt(Op.INVOKE_DIRECT, IntArray(params.size + 1) { it }, Method(parent, "<init>", params, "V"))
                            code.visitStmt0R(Op.RETURN_VOID)
                            code.visitEnd()
                        }
                        mv.visitEnd()
                    }
                    super.visitEnd()
                }
            }
        }
    }
}
