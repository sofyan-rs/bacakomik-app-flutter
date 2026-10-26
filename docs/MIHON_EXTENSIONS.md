# Mihon extensions (plan)

How to run Mihon (Tachiyomi) extension APKs inside BacaKomik, next to the JavaScript extensions. **Android only.** Nothing here is built yet; this is the implementation plan. Read [ARCHITECTURE.md](ARCHITECTURE.md) §8 first.

§ numbers refer to this file; "ARCHITECTURE §n" to the other one.

---

## 1. Goal and scope

**Goal:** a user adds a Mihon repo (e.g. Keiyoushi), installs an extension, and its sources work like any other source: Home, Explore, comic page, reader, bookmarks, refresh, history, downloads, sync, migration.

**Keeps working as is**
- JavaScript extensions, `index.json` repos, bundled `bacakomik` / `voratoon`. Mihon is a **second backend**, not a replacement.
- The library format. Mihon comics are ordinary comic keys (§4.1), so backup, sync and the journal need no change.
- iOS: JS extensions only. Mihon repos and extensions are hidden there.

**Not in scope**
- Aniyomi (anime) and LNReader (novels).
- Desktop. Possible later (§15); the Android work keeps the door open.
- Google Play. The app is not published there, so its rule against loading outside code does not apply.

---

## 2. How it works

A Mihon extension APK is not a real app. It holds compiled code (`classes.dex`), a manifest and an icon. Its code is written against Mihon's source API (`eu.kanade.tachiyomi.source.*`) and expects the host app to provide that API and its libraries (OkHttp, Jsoup, …).

So the app does what Mihon does with a "private" extension:

1. Download the APK into the app's own storage. No system install.
2. `PackageManager.getPackageArchiveInfo(path, GET_META_DATA | GET_SIGNING_CERTIFICATES)` reads the manifest and signer of the **uninstalled** file.
3. Check the signer, the extension lib version and the source class names (§5.3).
4. `DelegateLastClassLoader(path, nativeLibDir, appClassLoader)` loads the classes. The parent is the app's class loader, which contains the Mihon API with the **exact same class names**, so the extension finds it.
5. Instantiate the classes named in the manifest. Each is a `Source` or a `SourceFactory` (which returns several sources).
6. Call the source (`getPopularManga`, `getMangaDetails`, …) from Kotlin and send the results to Dart as JSON shaped like the JS contract (§4.3).

```
Dart                                           Kotlin (android/app)
ExtensionManager ─► MihonSource (LoadedSource) ─ MethodChannel bacakomik/mihon ─► MihonHost
                                                                                  ├─ MihonLoader (APK ─► Source)
                                                                                  ├─ Injekt: Application, NetworkHelper, Json
                                                                                  └─ ImageProxy (127.0.0.1)
reader / covers / downloads ── http://127.0.0.1:<port>/… ─────────────────────────┘
```

Reference implementation: SCANCORE (`github.com/medium-gh/scancore`), `host/api` (the Mihon API, Apache 2.0 from Mihon, MIT changes) and `host/android/…/AndroidLoader.kt`.

---

## 3. Phases

Each phase ends with something that runs on a phone. Phase 0 decides whether the rest goes ahead.

| # | Phase | Done when |
|---|---|---|
| 0 | Spike | One Keiyoushi APK loads from app storage and `getPopularManga(1)` prints titles in logcat, in a **release** build |
| 1 | Kotlin host (§5) | Channel answers `load`, `browse`, `series`, `chapters`, `chapter` for a loaded APK |
| 2 | Image proxy (§6) | Covers and pages show in a test screen through `127.0.0.1` |
| 3 | Dart backend (§7) | A Mihon source works on Home, comic page and reader; bookmark and history keys are stored |
| 4 | Repos and install (§8) | Add a Mihon repo, install, update, uninstall from Extensions |
| 5 | Filters and Home (§9) | Explore filters and Home's two lists work |
| 6 | Cloudflare and WebView (§10) | A Cloudflare source passes after "Verify in WebView" |
| 7 | Source settings (§11) | A `ConfigurableSource`'s settings show, save and take effect |
| 8 | Downloads and Mihon import (§12) | Background download of a Mihon chapter; `.tachibk` import matches by source id |
| 9 | Docs and tests (§13) | ARCHITECTURE §8 updated; tests pass |

Phases 5–8 are independent of each other once 4 is done.

---

## 4. Contracts

### 4.1 Ids and keys

| Thing | Format | Example |
|---|---|---|
| Source id | `mihon-<Mihon source id>` | `mihon-2499283573021220255` |
| Extension id | `mihon-` + package with `.` → `_` | `mihon-eu_kanade_tachiyomi_extension_en_mangadex` |
| Comic slug | base64url (no padding) of `SManga.url` | `L21hbmdhLzEyMw` |
| Comic key | `ComicKey.of(sourceId, slug)` | `mihon-2499283573021220255:L21hbmdhLzEyMw` |
| Chapter key | `<comicKey>/<number>` (unchanged) | `…:L21hbmdhLzEyMw/14` |

- **`:` must not appear in a source id**: `ComicKey` splits on the first `:`. Hence `mihon-`, not `mihon:`.
- Mihon source ids are positive 63-bit numbers (the MD5 of `<name>/<lang>/<versionId>`, as `mihonSourceId` already computes) and never change, so keys stay valid across extension updates.
- `SManga.url` is a path with `/`, `?`, sometimes non-ASCII. Base64url makes it ASCII, slash-free and safe for Hive keys, download folders and deep links. A key over `ComicKey.maxLength` (240) is skipped like any other (ARCHITECTURE §7.1); with a 27-character prefix that allows URLs up to ~160 characters.

### 4.2 Chapters are addressed by number

The app keys chapters by number; Mihon by URL. The Kotlin host keeps, per comic, the last chapter list it fetched (`number → SChapter`), and:

- `chapters` returns one chapter per `chapter_number`, newest first. Duplicates (several scanlators) keep the **first** in Mihon's order. Chapters with `chapter_number < 0` (unnumbered) are left out.
- `chapter(slug, number)` uses the cached list, fetching it again when missing or when the number is not in it. `prev` / `next` come from the same list.
- Known loss: unnumbered extras and alternative scanlations do not show. Acceptable for a first version; note it in the release.

### 4.3 Mapping to the JS contract

Kotlin returns the shapes of `bacakomik-ext/types/bridge.d.ts`, so `SeriesRemoteDataSource` and the DTOs stay as they are.

| Method | Mihon call | Mapping |
|---|---|---|
| `browse({page, query, filters})` | `getSearchManga` when `query` or a non-default filter is set; else `getPopularManga` or `getLatestUpdates` (§9) | `items[]` from `MangasPage.mangas`, `hasNext` = `hasNextPage`; `limit` ignored |
| `series(slug)` | `getMangaDetails(SManga(url))` | `title`, `cover` = proxied `thumbnail_url` (§6), `status` from the `SManga` constant (`Ongoing`, `Completed`, `Hiatus`, `Cancelled`, `Publishing finished`, else null), `author` = author + artist without repeats joined with `, `, `synopsis` = `description`, `genres` from `genre` split on `,` (id = name), `format`, `rating`, `nativeTitle`, `releaseDate`, `totalChapters` = null |
| `chapters(slug)` | `getChapterList` | §4.2; `createdAt` = `date_upload` (ms) as ISO 8601, null when 0 |
| `chapter(slug, number)` | `getPageList(SChapter)` | `title` = `SChapter.name`, `images` = proxied page URLs (§6), no `headers` |
| `webUrl(slug)` | `getMangaUrl(SManga)` (lib 1.5+), else `baseUrl + url` | |
| `filters()` / `home` | `getFilterList()` | §9 |

Errors: an `HttpException` with code 404 (or the source's own "not found") becomes an error starting with `404`, as the JS contract asks. Other exceptions go back as their message.

---

## 5. Kotlin host (phase 1)

All in `android/app/src/main/kotlin/org/kurodev/bacakomik/mihon/`, plus the API sources under their original packages.

### 5.1 The Mihon API

Copy from SCANCORE `host/api/src/main/kotlin`: `eu/kanade/tachiyomi/source/**`, `eu/kanade/tachiyomi/network/**`, `eu/kanade/tachiyomi/util/**`, `eu/kanade/tachiyomi/AppInfo.kt`, `mihon/**`, `tachiyomi/**`, `androidx/compose/runtime/Stable.kt`. Leave out `animesource`.

- Keep the original package names; extensions link against them by name.
- Keep the licence headers. Add `android/app/NOTICE.md` listing Mihon (Apache 2.0) and SCANCORE (MIT), and add both to the app's licences screen.
- Replace SCANCORE's desktop `NetworkHelper` with Mihon's Android one (`AndroidCookieJar` over the WebView `CookieManager`, `CloudflareInterceptor` with a real `WebView`).

### 5.2 Libraries

Add to `android/app/build.gradle` the libraries extensions expect from the host, at the **versions Mihon's extension lib was built with** (take them from Mihon's `gradle/libs.versions.toml` at the time of the work): OkHttp (+ brotli, dnsoverhttps), Okio, Jsoup, RxJava 1, `uy.kohesive.injekt`, `kotlinx-serialization-json` (+ protobuf), `kotlinx-coroutines`, `app.cash.quickjs` (or SCANCORE's QuickJS choice), `androidx.preference`.

- The app's Kotlin stdlib must be at least as new as the one extensions were compiled with. Check the Kotlin version Flutter's Gradle plugin uses in phase 0.
- Expect the APK to grow by a few MB per ABI.

### 5.3 Loader (`MihonLoader.kt`)

Port `AndroidLoader.kt`:

1. File missing → error "install it again". `setReadOnly()` the APK (Android 14 refuses to load code from writable files).
2. `getPackageArchiveInfo`; set `applicationInfo.sourceDir` / `publicSourceDir` to the path.
3. **Signer:** SHA-256 of the signing certificate must equal the fingerprint the repo publishes (§8.1). Unsigned or mismatched → refuse.
4. **Lib version:** meta-data `tachiyomix.extensionLib` (float), else `versionName` without its last part. Accept the versions the copied API implements (1.4 and 1.5 at the time of writing; check Mihon). Others → "This extension needs a newer BacaKomik".
5. **Classes:** meta-data `tachiyomi.extension.class`, split on `;`, a leading `.` means "prefix the package".
6. `DelegateLastClassLoader(apk, nativeLibraryDir, context.classLoader)`, instantiate, flatten `Source` / `SourceFactory` into a list of `CatalogueSource`.
7. Also read `tachiyomi.extension.nsfw` and the APK's label and icon (`packageManager.getResourcesForApplication(applicationInfo)`) for the Extensions list.

### 5.4 Start-up (`MihonHost.kt`)

Once, before the first load (and in the proxy's process, §6.3):

- `Injekt.addSingleton(application)`, `NetworkHelper(application)`, a `Json { ignoreUnknownKeys = true; explicitNulls = false }`. Extensions call `Injekt.get<…>()` in their constructors.
- Keep loaded sources in a map `sourceId → CatalogueSource`, and `extensionId → classLoader` so an update or uninstall drops the old one.

### 5.5 Channel `bacakomik/mihon`

| Method | Arguments | Result |
|---|---|---|
| `inspect` | `path` | `{pkg, name, versionName, versionCode, lib, nsfw, signers[], sources[{id, name, lang, baseUrl, supportsLatest}]}` without keeping it loaded |
| `load` | `extensionId`, `path`, `signer` | same `sources[]`; keeps the instances |
| `unload` | `extensionId` | drops instances and class loader |
| `call` | `sourceId`, `method`, `args` (JSON) | JSON per §4.3 |
| `userAgent` | `sourceId` | the source's `User-Agent` header (§10) |
| `preferences` / `setPreference` | §11 | |
| `proxyBase` | – | `http://127.0.0.1:<port>/<token>` (§6) |

- Every call runs on `Dispatchers.IO` (Mihon's methods block or suspend) and answers on the main thread. Never block the platform thread.
- One call per source at a time is not required; Mihon sources are thread-safe enough for Mihon's own parallel use. Rate limits are the extension's own interceptors.
- Add a timeout per call (60 s) so a hung site fails with "did not respond" like a JS source.

### 5.6 R8 / release builds

Flutter release builds shrink with R8. Extension classes are not part of the build, so R8 would remove or rename the API they need. Add to `android/app/proguard-rules.pro`:

```
-keep class eu.kanade.tachiyomi.** { *; }
-keep class mihon.** { *; }
-keep class tachiyomi.** { *; }
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
```

**Phase 0 must be tested on a release build**; a debug build hides this whole class of failure.

---

## 6. Images through a local proxy (phase 2)

Mihon sources often need their own OkHttp client to fetch images: headers, cookies, and **interceptors that unscramble the image**. `cached_network_image` and `background_downloader` cannot do that. Instead of teaching every image path about Mihon, Kotlin serves images on localhost and Dart sees ordinary URLs.

### 6.1 Routes

| Route | Fetches |
|---|---|
| `GET /<token>/cover?s=<sourceId>&u=<b64 thumbnail_url>` | `source.client` GET with `source.headers` |
| `GET /<token>/page?s=<sourceId>&p=<b64 Page.url>&i=<b64 Page.imageUrl>` | `imageUrl`, or `getImageUrl(page)` first when it is empty, then `getImageRequest` / `imageRequest(page)` through `source.client` |

Response: the bytes with the upstream `Content-Type`; upstream status on failure.

### 6.2 Details

- Server: NanoHTTPD or a small `ServerSocket` loop bound to `127.0.0.1` only, on a port fixed per install (stored in `SharedPreferences`; a new one only if taken).
- **Token:** a random path segment generated per install. Other apps on the phone can reach localhost; without the token they get 403.
- **Cache keys:** the URL contains the port and token. Set `cacheKey` to the URL without `http://127.0.0.1:<port>/<token>` so `comicImageCache` and `coverImageCache` survive a port change.
- Android blocks cleartext HTTP by default: allow `127.0.0.1` in `network_security_config.xml`.
- Image-host checks (`ImageHostCookies`, `imageHostBlocks`, ARCHITECTURE §8.6) must skip `127.0.0.1`.

### 6.3 Downloads in the background

`background_downloader` runs from WorkManager and may run after the app's UI has gone. The proxy must work without Dart:

- Start the proxy from a custom `Application.onCreate`, not from the Flutter engine.
- The proxy loads an extension on demand from what is installed: Kotlin keeps its own small index (`SharedPreferences`: `sourceId → extensionId, apk path, signer`), written by `load` and cleared by `unload`.

---

## 7. Dart backend (phase 3)

### 7.1 `ExtensionMeta`

Add:
- `kind`: `script` (default, current behaviour) or `apk`.
- `pkg`, `signer` (SHA-256), `versionCode`, `lib`, `sources` (`[{id, name, lang}]`) for `apk`.
- `sha256` becomes optional for `apk` (Mihon repos don't publish it; the signer replaces it).

A Mihon extension with several sources maps onto the existing multi-language model: each entry of `sources` is one app source `mihon-<id>` with `parentId` = the extension id. Enabled sources are stored like enabled languages (`source_settings` → `langs:<extensionId>`, holding languages), default English, else the first. Several sources with the same language (rare) are all enabled together.

### 7.2 `MihonSource implements LoadedSource`

`lib/core/source/mihon_source.dart`:
- `call(method, args)` → channel `call`.
- `features()` → `filters()` + `home` (§9), cached like `ExtensionRuntime`.
- `dispose()` → nothing per source; `ExtensionManager` calls `unload` per extension on update and uninstall.

`ExtensionManager._load` picks the backend from `meta.kind`; the install, update and "updated while loading" logic stays shared.

### 7.3 Platform

`Platform.isAndroid` gates everything: on other platforms Mihon repos are not fetched, `apk` metas are not listed, and a stored Mihon key shows `MissingSource` with "Android only".

---

## 8. Repos and install (phase 4)

### 8.1 Repo format

A Mihon repo is a base URL with:
- `repo.json`: `{ meta: { name, shortName, website, signingKeyFingerprint } }`.
- `index.min.json`: `[{ name, pkg, apk, lang, code, version, nsfw, sources: [{ name, lang, id, baseUrl }] }]`.
- APKs at `<base>/apk/<apk>`, icons at `<base>/icon/<pkg>.png`.

`addRepo` accepts a URL ending in `index.min.json` or `repo.json` (or the base) and stores it as a Mihon repo. `fetchRepo` parses it into `ExtensionMeta(kind: apk, signer: signingKeyFingerprint, …)`. A repo without `signingKeyFingerprint` is refused: the signer check is the only protection against a swapped APK.

**Icon and 18+** (same for both backends; can ship before Mihon support):
- `ExtensionMeta.icon`: optional URL. JS extensions get it from `index.json` (`build.ts` copies `src/<id>/icon.png` to `dist/icon/<id>.png`); Mihon from `<base>/icon/<pkg>.png`, else the APK's own icon. Loaded through `coverImageCache` so it shows offline.
- **No icon → the first letter of the name** in a Dotline circle. Never a blank or a generic picture.
- `nsfw` (already in `meta.json` and `ExtensionMeta`) shows as an `18+` label on the extension and in the source picker.

### 8.2 Install, update, uninstall

- **Install:** download to `<app support>/extensions/<extensionId>.apk.part`, rename, `inspect` (signer must match the repo's, lib supported), then `load`. Save the meta. A failed check deletes the file.
- **Update:** newer `code` in the repo. `unload`, replace the file, `load`. Keys don't change (§4.1).
- **Uninstall:** `unload`, make the file writable and delete it, remove meta, enabled sources, and the sources' `SharedPreferences` (`source_<id>`). Cookies live in the shared WebView `CookieManager`; leave them.
- Default repos: none. The user adds a Mihon repo themselves. Do not bundle any APK.

### 8.3 Security

An extension runs with all of the app's permissions and data. The only gate is the signer: an APK is loaded only if signed by the key its repo declares, and an update must keep the installed signer. Say so once in the "Add repo" sheet for Mihon repos.

---

## 9. Filters and Home (phase 5)

### 9.1 Filter mapping

`getFilterList()` gives a tree. Each top-level filter becomes a `FilterGroup` with key `f<index>`:

| Mihon filter | App group | Values |
|---|---|---|
| `Select` | `select` | option index as `value`, its `toString()` as label |
| `Sort` | `select` | one option per `(index, ascending)` pair: `"<name> ↑"`, `"<name> ↓"` |
| `Group` of `CheckBox` | `multi` | checked children's indexes |
| `Group` of `TriState` | `multi` | included children's indexes (exclude not supported) |
| top-level `CheckBox` / `TriState` | `multi` with one option | |
| `Text` | not shown | |
| `Header`, `Separator` | not shown | |

On `browse`, Kotlin calls `getFilterList()` again for a fresh list and applies the values by index. Sources whose filter list changes after a first request (some fetch genres) work, because the fresh list is built after the source has run.

### 9.2 Home and the popular/latest choice

- `home.featured = { "_list": ["popular"] }`, `home.latest = { "_list": ["latest"] }` (`popular` again when `supportsLatest` is false).
- `browse` with no query, only `_list` and filters at their defaults → `getPopularManga` / `getLatestUpdates`. Anything else → `getSearchManga(page, query ?: "", filters)`.
- Explore's default (no query, no filter) is popular.

---

## 10. Cloudflare and WebView (phase 6)

- Mihon's `NetworkHelper` uses `AndroidCookieJar`, i.e. the WebView `CookieManager`. The app's WebView screen (`flutter_inappwebview`) uses the same `CookieManager`, so a `cf_clearance` the user gets there is seen by the Mihon source with no copying.
- `cf_clearance` is bound to the User-Agent. The WebView screen must use the source's UA: `userAgent(sourceId)` from the channel, instead of the JS default.
- Mihon's `CloudflareInterceptor` solves automatic checks itself. When it gives up (it throws "Failed to bypass Cloudflare"), Kotlin returns `challenge: <request url>` so `SourceError` shows "Verify in WebView" as for JS sources.
- `HeadlessPages` is not used by Mihon sources.

---

## 11. Source settings (phase 7)

Many extensions implement `ConfigurableSource` (mirror domain, image quality, language, show/hide scanlators). Mihon shows them in "Extension settings". They work here too.

1. **Read:** Kotlin builds a `PreferenceScreen` with `PreferenceManager(context).createPreferenceScreen(context)`, calls `source.setupPreferenceScreen(screen)`, and serializes each preference:

   ```jsonc
   { "key": "pref_domain", "type": "list",          // list | multi | switch | checkbox | text
     "title": "Mirror", "summary": "…",
     "entries": ["Main", "Mirror 1"], "entryValues": ["a.com", "b.com"],
     "value": "a.com", "default": "a.com", "enabled": true }
   ```

   Types: `ListPreference` → `list`, `MultiSelectListPreference` → `multi`, `SwitchPreferenceCompat` → `switch`, `CheckBoxPreference` → `checkbox`, `EditTextPreference` → `text`. Others are skipped. Summaries with `%s` get the current entry.

2. **Write:** `setPreference(sourceId, key, value)` calls the preference's `callChangeListener(value)` (an extension may refuse a value or show a toast) and, if accepted, writes `getSharedPreferences("source_<id>")`.
3. **Take effect:** many extensions read settings in their constructor or a `lazy`. After any change, reload that extension (`unload` + `load`) and drop its `LoadedSource` in `ExtensionManager`, so the next call uses the new value.
4. **UI:** a "Settings" row on the extension in Extensions, opening a Dotline sheet with `ListGroup` / `ListRow`, switches, a picker sheet for lists and a text field sheet. Strings from the extension are shown as sent.

The values live in the extension's `SharedPreferences`, like in Mihon; they are not in backup or sync (same as other source settings).

---

## 12. Downloads and Mihon import (phase 8)

- **Downloads:** page URLs are proxy URLs (§6), so `PageDownloadQueue` needs no change once §6.3 works. Test: start a download, swipe the app away, check it finishes.
- **Mihon import:** a `.tachibk` source id that equals an installed Mihon source's id maps straight to `mihon-<id>` with slug = base64url of the backup's manga URL. No `urlPatterns`, no title search. Chapters match by `chapter_number` as today. Source ids that match neither a Mihon nor a JS source keep today's behaviour (name match).
- **Missing source:** on a phone without the extension, `MissingSource` finds `mihon-<id>` in the Mihon repos' `sources[].id` and offers to install it.

---

## 13. Tests and docs (phase 9)

**Dart (no device)**
- `MihonSource` with a fake channel: method names and arguments, error mapping (`404`, `challenge:`).
- `ExtensionMeta` round trip for `kind: apk`; Mihon `index.min.json` parsing; a repo without `signingKeyFingerprint` is refused.
- Slug encoding: `SManga.url` with `/`, `?`, non-ASCII → `storable` key and back.
- Filter mapping from a JSON fixture of a Mihon filter tree.

**Kotlin**
- Unit tests for the mappers (`SManga` → JSON, chapter dedupe §4.2, filter tree ⇄ values).
- On a device: load 3 real extensions of different kinds — a plain HTML one (Madara theme), an API one (MangaDex), one behind Cloudflare — through Home, comic page, reader, download, settings. Use a **release** build.

**Docs**
- ARCHITECTURE: §8 (second backend, ids, proxy), §3 table (`mihon/` folder, `bacakomik/mihon` channel), §7.1 (APK files in `extensions/`), §2 (new libraries), §1 non-goals (iOS gets JS only).
- Licences screen and `NOTICE.md` (§5.1).
- Release notes: Mihon extensions on Android; unnumbered chapters and alternative scanlations are hidden (§4.2).

---

## 14. Risks and open questions

| Risk | What to do |
|---|---|
| Kotlin or library versions in the app don't match what extensions were compiled with (`NoSuchMethodError`, `NoClassDefFoundError`) | Phase 0 on several extensions; pin versions to Mihon's |
| R8 strips API classes in release | §5.6 keep rules; test release only |
| Extension lib version moves (Mihon 1.6+) | Lib check refuses clearly; update the copied API |
| Unscrambled or header-bound images | Covered by the proxy (§6); test a source that scrambles |
| Proxy reachable by other apps | Token (§6.2), localhost only |
| A malicious or swapped APK | Signer check (§8.1, §8.3) |
| Duplicate / unnumbered chapters | §4.2, documented limitation |
| Memory: each extension's classes stay loaded | Load on first use only; unload on uninstall and update |

---

## 15. Later: desktop

Not planned now, but the Android design must not block it. Desktop can run Mihon extensions the way SCANCORE and Suwayomi do:

- A **separate JVM process** (a trimmed JRE shipped or downloaded on first use) runs the host. It converts each APK's dex to a jar with **dex2jar** (once per version), and provides Android classes extensions touch (`Context`, `SharedPreferences`, `WebView`, …) through stand-ins such as Suwayomi's **AndroidCompat** (MPL 2.0).
- Dart talks to it over **stdin/stdout, one JSON object per line**, with the same methods and results as the channel (§5.5). The image proxy (§6) works unchanged on localhost.
- Cloudflare needs a real browser: JCEF / KCEF, as Suwayomi and SCANCORE do.
- Alternative: run **Suwayomi-Server** itself as the backend and call its API. Less code to own, but a bigger dependency and a different contract.

What to do now so this stays cheap:
1. In Dart, `MihonSource` talks to a `MihonHost` interface, not to `MethodChannel` directly. Android implements it with the channel; desktop would implement it with the process.
2. Keep the Kotlin mappers (§4.3, §4.2, §9.1) and the API copy in plain-JVM code with no Android imports, so a desktop host can reuse them. Only the loader (§5.3), `NetworkHelper`, settings UI glue and the proxy start-up are Android-specific.

Open questions:
- Should Mihon and JS sources with the same site be marked as such in the source picker (e.g. a small `APK` label)?
- Should `TriState` exclude be added to the filter contract (a third state), for both backends?
