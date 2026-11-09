flutter_js 0.8.7 from pub.dev, minus example/, doc/ and test/, with one fix
in `lib/javascriptcore/jscore_runtime.dart` (macOS and iOS):

The `sendMessage` callback was a static set to the runtime created last, so
with several runtimes (one per extension) a message reached the wrong
runtime, and crashed the app (`JSValueToStringCopy` on a released context)
once that runtime was disposed. It is now routed by the calling context's
global context. Covered by `test/core/js_runtimes_test.dart`.

Drop this copy when a flutter_js release fixes it.

Linux: `linux/CMakeLists.txt` exported the QuickJS bridge as
`flutter_qjs_bundled_libraries` (the app reads `flutter_js_bundled_libraries`)
and installed it into the plugin's own default prefix, so
`libquickjs_c_bridge_plugin.so` was missing from the release bundle and every
JS source failed with "cannot open shared object file". It is now exported
under the right name, so the app installs it into `bundle/lib`.
