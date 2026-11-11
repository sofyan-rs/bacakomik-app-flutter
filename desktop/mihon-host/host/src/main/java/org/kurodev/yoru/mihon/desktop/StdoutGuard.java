package org.kurodev.yoru.mihon.desktop;

import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodType;
import java.lang.reflect.Field;
import jdk.incubator.foreign.CLinker;
import jdk.incubator.foreign.FunctionDescriptor;
import jdk.incubator.foreign.SymbolLookup;

/**
 * Keeps native code out of the protocol. stdout is the protocol, but native
 * libraries write to it too (JCEF prints "Initialize JCEF context ..." when
 * Chromium starts), past Java's System.setOut. So the process's own stdout
 * (C's file descriptor 1, and Windows' standard output handle that DLLs
 * loaded later read) becomes stderr, and the protocol goes on a copy of the
 * original.
 *
 * Java 17 has no stable way to call C, so this uses its incubating one
 * (jdk.incubator.foreign, enabled by the runtime's built-in options:
 * host/build.gradle.kts). Without it the protocol stays on stdout as before.
 */
final class StdoutGuard {
    private StdoutGuard() {}

    /** The stream the protocol writes to. Call once, before anything native. */
    static OutputStream protocolStream() {
        try {
            boolean windows = System.getProperty("os.name").toLowerCase().startsWith("windows");
            return windows ? windows() : unix();
        } catch (Throwable e) {
            System.err.println("Native stdout stays shared with the protocol: " + e);
            return new FileOutputStream(FileDescriptor.out);
        }
    }

    private static MethodHandle function(SymbolLookup lookup, String name, Class<?> result, Class<?>... args) {
        MethodType type = MethodType.methodType(result, args);
        FunctionDescriptor descriptor = FunctionDescriptor.of(layout(result), java.util.Arrays.stream(args).map(StdoutGuard::layout).toArray(jdk.incubator.foreign.MemoryLayout[]::new));
        return CLinker.getInstance().downcallHandle(lookup.lookup(name).orElseThrow(() -> new IllegalStateException("no " + name)), type, descriptor);
    }

    private static jdk.incubator.foreign.MemoryLayout layout(Class<?> type) {
        return type == long.class ? CLinker.C_LONG_LONG : CLinker.C_INT;
    }

    // C runtimes in the process (the shared UCRT) keep fd 1, and DLLs with
    // their own C runtime (jcef.dll) take GetStdHandle(STD_OUTPUT_HANDLE)
    // when they load: both now lead to stderr.
    private static OutputStream windows() throws Throwable {
        SymbolLookup crt = CLinker.systemLookup();
        int copy = (int) function(crt, "_dup", int.class, int.class).invokeExact(1);
        if (copy < 0) throw new IllegalStateException("_dup failed");
        long handle = (long) function(crt, "_get_osfhandle", long.class, int.class).invokeExact(copy);
        OutputStream protocol = new FileOutputStream(descriptor("handle", handle));
        if ((int) function(crt, "_dup2", int.class, int.class, int.class).invokeExact(2, 1) != 0) throw new IllegalStateException("_dup2 failed");
        System.loadLibrary("kernel32");
        SymbolLookup kernel32 = SymbolLookup.loaderLookup();
        long stderr = (long) function(kernel32, "GetStdHandle", long.class, int.class).invokeExact(-12);
        int ok = (int) function(kernel32, "SetStdHandle", int.class, int.class, long.class).invokeExact(-11, stderr);
        if (ok == 0) System.err.println("SetStdHandle failed");
        return protocol;
    }

    private static OutputStream unix() throws Throwable {
        SymbolLookup libc = CLinker.systemLookup();
        int copy = (int) function(libc, "dup", int.class, int.class).invokeExact(1);
        if (copy < 0) throw new IllegalStateException("dup failed");
        OutputStream protocol = new FileOutputStream(descriptor("fd", copy));
        if ((int) function(libc, "dup2", int.class, int.class, int.class).invokeExact(2, 1) < 0) throw new IllegalStateException("dup2 failed");
        return protocol;
    }

    // A FileDescriptor for a raw handle (Windows) or fd (elsewhere): Java has
    // no public way to make one, and java.io is not open to this module.
    private static FileDescriptor descriptor(String field, long value) throws Exception {
        Field f = sun.misc.Unsafe.class.getDeclaredField("theUnsafe");
        f.setAccessible(true);
        sun.misc.Unsafe unsafe = (sun.misc.Unsafe) f.get(null);
        FileDescriptor fd = new FileDescriptor();
        long offset = unsafe.objectFieldOffset(FileDescriptor.class.getDeclaredField(field));
        if (field.equals("fd")) {
            unsafe.putInt(fd, offset, (int) value);
        } else {
            unsafe.putLong(fd, offset, value);
        }
        return fd;
    }
}
