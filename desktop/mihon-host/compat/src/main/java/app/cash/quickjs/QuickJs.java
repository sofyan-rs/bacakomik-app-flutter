/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// SCANCORE: QuickJS's Java API (what Mihon gives extensions) on Mozilla
// Rhino instead of GraalJS: about 1.5 MB, compiling scripts to JVM
// bytecode. Values come back as QuickJS returns them: Integer, Long or
// Double, Boolean, String, arrays of those, or null.
package app.cash.quickjs;

import org.mozilla.javascript.ConsString;
import org.mozilla.javascript.Context;
import org.mozilla.javascript.ContextFactory;
import org.mozilla.javascript.NativeArray;
import org.mozilla.javascript.NativeJavaObject;
import org.mozilla.javascript.RhinoException;
import org.mozilla.javascript.Scriptable;
import org.mozilla.javascript.ScriptableObject;
import org.mozilla.javascript.Undefined;

import java.io.Closeable;

public final class QuickJs implements Closeable {
    private static final ContextFactory FACTORY = new ContextFactory() {
        @Override
        protected Context makeContext() {
            Context cx = super.makeContext();
            cx.setLanguageVersion(Context.VERSION_ES6);
            cx.setInterpretedMode(false);
            return cx;
        }

        @Override
        protected boolean hasFeature(Context cx, int feature) {
            // Scripts must not reach Java classes they were not handed.
            if (feature == Context.FEATURE_ENHANCED_JAVA_ACCESS)
                return false;
            return super.hasFeature(cx, feature);
        }
    };

    private ScriptableObject scope;

    public static QuickJs create() {
        return new QuickJs();
    }

    public QuickJs() {
        scope = (ScriptableObject) FACTORY.call(cx -> {
            ScriptableObject standard = cx.initSafeStandardObjects();
            // No Packages/java globals: scripts see only JavaScript.
            return standard;
        });
    }

    public Object evaluate(String script, String fileName) {
        if (scope == null)
            throw new IllegalStateException("QuickJs is closed");
        try {
            return FACTORY.call(cx -> {
                try {
                    return translate(cx.evaluateString(scope, script, fileName, 1, null));
                } catch (IllegalStateException | IllegalArgumentException tooLarge) {
                    // Methods over the JVM's 64 KB limit: interpret instead.
                    cx.setInterpretedMode(true);
                    return translate(cx.evaluateString(scope, script, fileName, 1, null));
                }
            });
        } catch (RhinoException e) {
            throw new QuickJsException(e.details(), e);
        } catch (RuntimeException e) {
            throw new QuickJsException(String.valueOf(e.getMessage()), e);
        }
    }

    public Object evaluate(String script) {
        return evaluate(script, "?");
    }

    public byte[] compile(String sourceCode, String fileName) {
        return sourceCode.getBytes(java.nio.charset.StandardCharsets.UTF_8);
    }

    public Object execute(byte[] bytecode) {
        return evaluate(new String(bytecode, java.nio.charset.StandardCharsets.UTF_8));
    }

    public <T> void set(String name, Class<T> type, T object) {
        FACTORY.call(cx -> {
            ScriptableObject.putProperty(scope, name, Context.javaToJS(object, scope));
            return null;
        });
    }

    @SuppressWarnings("unchecked")
    public <T> T get(String name, Class<T> type) {
        return (T) FACTORY.call(cx -> translate(ScriptableObject.getProperty(scope, name)));
    }

    @Override
    public void close() {
        scope = null;
    }

    private static Object translate(Object value) {
        if (value == null || value instanceof Undefined || value == Scriptable.NOT_FOUND)
            return null;
        if (value instanceof NativeJavaObject)
            return ((NativeJavaObject) value).unwrap();
        if (value instanceof ConsString || value instanceof CharSequence)
            return value.toString();
        if (value instanceof Boolean)
            return value;
        if (value instanceof Number)
            return number(((Number) value).doubleValue());
        if (value instanceof NativeArray) {
            NativeArray array = (NativeArray) value;
            int size = (int) array.getLength();
            if (size == 0)
                return new int[0];
            Object first = translate(array.get(0, array));
            if (first instanceof Boolean) {
                boolean[] out = new boolean[size];
                for (int i = 0; i < size; i++)
                    out[i] = Boolean.TRUE.equals(translate(array.get(i, array)));
                return out;
            }
            if (first instanceof Number) {
                boolean ints = true;
                double[] values = new double[size];
                for (int i = 0; i < size; i++) {
                    Object v = array.get(i, array);
                    values[i] = v instanceof Number ? ((Number) v).doubleValue() : Double.NaN;
                    ints &= values[i] == Math.rint(values[i]) && Math.abs(values[i]) <= Integer.MAX_VALUE;
                }
                if (!ints)
                    return values;
                int[] out = new int[size];
                for (int i = 0; i < size; i++)
                    out[i] = (int) values[i];
                return out;
            }
            if (first instanceof String) {
                String[] out = new String[size];
                for (int i = 0; i < size; i++) {
                    Object v = translate(array.get(i, array));
                    out[i] = v == null ? null : v.toString();
                }
                return out;
            }
            Object[] out = new Object[size];
            for (int i = 0; i < size; i++)
                out[i] = translate(array.get(i, array));
            return out;
        }
        return value;
    }

    private static Object number(double d) {
        if (d == Math.rint(d) && !Double.isInfinite(d)) {
            if (Math.abs(d) <= Integer.MAX_VALUE)
                return (int) d;
            if (Math.abs(d) <= Long.MAX_VALUE)
                return (long) d;
        }
        return d;
    }
}
