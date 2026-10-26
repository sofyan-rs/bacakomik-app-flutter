# Extensions are loaded at run time and call the host's classes by name, so
# R8 must keep the API and the libraries extensions use, whole.
-keep class eu.kanade.tachiyomi.** { *; }
-keep class mihon.** { *; }
-keep class tachiyomi.** { *; }
-keep class androidx.compose.runtime.Stable { *; }
-keep class org.kurodev.bacakomik.mihon.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class org.jsoup.** { *; }
-keep class rx.** { *; }
-keep class uy.kohesive.injekt.** { *; }
-keep class kotlinx.serialization.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class kotlin.** { *; }
-keep class app.cash.quickjs.** { *; }
-keep class androidx.preference.** { *; }
# Native code finds these by name over JNI.
-keep class com.squareup.zstd.** { *; }
-keep class org.brotli.** { *; }
-dontwarn okhttp3.**
-dontwarn org.jsoup.**
-dontwarn rx.**
