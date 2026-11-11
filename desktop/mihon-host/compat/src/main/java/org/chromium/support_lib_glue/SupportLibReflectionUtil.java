package org.chromium.support_lib_glue;

import android.webkit.WebView;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import xyz.nulldev.androidcompat.webkit.KcefWebViewProvider;

// SCANCORE: the entry point androidx.webkit (and Keiyoushi's WebViewGlueBridge,
// which extensions bundle) looks up in the web view's class loader for
// features beyond android.webkit. Answered by method name, since callers
// wrap these handlers in their own copies of the boundary interfaces:
//   DOCUMENT_START_SCRIPT:1  addDocumentStartJavaScript (KcefWebViewProvider)
//   MUTE_AUDIO               setAudioMuted (the browser never plays sound)
// Anything else is reported unsupported, and callers fall back.
public final class SupportLibReflectionUtil {
    private static final String[] FEATURES = {"DOCUMENT_START_SCRIPT:1", "MUTE_AUDIO"};

    private SupportLibReflectionUtil() {}

    // Called by reflection: the name and signature are fixed.
    public static InvocationHandler createWebViewProviderFactory() {
        return new Factory();
    }

    private static Object basics(Object self, Method method, Object[] args) {
        switch (method.getName()) {
            case "hashCode":
                return System.identityHashCode(self);
            case "equals":
                return args != null && args.length == 1 && self == args[0];
            case "toString":
                return "SCANCORE web view glue";
            default:
                throw new UnsupportedOperationException(method.getName() + " is not supported by SCANCORE's web view");
        }
    }

    private static Object nothing(Method method) {
        Class<?> type = method.getReturnType();
        if (type == boolean.class) return false;
        if (type == int.class || type == long.class || type == short.class || type == byte.class) return 0;
        if (type == float.class || type == double.class) return 0.0;
        return null;
    }

    private static final class Factory implements InvocationHandler {
        private final InvocationHandler converter = new Converter();

        @Override
        public Object invoke(Object self, Method method, Object[] args) {
            switch (method.getName()) {
                case "getSupportedFeatures":
                    return FEATURES.clone();
                case "createWebView":
                    return new Provider((WebView) args[0]);
                case "getWebkitToCompatConverter":
                    return converter;
                default:
                    return basics(self, method, args);
            }
        }
    }

    // Settings and other objects are handed back as they are: nothing here
    // needs them (COOKIE_INTERCEPT and the like are not offered).
    private static final class Converter implements InvocationHandler {
        @Override
        public Object invoke(Object self, Method method, Object[] args) {
            if (method.getName().startsWith("convert")) return new NoOp();
            return basics(self, method, args);
        }
    }

    private static final class NoOp implements InvocationHandler {
        @Override
        public Object invoke(Object self, Method method, Object[] args) {
            return nothing(method);
        }
    }

    private static final class Provider implements InvocationHandler {
        private final WebView view;

        Provider(WebView view) {
            this.view = view;
        }

        @Override
        public Object invoke(Object self, Method method, Object[] args) {
            switch (method.getName()) {
                case "addDocumentStartJavaScript": {
                    if (!(view.getWebViewProvider() instanceof KcefWebViewProvider))
                        throw new UnsupportedOperationException("This web view cannot run scripts");
                    KcefWebViewProvider provider = (KcefWebViewProvider) view.getWebViewProvider();
                    Function0<Unit> remove = provider.addDocumentStartScript((String) args[0], (String[]) args[1]);
                    return new ScriptHandler(remove);
                }
                case "setAudioMuted":
                    return null;
                default:
                    return basics(self, method, args);
            }
        }
    }

    private static final class ScriptHandler implements InvocationHandler {
        private final Function0<Unit> remove;

        ScriptHandler(Function0<Unit> remove) {
            this.remove = remove;
        }

        @Override
        public Object invoke(Object self, Method method, Object[] args) {
            if (method.getName().equals("remove")) {
                remove.invoke();
                return null;
            }
            return basics(self, method, args);
        }
    }
}
