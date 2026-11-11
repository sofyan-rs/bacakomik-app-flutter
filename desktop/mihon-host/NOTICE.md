# Third-party code in the desktop Mihon host

The host runs the Kotlin of `android/mihon` (the build points at those
files; see `host/build.gradle.kts`) on a JVM. What it adds comes from
[SCANCORE](https://github.com/medium-gh/scancore)'s extension host (MIT,
`LICENSE-SCANCORE`) and the projects SCANCORE took it from, under their own
licences, kept with their notices:

| Path | From | Licence |
| --- | --- | --- |
| `compat/` | SCANCORE's `host/compat`: [Suwayomi-Server](https://github.com/Suwayomi/Suwayomi-Server)'s AndroidCompat (Android API stand-ins for the JVM), with SCANCORE's changes marked "SCANCORE" | Mozilla Public License 2.0 (each file keeps its header) |
| `compat/src/main/java/android/view/MotionEvent.java`, `InputEvent.java`, `android/util/DisplayMetrics.java`, `android/content/res/Resources.java` | Rebuilt by SCANCORE from AOSP's android.jar stubs | Apache License 2.0 |
| `compat/.../webkit/KcefWebViewProvider.kt`, `KcefHelper.kt`, `CefHelper.kt` | Suwayomi-Server's JCEF web view, through SCANCORE. Started by `CefRuntime` when an extension opens a web view | Mozilla Public License 2.0 |
| `compat/src/main/java/android/content/res/Configuration.java` | Rebuilt by Yoru from AOSP's android.jar stubs | Apache License 2.0 |
| `host/.../desktop/CefRuntime.kt` | SCANCORE's `host/desktop/CefRuntime.kt` (Chromium downloaded on first use) | MIT |
| `host/.../desktop/BytecodeEditor.kt` | Suwayomi-Server, through SCANCORE | Mozilla Public License 2.0 |
| `host/.../desktop/ApkLoader.kt`, `InlinedConstructors.kt`, `CompatSettings.kt`, `AppBrowserCheck.kt`, parts of `Main.kt` | SCANCORE's `host/desktop` | MIT |
| `gradle/wrapper/`, `gradlew`, `gradlew.bat` | Gradle | Apache License 2.0 |

Yoru's changes to those files are marked "YORU" in comments: Aniyomi,
CloudStream and Echo left out, `ApkLoader.inspect` added, the browser check
asked over `LineServer`, AndroidCompat's root folder property renamed to
`yoru.mihon.root`, `CustomContext.getResources()` and
`Resources.getConfiguration()` answering instead of null / "Stub!", and in
`CefRuntime`: SHA-256 pinned per platform, `<root>/chromium/<version>`,
progress events, and the first web view waiting for the download.

At build time, `compat` downloads AOSP's public API 30 `android.jar`
(Apache-2.0) and strips the classes it implements.

Libraries the host uses at run time (downloaded by Gradle, shipped in the
runtime the app downloads): Kotlin, kotlinx.coroutines,
kotlinx.serialization, OkHttp, Okio, Brotli, Zstd, Jsoup, RxJava, Injekt,
dex2jar, apk-parser, apksig, the AOSP android.jar stubs, xmlpull,
multiplatform-settings, ICU4J, TwelveMonkeys ImageIO, webp-imageio,
sqlite-jdbc, SLF4J, Mozilla Rhino, JetBrains' JCEF (BSD 3-Clause), and a
trimmed OpenJDK runtime (GPLv2 with the Classpath Exception).

Downloaded by the host the first time an extension opens a web view, never
shipped: the native part of JCEF from a JetBrains Runtime release
(`jbr_jcef-25.0.4-<platform>-b508.27`, from JetBrains' CDN, checked against a
pinned SHA-256): Chromium Embedded Framework and Chromium (BSD 3-Clause and
the licences listed in its `legal/` notices) and JetBrains Runtime (GPLv2
with the Classpath Exception).

The MPL-2.0 text is at https://mozilla.org/MPL/2.0/ and the Apache License
2.0 at https://www.apache.org/licenses/LICENSE-2.0. The source of every
MPL-covered file is this folder.
