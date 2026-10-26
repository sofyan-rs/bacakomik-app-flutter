# Mihon extensions

How BacaKomik runs Mihon (Tachiyomi) extension APKs next to its JavaScript extensions. **Android 9+ only.** Read [ARCHITECTURE.md](ARCHITECTURE.md) §8 first.

§ numbers refer to this file; "ARCHITECTURE §n" to the other one.

---

## 1. Scope

A user adds a Mihon repo (e.g. Keiyoushi), installs an extension, and its sources work like any other source: Home, Explore (search, filters), comic page, reader, bookmarks, refresh, history, downloads, sync, migration, Mihon backup import.

- **JS extensions keep working.** Mihon is a second `LoadedSource` backend; ids never collide (§3.1), so the same site from both is two sources.
- **Library format unchanged.** Mihon comics are ordinary comic keys, so backup, sync and the journal need nothing new.
- **iOS / Android 8 and older:** JS only. Mihon repos are skipped and can't be added.
- **Not supported:** Aniyomi (anime), LNReader (novels), desktop (§11). The app is not on Google Play, so its rule against loading outside code does not apply.

---

## 2. How it works

A Mihon extension APK is not a real app: compiled code (`classes.dex`), a manifest and an icon, written against Mihon's source API (`eu.kanade.tachiyomi.source.*`). The host app must provide that API, with the same class names, and the libraries extensions use (OkHttp, Jsoup, …). BacaKomik does what Mihon does with a "private" extension:

1. Download the APK into app storage (no system install).
2. `getPackageArchiveInfo` reads the manifest and signer of the uninstalled file; the signer must be the repo's key, the lib version one the host runs.
3. `DelegateLastClassLoader(apk, …, appClassLoader)` loads the classes named in the manifest (`Source` or `SourceFactory`).
4. Kotlin calls the source and answers Dart in the JS contract's shapes, so everything above `SourceBackend` treats both backends alike.

```
Dart                                              Kotlin
ExtensionManager ─► MihonSource (LoadedSource) ─┐
image caches (mihon:// URLs) ───────────────────┼─ MethodChannel bacakomik/mihon ─► MihonChannel (app)
MihonInstaller ─────────────────────────────────┘                                     └─► MihonHost (:mihon module)
                                                                                          ├─ Contract, Filters, Images, Slugs
                                                                                          ├─ SourceIndex (installed APKs)
                                                                                          └─ ExtensionHost + AndroidLoader (SCANCORE)
```

---

## 3. Contracts

### 3.1 Ids and keys

| Thing | Format | Example |
|---|---|---|
| Extension id | `mihon-` + package without `eu.kanade.tachiyomi.extension.`, `.` → `_` | `mihon-en_example` |
| Source id | `mihon-<Mihon source id>` | `mihon-3639673976007021338` |
| Comic slug | base64url, no padding, of `SManga.url` (`Slugs.kt`, `ExtensionMeta.mihonSlug`) | `L21hbmdhLzEyMw` |
| Comic key / chapter key | `ComicKey` as usual | `mihon-363…:L21hbmdhLzEyMw/14` |

- Never `:` in a source id: `ComicKey` splits on the first `:`.
- Mihon source ids are stable hashes, so keys survive extension updates and match Mihon backups.
- A multi-source extension maps onto the multi-language model: `ExtensionMeta.mihonSources`, each one `forMihonSource`; enabled languages in `langs:<extensionId>` as for JS.

### 3.2 Methods (`Contract.kt`)

| App method | Mihon | Notes |
|---|---|---|
| `browse` | `getSearchManga` when a query or a changed filter is set; else `getPopularManga` / `getLatestUpdates` by the `_list` value Home sends | `limit` ignored; `hasNext` = `hasNextPage` |
| `series` | `getMangaUpdate` (details) | status from the `SManga` constant (`ongoing`, `completed`, `licensed`, `cancelled`, `hiatus`); author + artist without repeats; genres split, id = name |
| `chapters` | `getMangaUpdate` (chapters) | number = `chapter_number`, else read from the chapter's name as Mihon does (`ChapterRecognition.kt`, from Mihon); one per number, first in Mihon's order; none found → left out; whole numbers as integers |
| `chapter` | `getPageList` | finds the URL of a number in the last list (fetches again when missing); `prev` / `next` from the list; images are `mihon://` URLs |
| `webUrl` | `HttpSource.getMangaUrl` | |
| `features` | `getFilterList` | filter groups (§3.3) + `home` (`_list: popular / latest`). A source that made no request yet first loads popular page 1: many extensions fetch their genre list with their first request, and a list still showing a "Press reset" header is read again after 2 s |

Details and chapters asked at once are merged into one `getMangaUpdate` (SCANCORE's `ExtensionHost`), which Keiyoushi's lib 1.6 sources require.

**Known loss:** unnumbered extras and alternative scanlations of a number don't show.

### 3.3 Filters (`Filters.kt`)

Each top-level filter is group `f<index>`: `Select` → select (option index; a blank option is labelled All), `Sort` → type `sort` (`<i>:a` / `<i>:d`, `''` = source default; the sheet shows one chip per field and a second tap turns the direction, `FilterGroup.sort`), `Group` of `CheckBox` / `TriState` → multi (checked / included children), top-level `CheckBox` / `TriState` → multi with one option `1`. `Text`, `Header`, `Separator` have no group; TriState exclude isn't offered. Values go onto a fresh `getFilterList()` by position; a tree equal to the fresh one (and no query) means "not searching".

### 3.4 Errors

`describeFailure` (`Rpc.kt`) words a failure; `MihonChannel` sends it as a `PlatformException` (code = status). Dart (`ChannelMihonHost.failure`): a browser check becomes `challenge: <url>` (Verify in WebView), status 404 a 404 `ServerException`. A bare `IOException` is shown as its message: that is how extensions say "log in to read this".

---

## 4. Kotlin

### 4.1 Module `android/mihon`

An Android library the app depends on (`implementation project(':mihon')`).

| Path | What |
|---|---|
| `eu/`, `mihon/`, `tachiyomi/`, `androidx/compose/runtime/Stable.kt` | Mihon's source API and network helpers, vendored from SCANCORE's `host/api` (Mihon: Apache 2.0). Original package names: extensions link against them |
| `com/mediumdev/scancore/host/` | SCANCORE's host (MIT, `LICENSE-SCANCORE`): `ExtensionHost` (calls, `getMangaUpdate` merging, memos, warm-up), `Codec`, `MemoStore`, `Rpc` (errors), `android/AndroidLoader`, `AndroidSettings`, `WebViewBrowserCheck` (hidden Cloudflare solver, `WebViewCookieJar`). Changes are marked `BACAKOMIK` |
| `org/kurodev/bacakomik/mihon/` | Ours: `MihonHost` (entry), `Contract`, `Filters`, `Images`, `Slugs`, `SourceIndex` |

Library versions follow Mihon's (through SCANCORE): OkHttp 5.5, kotlinx.serialization 1.11, coroutines 1.11, Jsoup, RxJava 1, Injekt, androidx.preference, QuickJS (jitpack, `zhanghai/quickjs-java`). Kotlin is 2.4.21 for the whole build; the module applies the serialization plugin with its own version (`background_downloader` pins another).

When updating the vendored code, diff against SCANCORE's `host/` and keep the `BACAKOMIK` changes.

### 4.2 `MihonHost`

`start(context, userAgent, appVersion)` once per process (Dart calls it before the first call): `HostNetwork` gets the app's User-Agent (so WebView clearances work), `WebViewCookieJar`, the hidden `WebViewBrowserCheck`; Injekt gets `Application`, `NetworkHelper`, `JavaScriptEngine`, `Json`, `ProtoBuf`.

| Call | Args | Result |
|---|---|---|
| `inspect` | path, signer | pkg, name, versions, lib, nsfw, signers, `supported`; with a matching signer also `sources` (code runs only after the signer check) |
| `install` | pkg, apk, signer | sources `[{id, name, lang, baseUrl, supportsLatest, configurable}]`; recorded in `SourceIndex` |
| `uninstall` | pkg | drops it and its sources' `source_<id>` preferences |
| `call` | source, method, args | §3.2 |
| `preferences` / `setPreference` | source (, key, value) | settings (§6); a change unloads the extension so it rebuilds with the new value |
| `userAgent` | source | the User-Agent the source sends |

`SourceIndex` (SharedPreferences `bacakomik_mihon_index`) maps source ids to their APK and signer, so a call naming only a source (a cover at start) finds its extension. Extensions load on first use.

### 4.3 Android setup

- `MihonChannel.kt` (app) runs calls on `Dispatchers.IO`, answers on the main thread.
- `android:usesCleartextTraffic="true"`: some sites are plain `http` (Mihon allows it too).
- R8: `mihon/consumer-rules.pro` keeps the API and every library extensions use, plus `com.squareup.zstd` and `org.brotli`, which native code finds by name over JNI (stripping them aborts the process). **Test changes on a release build.**
- `MihonHost.supported` is false below Android 9 (signing info, `DelegateLastClassLoader`).

---

## 5. Dart

| File | What |
|---|---|
| `core/source/mihon_host.dart` | `MihonHost` interface; `ChannelMihonHost` (channel, lazy `start`, error mapping) |
| `core/source/mihon_source.dart` | `MihonSource implements LoadedSource`; `preferences`, `setPreference` |
| `core/source/mihon_repo.dart` | Repo URL normalising, `repo.json`, `index_v2` store or legacy `index.min.json` → `ExtensionMeta` |
| `core/source/mihon_store.dart` | Protobuf reader for the `index_v2` store (§7.1) |
| `core/source/mihon_installer.dart` | Download, `inspect`, `install`, uninstall; APK files |
| `core/source/extension_meta.dart` | `pkg`, `signer`, `versionCode`, `mihonSources` (`MihonSourceRef`, with `configurable`), `icon`; `isMihon`, `forMihonSource`, `mihonSourcesIn`, `mihonSlug` |
| `core/source/extension_manager.dart` | Picks the backend by `meta.isMihon`; Mihon repos in `catalog`, `fetchRepo`, `addRepo`; install / uninstall delegate to `MihonInstaller` |

- **APK files:** `<app support>/extensions/<id>-<versionCode>-<time>.apk`, made read-only by the loader (Android 14 refuses writable code). Every install gets a new file (so a reinstall never removes the one a loaded extension runs from); the old one is deleted after the new one installs.
- **Updates:** a higher `versionCode` in the repo; same badge and button as JS. Keys don't change.
- **Lib versions:** `supportedMihonLibs` (`1.4`, `1.5`, `1.6`) must match `AndroidLoader.libs`.

---

## 6. Images, downloads, settings

- **Images** need the source's own client (headers, cookies, interceptors that unscramble pages), so they are `mihon://<sourceId>/cover/<b64url>` and `mihon://<sourceId>/page/<b64url of page JSON>` (`Images.kt`). The image caches' `FileService` (`image_cache.dart`) fetches them through the channel (`MihonHost.image`). The URL is the same on every device, so stored covers survive sync and it is a stable cache key.
- **Downloads:** `PageDownloadQueue` saves `mihon://` pages through `comicImageCache`, like pages of blocking hosts: **only while the app runs** (not in the background downloader).
- **Settings:** `ConfigurableSource` screens are read with androidx.preference (`AndroidSettings`) and shown in a Dotline sheet (`mihon_settings_sheet.dart`): switch, list, multiselect, text. Values live in the extension's `source_<id>` SharedPreferences, as in Mihon; not in backup or sync. The settings button shows only for extensions with a configurable source.
- **Cloudflare:** `CloudflareInterceptor` solves automatic checks in a hidden WebView; one that needs the user becomes "Verify in WebView". Extensions and the app's WebViews share Android's `CookieManager`, so a clearance passed there works at once.

---

## 7. Repos

### 7.1 Formats

A Mihon repo is stored by its `index.min.json` URL; a pasted `repo.json` or base URL is normalised to it. `MihonRepo.fetch` reads `repo.json` next to it:

- With `index_v2` (Mihon 0.20.1+, e.g. Keiyoushi): a protobuf **store**, often gzipped. `index.min.json` then only lists an "update the app" stub.

  ```
  Store     { 1 name, 2 badge, 3 signingKey, 4 contact, 101 ExtensionList, 102 extensionListUrl }
  ExtensionList { repeated 1 Extension }
  Extension { 1 name, 2 packageName, 3 Resources {1 apkUrl, 2 iconUrl}, 4 extensionLib,
              5 versionCode, 6 versionName, 7 contentWarning (3 = NSFW), 8 repeated Source }
  Source    { 1 id, 2 name, 3 language, 4 homeUrl }
  ```

  Field numbers as SCANCORE reads them (`src/extensions/Index.cpp`). APK and icon URLs are absolute.
- Without it: the legacy `index.min.json` (`{name, pkg, apk, lang, code, version, nsfw, sources}`), APKs at `apk/<file>`, icons at `icon/<pkg>.png`.

### 7.2 Trust

A repo without a signing key (`signingKeyFingerprint`, or the store's `signingKey`) is refused. An APK loads only if signed by that key. Extensions run with all of the app's permissions: the signer is the only gate.

The same package in two repos with different keys (Keiyoushi and a fork) is two builds: an installed extension is offered updates only from repos with its key, and installing it from a repo with another key is refused until it is uninstalled, as in Mihon.

---

## 8. Screens

**Explore filter sheet:** groups with more than 14 options show 12 (plus any picked) and "Show all · n". **Comic page:** a genre chip opens Explore when the source has a matching filter (`SourceFeatures.genreFilter`: the `genre` group's id, else any option with the genre's name); otherwise it is a plain label.

**Extensions screen:**

Shared by JS and Mihon: icon from the repo (`ExtensionMeta.icon`, cached with the covers; no icon → the name's first letter), `18+` in red in the info line (`ExtensionLine`), search by name or site, a language sheet (names from `core/utils/language_names.dart`, counts, Indonesian and English first; a multi-language extension shows under each language) and Hide 18+, on both tabs.

---

## 9. Mihon backup import

A backup source id equal to an installed or offered Mihon source's id maps straight to `mihon-<id>` with slug `mihonSlug(url)`: no `urlPatterns`, no title search. Mihon extensions are left out of the name matching JS extensions use. When both match, what is installed wins, JS before Mihon (the library then opens on any device): an installed JS source, then an installed Mihon one, then a JS one from the repos, then a Mihon one. Comics whose link the JS extension's `urlPatterns` can't read are listed as unreadable.

---

## 10. Tests

- `test/core/mihon_test.dart`: repo URLs, legacy entries, protobuf stores, `ExtensionMeta` round trip and ids, `MihonSource` calls, error mapping, backup matching by id.
- On a phone (release build): add a repo, install, Home, Explore search and filters, comic page, reader, settings, uninstall. Tried with several Keiyoushi extensions (lib 1.6).

---

## 11. Later: desktop

Not planned now. Desktop could run the same host the way SCANCORE and Suwayomi do: a separate JVM process, dex2jar per APK, Android stand-ins (Suwayomi's AndroidCompat), JCEF for Cloudflare, Dart talking JSON lines over stdin/stdout with the same calls as §4.2. To keep that cheap: `MihonSource` talks to the `MihonHost` interface, not the channel; `Contract`, `Filters`, `Images` have no Android imports beyond `android.util.Base64` in `Slugs`.

---

## 12. Open questions

- Mark Mihon sources (e.g. `MIHON`) where a site is offered by both backends?
- TriState exclude in the filter contract, for both backends?
- Background downloads for Mihon pages (a localhost proxy the background downloader can reach)?
