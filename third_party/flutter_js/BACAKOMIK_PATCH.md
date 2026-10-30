flutter_js 0.8.7 from pub.dev, minus example/, doc/ and test/, with one fix
in `lib/javascriptcore/jscore_runtime.dart` (macOS and iOS):

The `sendMessage` callback was a static set to the runtime created last, so
with several runtimes (one per extension) a message reached the wrong
runtime, and crashed the app (`JSValueToStringCopy` on a released context)
once that runtime was disposed. It is now routed by the calling context's
global context. Covered by `test/core/js_runtimes_test.dart`.

Drop this copy when a flutter_js release fixes it.
